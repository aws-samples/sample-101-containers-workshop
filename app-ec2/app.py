from datetime import datetime, timedelta
from io import BytesIO
import os
import uuid

import boto3
from botocore.exceptions import ClientError
from flask import (
    Flask, 
    jsonify, 
    redirect, 
    render_template, 
    request, 
    send_file
)
from pymongo import MongoClient

app = Flask(__name__, 
           static_folder='static',
           static_url_path='/wildlife/static')

# Environment variables
ENV_VARS = {
    'PREFIX_CODE': os.getenv('PREFIX_CODE'),
    'AWS_ACCOUNT_ID': os.getenv('AWS_ACCOUNT_ID'),
    'BUCKET_NAME': os.getenv('BUCKET_NAME'),
    'AWS_REGION': os.getenv('AWS_REGION')
}

if not all(ENV_VARS.values()):
    raise ValueError("Missing required environment variables: " + 
                    ", ".join(k for k, v in ENV_VARS.items() if not v))

# Initialize clients
s3 = boto3.client('s3', region_name=ENV_VARS['AWS_REGION'])
mongo_client = MongoClient('mongodb://localhost:27017/')
db = mongo_client.wildlife_db

# Constants
ALLOWED_IMAGE_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.gif'}
CACHE_HEADERS = {
    'Cache-Control': 'no-cache, no-store, must-revalidate, max-age=0',
    'Pragma': 'no-cache',
    'Expires': '0'
}

def add_cache_headers(response):
    """Add no-cache headers to to response"""
    for key, value in CACHE_HEADERS.items():
        response.headers[key] = value
    return response

def handle_image_upload(file):
    """Handle image upload to S3"""
    if not file.filename:
        return None
    
    try:
        file_extension = os.path.splitext(file.filename)[1]
        unique_filename = f"{uuid.uuid4()}{file_extension}"
        filename = f"sightings/{datetime.now().strftime('%Y%m%d')}/{unique_filename}"
        
        s3.upload_fileobj(
            file,
            ENV_VARS['BUCKET_NAME'],
            filename,
            ExtraArgs={'ContentType': file.content_type}
        )
        return filename
    except Exception as e:
        print(f"Error uploading image: {str(e)}")
        return None

# Main application routes
@app.route('/wildlife')
def wildlife_root():
    return redirect('/wildlife/')

@app.route('/wildlife/')
def index():
    return render_template('index.html')

@app.route('/wildlife/api/sightings', methods=['POST'])
def report_sighting():
    if not request.form:
        return jsonify({"error": "No form data received"}), 400
            
    try:
        data = request.form.to_dict()
        
        # Convert coordinates to float
        for coord in ['latitude', 'longitude']:
            if coord in data:
                try:
                    data[coord] = float(data[coord])
                except ValueError:
                    return jsonify({"error": f"Invalid {coord}"}), 400
        
        # Add timestamp
        data['timestamp'] = datetime.utcnow()
        
        # Handle image upload
        if 'image' in request.files:
            image_url = handle_image_upload(request.files['image'])
            if image_url:
                data['image_url'] = image_url
        
        # Store in MongoDB
        db.sightings.insert_one(data)
        
        response = jsonify({"message": "Sighting reported successfully"})
        return add_cache_headers(response), 200

    except Exception as e:
        print(f"Error in report_sighting: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/wildlife/api/sightings', methods=['GET'])
def get_sightings():
    try:
        sightings = list(db.sightings.find({}, {'_id': False}))
        response = jsonify(sightings)
        return add_cache_headers(response), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/wildlife/api/images/<path:image_key>')
def get_image(image_key):
    # Validate image key
    if not image_key or '..' in image_key:
        return jsonify({"error": "Invalid image key"}), 400

    if not any(image_key.lower().endswith(ext) for ext in ALLOWED_IMAGE_EXTENSIONS):
        return jsonify({"error": "Invalid file type"}), 400

    try:
        response = s3.get_object(Bucket=ENV_VARS['BUCKET_NAME'], Key=image_key)
        return send_file(
            BytesIO(response['Body'].read()),
            mimetype=response.get('ContentType', 'image/jpeg'),
            as_attachment=False
        )
    except ClientError as e:
        error_code = e.response.get('Error', {}).get('Code', 'Unknown')
        if error_code == 'NoSuchKey':
            return jsonify({"error": "Image not found"}), 404
        return jsonify({"error": "Failed to retrieve image"}), 500
    except Exception as e:
        return jsonify({"error": "Internal server error"}), 500

@app.route('/wildlife/api/gps', methods=['POST'])
def receive_gps():
    try:
        data = request.json
        data['timestamp'] = datetime.utcnow()
        db.gps_tracking.insert_one(data)
        return jsonify({"message": "GPS data received"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/wildlife/api/gps', methods=['GET'])
def get_gps_data():
    try:
        cutoff = datetime.utcnow() - timedelta(hours=24)
        gps_data = list(db.gps_tracking.find(
            {"timestamp": {"$gt": cutoff}}, 
            {'_id': False}
        ))
        response = jsonify(gps_data)
        return add_cache_headers(response), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Data API routes
@app.route('/wildlife/api/data/health')
def data_health_check():
    return jsonify({
        "status": "healthy",
        "service": "data-api"
    }), 200

@app.route('/wildlife/api/data/sightings', methods=['GET'])
def data_get_sightings():
    try:
        sightings = list(db.sightings.find({}, {'_id': False}))
        return jsonify(sightings), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/wildlife/api/data/sightings/<sighting_id>', methods=['GET'])
def data_get_sighting(sighting_id):
    try:
        sighting = db.sightings.find_one({"id": sighting_id}, {'_id': False})
        if sighting:
            return jsonify(sighting), 200
        else:
            return jsonify({"error": "Sighting not found"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    print("Starting wildlife application with integrated data API on port 5000")
    app.run(host='0.0.0.0', port=5000, debug=False)  # nosec B104, nosemgrep: avoid_app_run_with_bad_host - Required for EC2 deployment: 0.0.0.0 binding allows ALB to reach application