from flask import Flask, request, jsonify
from flask_cors import CORS  # Import CORS
import cv2
import numpy as np
import pandas as pd
import os

app = Flask(__name__)
CORS(app)  # Allow all origins


# Constants
BRICK_LENGTH = 0.19  # meters (190mm)
BRICK_HEIGHT = 0.09  # meters (90mm)
COST_PER_BRICK_HIGH = 8  # Cost per high-quality brick

# City-wise material data
data = {
    "City": ["KSD", "KNR", "WYD", "KZH", "MLP", "PKD", "TSR", "EKM", "IDK", "KTM", "ALP", "PTA", "KLM", "TVM"],
    "Bricks_High": [15000, 0, 9000, 11750, 0, 9000, 10250, 10500, 12500, 12000, 10750, 0, 0, 11270],
    "Total_Cost": [200000, 150000, 180000, 220000, 140000, 175000, 195000, 210000, 185000, 225000, 190000, 160000, 170000, 200500]
}

df = pd.DataFrame(data)

# Folder to save uploaded images
UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config["UPLOAD_FOLDER"] = UPLOAD_FOLDER

def estimate_bricks_from_image(image_path, scale_factor=0.01):
    """Estimates the number of bricks from a given house layout image and adjusts costs efficiently."""
    
    img = cv2.imread(image_path)
    if img is None:
        return None, "Error: Unable to process image"

    # Resize image to speed up processing
    img = cv2.resize(img, (400, 400))  # Adjust size for faster processing

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    edges = cv2.Canny(gray, 50, 150)

    # Contour detection
    contours, _ = cv2.findContours(edges, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)

    # Calculate total wall area
    total_wall_area = sum(cv2.contourArea(cnt) for cnt in contours if cv2.contourArea(cnt) > 500)  # Ignore small contours

    brick_area = BRICK_LENGTH * BRICK_HEIGHT
    estimated_bricks = total_wall_area / brick_area

    # Adjust cost based on estimated bricks
    df["Adjusted_Cost"] = df["Total_Cost"] + (estimated_bricks * COST_PER_BRICK_HIGH)

    return int(estimated_bricks), df.to_dict(orient="records")

@app.route("/upload", methods=["POST"])
def upload_file():
    """Handles image upload from Flutter and estimates construction cost."""
    
    if "file" not in request.files:
        return jsonify({"error": "No file uploaded"}), 400

    file = request.files["file"]
    if file.filename == "":
        return jsonify({"error": "No selected file"}), 400

    file_path = os.path.join(app.config["UPLOAD_FOLDER"], file.filename)
    file.save(file_path)

    estimated_bricks, cost_data = estimate_bricks_from_image(file_path)
    
    if estimated_bricks is None:
        return jsonify({"error": cost_data}), 500

    return jsonify({
        "estimated_bricks": estimated_bricks,
        "city_costs": cost_data
    })

if __name__ == "__main__":
    app.run(debug=True)
