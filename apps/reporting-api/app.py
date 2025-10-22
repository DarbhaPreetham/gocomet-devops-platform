from flask import Flask, jsonify, request
from flask_cors import CORS
from pymongo import MongoClient
from datetime import datetime, timedelta
import os
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
CORS(app)

# MongoDB connection
MONGODB_URI = os.getenv('MONGODB_URI', 'mongodb://admin:admin_password@mongodb:27017/reports_db')
client = MongoClient(MONGODB_URI)
db = client.reports_db

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    try:
        # Test MongoDB connection
        client.admin.command('ping')
        return jsonify({
            'status': 'healthy',
            'timestamp': datetime.utcnow().isoformat(),
            'database': 'connected'
        }), 200
    except Exception as e:
        return jsonify({
            'status': 'unhealthy',
            'timestamp': datetime.utcnow().isoformat(),
            'error': str(e)
        }), 500

@app.route('/api/reports', methods=['GET'])
def get_reports():
    """Get all reports with optional filtering"""
    try:
        # Parse query parameters
        limit = int(request.args.get('limit', 10))
        skip = int(request.args.get('skip', 0))
        category = request.args.get('category')
        status = request.args.get('status')
        
        # Build query
        query = {}
        if category:
            query['category'] = category
        if status:
            query['status'] = status
            
        # Fetch reports
        reports = list(db.reports.find(query).skip(skip).limit(limit))
        
        # Convert ObjectId to string for JSON serialization
        for report in reports:
            report['_id'] = str(report['_id'])
            
        return jsonify({
            'reports': reports,
            'total': db.reports.count_documents(query),
            'limit': limit,
            'skip': skip
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/reports/<report_id>', methods=['GET'])
def get_report(report_id):
    """Get a specific report by ID"""
    try:
        from bson import ObjectId
        report = db.reports.find_one({'_id': ObjectId(report_id)})
        
        if not report:
            return jsonify({'error': 'Report not found'}), 404
            
        report['_id'] = str(report['_id'])
        return jsonify(report), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/reports', methods=['POST'])
def create_report():
    """Create a new report"""
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['title', 'category', 'content']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'Missing required field: {field}'}), 400
        
        # Add metadata
        data['created_at'] = datetime.utcnow()
        data['updated_at'] = datetime.utcnow()
        data['status'] = data.get('status', 'draft')
        
        # Insert report
        result = db.reports.insert_one(data)
        
        return jsonify({
            'message': 'Report created successfully',
            'report_id': str(result.inserted_id)
        }), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/reports/<report_id>', methods=['PUT'])
def update_report(report_id):
    """Update an existing report"""
    try:
        from bson import ObjectId
        data = request.get_json()
        
        # Add update timestamp
        data['updated_at'] = datetime.utcnow()
        
        # Update report
        result = db.reports.update_one(
            {'_id': ObjectId(report_id)},
            {'$set': data}
        )
        
        if result.matched_count == 0:
            return jsonify({'error': 'Report not found'}), 404
            
        return jsonify({'message': 'Report updated successfully'}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/reports/<report_id>', methods=['DELETE'])
def delete_report(report_id):
    """Delete a report"""
    try:
        from bson import ObjectId
        result = db.reports.delete_one({'_id': ObjectId(report_id)})
        
        if result.deleted_count == 0:
            return jsonify({'error': 'Report not found'}), 404
            
        return jsonify({'message': 'Report deleted successfully'}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/reports/stats', methods=['GET'])
def get_report_stats():
    """Get report statistics"""
    try:
        # Get total reports
        total_reports = db.reports.count_documents({})
        
        # Get reports by status
        status_counts = {}
        for status in ['draft', 'published', 'archived']:
            status_counts[status] = db.reports.count_documents({'status': status})
        
        # Get reports by category
        category_pipeline = [
            {'$group': {'_id': '$category', 'count': {'$sum': 1}}},
            {'$sort': {'count': -1}}
        ]
        category_stats = list(db.reports.aggregate(category_pipeline))
        
        # Get recent reports (last 7 days)
        week_ago = datetime.utcnow() - timedelta(days=7)
        recent_reports = db.reports.count_documents({'created_at': {'$gte': week_ago}})
        
        return jsonify({
            'total_reports': total_reports,
            'status_breakdown': status_counts,
            'category_breakdown': category_stats,
            'recent_reports': recent_reports
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

def initialize_database():
    """Initialize database with sample data"""
    try:
        # Check if reports collection exists and has data
        if db.reports.count_documents({}) == 0:
            sample_reports = [
                {
                    'title': 'Monthly Sales Report',
                    'category': 'sales',
                    'content': 'Comprehensive analysis of monthly sales performance...',
                    'status': 'published',
                    'created_at': datetime.utcnow() - timedelta(days=5),
                    'updated_at': datetime.utcnow() - timedelta(days=5)
                },
                {
                    'title': 'User Engagement Analysis',
                    'category': 'analytics',
                    'content': 'Detailed analysis of user engagement metrics...',
                    'status': 'published',
                    'created_at': datetime.utcnow() - timedelta(days=3),
                    'updated_at': datetime.utcnow() - timedelta(days=3)
                },
                {
                    'title': 'Q4 Performance Review',
                    'category': 'performance',
                    'content': 'Quarterly performance review and recommendations...',
                    'status': 'draft',
                    'created_at': datetime.utcnow() - timedelta(days=1),
                    'updated_at': datetime.utcnow() - timedelta(days=1)
                }
            ]
            
            db.reports.insert_many(sample_reports)
            print("Sample reports inserted successfully")
            
    except Exception as e:
        print(f"Error initializing database: {e}")

if __name__ == '__main__':
    initialize_database()
    app.run(host='0.0.0.0', port=5000, debug=True)
