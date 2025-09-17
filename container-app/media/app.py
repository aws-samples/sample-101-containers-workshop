# Media Service - Handles image upload, storage, and retrieval for wildlife sightings

from datetime import datetime
from io import BytesIO
import os
import uuid
import boto3
from flask import Flask, jsonify, send_file, request
from botocore.exceptions import ClientError
from pymongo import MongoClient
import logging
import time
from aws_xray_sdk.core import xray_recorder, patch_all
from aws_xray_sdk.ext.flask.middleware import XRayMiddleware

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize X-Ray
logger.info("Initializing X-Ray")
xray_recorder.configure(
    context_missing='LOG_ERROR',
    service='wildlife-media'
)
patch_all()

app = Flask(__name__)
logger.info("initializing xray middleware")
# Add X-Ray middleware to Flask
XRayMiddleware(app, xray_recorder)

# Simple retry mechanism: 60 attempts with 30-second delay (30 minutes total)
def connect_with_retry(connect_func, service_name, max_attempts=60, delay=30):
    logger.info(f"Connecting to {service_name} with retry logic...")
    
    for attempt in range(max_attempts):
        try:
            result = connect_func()
            logger.info(f"Successfully connected to {service_name} on attempt {attempt+1}")
            return result
        except Exception as e:
            if attempt < max_attempts - 1:
                logger.warning(f"Connection to {service_name} failed (attempt {attempt+1}/{max_attempts}): {str(e)}")
                logger.info(f"Retrying in {delay} seconds...")
                time.sleep(delay)
            else:
                logger.warning(f"Failed to connect to {service_name} after {max_attempts} attempts (30 minutes)")
                raise

# Get environment variables from ECS task definition
logger.info("Getting environment variables from task definition")
AWS_REGION = os.getenv('AWS_REGION')
BUCKET_NAME = os.getenv('BUCKET_NAME')

logger.info(f"Using AWS_REGION: {AWS_REGION}")
logger.info(f"Using BUCKET_NAME: {BUCKET_NAME}")

# Initialize S3 client
logger.info(f"Initializing S3 client for region {AWS_REGION}")
s3 = boto3.client('s3', region_name=AWS_REGION)

# Initialize MongoDB client
logger.info("Connecting to MongoDB")
mongo_client = connect_with_retry(
    lambda: MongoClient('mongodb://wildlife-datadb.wildlife:27017'),
    'MongoDB (wildlife-datadb)'
)
db = mongo_client.wildlife_db

# Constants
ALLOWED_IMAGE_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.gif'}

@xray_recorder.capture('s3_image_upload')
def handle_image_upload(file):
    """Handle image upload to S3"""
    if not file.filename or file.filename == '':
        logger.warning("No filename provided")
        return None
    
    # Read the file content to check if it's empty
    file_content = file.read()
    if len(file_content) == 0:
        logger.warning("Empty file provided")
        return None
    
    # Reset file pointer to beginning for upload
    file.seek(0)
    
    try:
        # For files with no extension (like 'image' from form)
        file_extension = os.path.splitext(file.filename)[1].lower()
        if not file_extension and file.filename == 'image':
            file_extension = '.jpg'
            
        unique_filename = f"{uuid.uuid4()}{file_extension}"
        filename = f"sightings/{datetime.now().strftime('%Y%m%d')}/{unique_filename}"
        
        logger.info(f"Uploading image to S3: {filename}")
        
        # Ensure content_type is not None
        content_type = file.content_type or 'image/jpeg'
        
        s3.upload_fileobj(
            file,
            BUCKET_NAME,
            filename,
            ExtraArgs={'ContentType': content_type}
        )
        logger.info(f"Successfully uploaded image to S3: {filename}")
        return filename
    except Exception as e:
        logger.error(f"Error uploading image: {str(e)}")
        return None

@app.route('/wildlife/health')
def health_check():
    logger.info("Health check requested")
    return jsonify({
        "status": "healthy",
        "service": "media",
        "xray": "enabled",
        "bucket": BUCKET_NAME,
        "region": AWS_REGION
    }), 200

@app.route('/wildlife/api/images/<path:image_key>')
@xray_recorder.capture('s3_image_retrieval')
def get_image(image_key):
    # Validate image key
    if not image_key or '..' in image_key:
        logger.warning(f"Invalid image key: {image_key}")
        return jsonify({"error": "Invalid image key"}), 400

    # Check if the image key has a valid extension
    has_valid_ext = False
    for ext in ALLOWED_IMAGE_EXTENSIONS:
        if image_key.lower().endswith(ext):
            has_valid_ext = True
            break
            
    if not has_valid_ext:
        logger.warning(f"Invalid file type: {image_key}")
        return jsonify({"error": "Invalid file type"}), 400

    try:
        logger.info(f"Getting image from S3: {image_key}")
        response = s3.get_object(Bucket=BUCKET_NAME, Key=image_key)
        return send_file(
            BytesIO(response['Body'].read()),
            mimetype=response.get('ContentType', 'image/jpeg'),
            as_attachment=False
        )
    except ClientError as e:
        error_code = e.response.get('Error', {}).get('Code', 'Unknown')
        if error_code == 'NoSuchKey':
            logger.warning(f"Image not found: {image_key}")
            return jsonify({"error": "Image not found"}), 404
        logger.error(f"Failed to retrieve image: {str(e)}")
        return jsonify({"error": "Failed to retrieve image"}), 500
    except Exception as e:
        logger.error(f"Internal server error: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500

@app.route('/wildlife/api/sightings', methods=['POST'])
def report_sighting():
    if not request.form:
        logger.warning("No form data received")
        return jsonify({"error": "No form data received"}), 400
            
    try:
        logger.info("Processing sighting report")
        data = request.form.to_dict()
        
        # Convert coordinates to float
        for coord in ['latitude', 'longitude']:
            if coord in data:
                try:
                    data[coord] = float(data[coord])
                except ValueError:
                    logger.warning(f"Invalid {coord}")
                    return jsonify({"error": f"Invalid {coord}"}), 400
        
        # Add timestamp
        data['timestamp'] = datetime.utcnow()
        
        # Handle image upload
        if 'image' in request.files:
            logger.info("Processing image upload")
            image_url = handle_image_upload(request.files['image'])
            if image_url:
                data['image_url'] = image_url
                logger.info(f"Image URL set to: {image_url}")
        
        # Store in MongoDB
        logger.info("Storing sighting in MongoDB")
        db.sightings.insert_one(data)
        
        return jsonify({"message": "Sighting reported successfully"}), 200

    except Exception as e:
        logger.error(f"Error in report_sighting: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/wildlife/api/sightings', methods=['GET'])
def get_sightings():
    try:
        logger.info("Getting sightings from MongoDB")
        sightings = list(db.sightings.find({}, {'_id': False}))
        return jsonify(sightings), 200
    except Exception as e:
        logger.error(f"Error getting sightings: {str(e)}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    logger.info("Starting media service")
    app.run(host='0.0.0.0', port=5000)  # nosec B104, nosemgrep: avoid_app_run_with_bad_host - Required for containerized deployment: 0.0.0.0 binding allows ECS Service Connect and ALB to reach container