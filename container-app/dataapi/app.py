# Data API Service - faciliates frontend access to data service

from flask import Flask, jsonify, request
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
    service='wildlife-dataapi'
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

# Initialize MongoDB client
logger.info("Starting MongoDB")
client = connect_with_retry(
    lambda: MongoClient('mongodb://wildlife-datadb.wildlife:27017'),
    'MongoDB (wildlife-datadb)'
)
db = client.wildlife_db

@app.route('/wildlife/health')
def health_check():
    logger.info("Health check requested")
    return jsonify({
        "status": "healthy",
        "service": "dataapi"
    }), 200

@app.route('/wildlife/api/sightings', methods=['GET'])
def get_sightings():
    try:
        logger.info("Getting sightings from MongoDB")
        sightings = list(db.sightings.find({}, {'_id': False}))
        return jsonify(sightings), 200
    except Exception as e:
        logger.error(f"Error getting sightings: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/wildlife/api/sightings/<sighting_id>', methods=['GET'])
def get_sighting(sighting_id):
    try:
        logger.info(f"Getting sighting {sighting_id}")
        sighting = db.sightings.find_one({"id": sighting_id}, {'_id': False})
        if sighting:
            return jsonify(sighting), 200
        else:
            return jsonify({"error": "Sighting not found"}), 404
    except Exception as e:
        logger.error(f"Error getting sighting: {str(e)}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    logger.info("Starting dataapi service")
    app.run(host='0.0.0.0', port=5000)  # nosec B104, nosemgrep: avoid_app_run_with_bad_host - Required for containerized deployment: 0.0.0.0 binding allows ECS Service Connect and ALB to reach container