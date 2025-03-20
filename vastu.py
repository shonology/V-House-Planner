import cv2
import pytesseract
import numpy as np
import os
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

UPLOAD_FOLDER = "uploads"
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

# Vastu Compliance Rules
vastu_rules = {
    "KITCHEN": "Should be in the Southeast (SE) or Northwest (NW).",
    "BEDROOM": "Master bedroom should be in the Southwest (SW).",
    "TOILET": "Should not be in the Northeast (NE).",
    "PUJA": "Should be in the Northeast (NE)."
}

# 🔹 Function to Enhance Image for OCR
def preprocess_image(image_path):
    image = cv2.imread(image_path)

    # Convert to Grayscale
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    # Resize for better OCR detection
    gray = cv2.resize(gray, None, fx=1.5, fy=1.5, interpolation=cv2.INTER_CUBIC)

    # Apply Bilateral Filter (Reduces noise but keeps edges sharp)
    gray = cv2.bilateralFilter(gray, 9, 75, 75)

    # Adaptive Thresholding for better contrast
    thresh = cv2.adaptiveThreshold(
        gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 15, 3)

    return thresh


@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({"error": "No file uploaded"}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400

    file_path = os.path.join(app.config['UPLOAD_FOLDER'], file.filename)
    file.save(file_path)

    # Process Image
    processed_image = preprocess_image(file_path)

    # 🔹 OCR with Better Configurations
    custom_config = r'--oem 3 --psm 6'
    text = pytesseract.image_to_string(processed_image, config=custom_config)
    text = text.upper().strip()

    print("Extracted Text:", text)  # Debugging

    # 🔹 Checking Vastu Compliance
    analysis = []
    for room, rule in vastu_rules.items():
        if room in text:
            analysis.append(f"✅ {room} found. {rule}")
        else:
            analysis.append(f"⚠ {room} not detected. Consider proper placement.")

    return jsonify({"analysis": "\n".join(analysis)}), 200


if __name__ == '__main__':
    app.run(debug=True, host="0.0.0.0", port=5000)
