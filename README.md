# Task Manager for Dev Teams

A full-stack CRUD application for managing tasks in development teams, built with Flask backend, vanilla JavaScript frontend, and PostgreSQL database. Designed for deployment on AWS with high availability.

## Architecture

The application follows a three-tier architecture:

- **Frontend Layer**: Static web interface served via nginx
- **Backend Layer**: REST API built with Python Flask handling business logic
- **Database Layer**: PostgreSQL database with task data persistence

All layers are containerized with Docker for easy deployment.

## Features

- Create, read, update, and delete tasks
- Task fields: title, description, status, priority, assignee, estimated hours, tags
- Color-coded priority indicators (low=green, medium=blue, high=yellow, critical=red)
- Responsive web interface
- RESTful API with CORS support
- Health check endpoint for load balancer

## Valid Values

- **Status**: backlog, todo, in_progress, in_review, done
- **Priority**: low, medium, high, critical

## Local Development

### Prerequisites

- Docker
- Docker Compose

### Setup

1. Clone the repository
2. Navigate to the project directory
3. Run the application:

```bash
docker-compose up --build
```

4. Access the application:
   - Frontend: http://localhost:8080
   - Backend API: http://localhost:5000
   - Database: localhost:5432 (user: user, password: password, db: taskmanager)

## Building and Pushing Docker Images

This section provides instructions for building Docker images for the backend and frontend services and pushing them to Docker Hub, preparing them for deployment on AWS ECS.

### Prerequisites

