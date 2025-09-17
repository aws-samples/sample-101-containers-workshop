# Alerts Service - Handles GPS tracking data and notifications for wildlife collars

from datetime import datetime, timedelta
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
    service='wildlife-alerts',
    daemon_address='localhost:2000'
)
patch_all()

app = Flask(__name__)

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
logger.info("Connecting to MongoDB")
mongo_client = connect_with_retry(
    lambda: MongoClient('mongodb://wildlife-datadb.wildlife:27017'),
    'MongoDB (wildlife-datadb)'
)
db = mongo_client.wildlife_db

@app.route('/wildlife/api/gps', methods=['POST'])
def receive_gps():
    try:
        logger.info("Receiving GPS data")
        data = request.json
        data['timestamp'] = datetime.utcnow()
        db.gps_tracking.insert_one(data)
        return jsonify({"message": "GPS data received"}), 200
    except Exception as e:
        logger.error(f"Error receiving GPS data: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/wildlife/api/gps', methods=['GET'])
def get_gps_data():
    try:
        logger.info("Getting GPS data")
        cutoff = datetime.utcnow() - timedelta(hours=24)
        gps_data = list(db.gps_tracking.find(
            {"timestamp": {"$gt": cutoff}}, 
            {'_id': False}
        ))
        return jsonify(gps_data), 200
    except Exception as e:
        logger.error(f"Error getting GPS data: {str(e)}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    logger.info("Starting alerts service")
    app.run(host='0.0.0.0', port=5000)  # nosec B104, nosemgrep: avoid_app_run_with_bad_host - Required for containerized deployment: 0.0.0.0 binding allows ECS Service Connect and ALB to reach container