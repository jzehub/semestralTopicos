from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
from datetime import datetime
import os

app = Flask(__name__)
CORS(app)

# Database configuration
# For local development: DATABASE_URL=postgresql://user:password@db:5432/taskmanager
# For AWS RDS: Set DATABASE_URL to RDS endpoint, e.g., postgresql://username:password@rds-instance.region.rds.amazonaws.com:5432/taskmanager
# Use AWS Secrets Manager or Parameter Store for secure credential management
app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv(
    'DATABASE_URL',
    'postgresql://user:password@db:5432/taskmanager'
)
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False


db = SQLAlchemy(app)

# Valid options
VALID_STATUS = ['backlog', 'todo', 'in_progress', 'in_review', 'done']
VALID_PRIORITY = ['low', 'medium', 'high', 'critical']

class Task(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text)
    status = db.Column(db.String(50), default='backlog')
    priority = db.Column(db.String(20), default='medium')
    assigned_to = db.Column(db.String(100))
    estimated_hours = db.Column(db.Float)
    tags = db.Column(db.String(255))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'title': self.title,
            'description': self.description,
            'status': self.status,
            'priority': self.priority,
            'assigned_to': self.assigned_to,
            'estimated_hours': self.estimated_hours,
            'tags': self.tags,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }

# Health check endpoint
@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy'}), 200

# Get all tasks
@app.route('/tasks', methods=['GET'])
def get_tasks():
    try:
        tasks = Task.query.all()
        return jsonify([task.to_dict() for task in tasks]), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Get single task
@app.route('/tasks/<int:id>', methods=['GET'])
def get_task(id):
    try:
        task = Task.query.get_or_404(id)
        return jsonify(task.to_dict()), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Create task
@app.route('/tasks', methods=['POST'])
def create_task():
    try:
        data = request.get_json()
        if not data or not data.get('title'):
            return jsonify({'error': 'Title is required'}), 400

        if data.get('status') and data['status'] not in VALID_STATUS:
            return jsonify({'error': 'Invalid status'}), 400

        if data.get('priority') and data['priority'] not in VALID_PRIORITY:
            return jsonify({'error': 'Invalid priority'}), 400

        task = Task(
            title=data['title'],
            description=data.get('description'),
            status=data.get('status', 'backlog'),
            priority=data.get('priority', 'medium'),
            assigned_to=data.get('assigned_to'),
            estimated_hours=data.get('estimated_hours'),
            tags=data.get('tags')
        )
        db.session.add(task)
        db.session.commit()
        return jsonify(task.to_dict()), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

# Update task
@app.route('/tasks/<int:id>', methods=['PUT'])
def update_task(id):
    try:
        task = Task.query.get_or_404(id)
        data = request.get_json()

        if data.get('title') is not None and not data['title'].strip():
            return jsonify({'error': 'Title cannot be empty'}), 400

        if data.get('status') and data['status'] not in VALID_STATUS:
            return jsonify({'error': 'Invalid status'}), 400

        if data.get('priority') and data['priority'] not in VALID_PRIORITY:
            return jsonify({'error': 'Invalid priority'}), 400

        for key, value in data.items():
            if hasattr(task, key):
                setattr(task, key, value)

        db.session.commit()
        return jsonify(task.to_dict()), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

# Delete task
@app.route('/tasks/<int:id>', methods=['DELETE'])
def delete_task(id):
    try:
        task = Task.query.get_or_404(id)
        db.session.delete(task)
        db.session.commit()
        return '', 204
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(host='0.0.0.0', port=5000, debug=True)