- Docker installed and running on your system
- A Docker Hub account (sign up at [hub.docker.com](https://hub.docker.com) if you don't have one)

### Using the Build Script

A convenience script `build-and-push.sh` is provided in the root directory to automate the build and push process.

1. **Set Environment Variables** (optional, defaults are provided in the script):
   ```bash
   export DOCKER_USERNAME=your-dockerhub-username
   export BACKEND_REPO=your-backend-repo-name
   export FRONTEND_REPO=your-frontend-repo-name
   export TAG=latest  # or specify a version tag like 'v1.0.0'
   ```

2. **Make the script executable** (if not already):
   ```bash
   chmod +x build-and-push.sh
   ```

3. **Run the script**:
   ```bash
   ./build-and-push.sh
   ```
   The script will prompt you to enter your Docker Hub password for authentication.

4. **Verify**: Check your Docker Hub repository to confirm the images have been pushed successfully.

### Manual Build and Push Steps

If you prefer to build and push manually or need more control:

1. **Login to Docker Hub**:
   ```bash
   docker login
   ```

2. **Build Backend Image**:
   ```bash
   cd backend
   docker build -t your-username/your-backend-repo:latest .
   docker push your-username/your-backend-repo:latest
   cd ..
   ```

3. **Build Frontend Image**:
   ```bash
   cd frontend
   docker build -t your-username/your-frontend-repo:latest .
   docker push your-username/your-frontend-repo:latest
   cd ..
   ```

Replace `your-username`, `your-backend-repo`, and `your-frontend-repo` with your actual Docker Hub username and desired repository names.

### API Endpoints

- `GET /health` - Health check
- `GET /tasks` - Retrieve all tasks
- `GET /tasks/:id` - Retrieve single task
- `POST /tasks` - Create new task
- `PUT /tasks/:id` - Update existing task
- `DELETE /tasks/:id` - Delete task

## Environment Variables

### Backend Service

- `DATABASE_URL`: PostgreSQL connection string (default: `postgresql://user:password@db:5432/taskmanager`)

### Frontend Service

- `API_BASE_URL`: Backend API base URL (default: `http://backend:5000` for local development)
  - Configure in `index.html` by setting `window.API_BASE_URL` before loading `app.js`
  - For AWS: Set to your Application Load Balancer DNS name

## Ports

- Frontend: 8080
- Backend: 5000
- Database: 5432

## Health Checks

- Backend: `GET /health` returns `{"status": "healthy"}`

## AWS Deployment Notes

### Container Images

Build and push the following images to Amazon ECR:

1. Backend image: `docker build -t taskmanager-backend ./backend`
2. Frontend image: `docker build -t taskmanager-frontend ./frontend`

### Infrastructure Setup (Teammate Responsibility)

1. **VPC and Networking**:
   - Create VPC with public and private subnets across 2+ AZs
   - Configure internet gateway, NAT gateways, route tables

2. **Database**:
   - Provision RDS PostgreSQL instance (Multi-AZ for HA)
   - Run the `database/init.sql` script to create tables
   - Configure security groups to allow access from ECS tasks only

3. **ECS Fargate**:
   - Create ECS cluster
   - Deploy backend service with task definition using the backend image
   - Configure service with 2+ tasks across AZs

4. **Application Load Balancer**:
   - Create ALB in public subnets
   - Configure target group for backend service (port 5000)
   - Add health check path: `/health`
   - Configure security groups

5. **Frontend**:
   - Deploy frontend as static site or additional ECS service
   - Configure to point to ALB DNS for API calls

6. **Security**:
   - Use IAM roles for ECS tasks
   - Configure security groups with minimal required access
   - Enable encryption in transit and at rest

### Environment Variables for AWS

Update the backend environment variables in ECS task definition:

- `DATABASE_URL`: Use RDS endpoint and credentials from Secrets Manager or Parameter Store

### Deploying Frontend and Backend as Separate ECS Tasks

1. **Build and Push Images to ECR**:
   ```bash
   # Backend
   docker build -t taskmanager-backend ./backend
   aws ecr get-login-password --region your-region | docker login --username AWS --password-stdin your-account.dkr.ecr.your-region.amazonaws.com
   docker tag taskmanager-backend:latest your-account.dkr.ecr.your-region.amazonaws.com/taskmanager-backend:latest
   docker push your-account.dkr.ecr.your-region.amazonaws.com/taskmanager-backend:latest

   # Frontend
   docker build -t taskmanager-frontend ./frontend
   docker tag taskmanager-frontend:latest your-account.dkr.ecr.your-region.amazonaws.com/taskmanager-frontend:latest
   docker push your-account.dkr.ecr.your-region.amazonaws.com/taskmanager-frontend:latest
   ```

2. **Create ECS Cluster**:
   - Create an ECS cluster in your VPC

3. **Create Task Definitions**:
   - **Backend Task Definition**:
     - Container: ECR backend image
     - Port: 5000
     - Environment variables: `DATABASE_URL` pointing to RDS
     - Health check: `CMD-SHELL curl -f http://localhost:5000/health`
   - **Frontend Task Definition**:
     - Container: ECR frontend image
     - Port: 80
     - Environment: None (API URL configured in HTML)

4. **Create Services**:
   - **Backend Service**:
     - Attach to ALB target group (port 5000)
     - Desired count: 2+ for HA
     - Service discovery or ALB for frontend to access
   - **Frontend Service**:
     - Can use ALB or service discovery
     - For public access, attach to ALB

5. **Configure Frontend for Production**:
   - Update `window.API_BASE_URL` in `index.html` to your ALB DNS (e.g., `http://your-alb-123456789.us-east-1.elb.amazonaws.com`)
   - Rebuild and push frontend image with updated config

6. **Network Configuration**:
   - Backend service in private subnets
   - Frontend service in public subnets (if needed)
   - ALB in public subnets routing to backend

### Monitoring

- Enable CloudWatch logs for ECS services
- Set up CloudWatch alarms for ALB and RDS metrics
- Configure health checks and auto-scaling if needed

## Project Structure

```
.
├── backend/
│   ├── app.py
│   ├── requirements.txt
│   └── Dockerfile
├── frontend/
│   ├── index.html
│   ├── styles.css
│   ├── app.js
│   └── Dockerfile
├── database/
│   └── init.sql
├── docker-compose.yml
├── README.md
├── overview.md
└── proyect-brief.md