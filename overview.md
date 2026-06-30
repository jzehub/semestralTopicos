# Task Manager for Dev Teams - Project Documentation

## Project Overview
Build a fully functional CRUD application on AWS with multi-AZ backend, Application Load Balancer, managed database, and a frontend consuming the API. The application must demonstrate high availability, proper network segmentation, and complete separation of concerns across layers.

## Team Scope
**Our responsibility:** Develop the full-stack application (frontend + backend + database schema) and package it as Docker containers ready for AWS deployment.

**Infrastructure team responsibility:** Deploy containers to AWS ECS Fargate, configure ALB, set up VPC/networking, provision RDS, and ensure multi-AZ availability.

## Tech Stack
- **Backend:** Python + Flask
- **Frontend:** HTML + CSS + JavaScript (vanilla)
- **Database:** PostgreSQL
- **Containerization:** Docker

## Architecture
Three-tier application:
- **Frontend Layer:** Static web interface served via nginx
- **Backend Layer:** REST API handling business logic
- **Database Layer:** PostgreSQL with task data persistence

All layers communicate through environment variables and are independently containerized.

## User Stories

### US-1: Create Tasks
As a dev team member, I want to create new tasks with title, description, priority, status, assignee, estimated hours, and tags, so I can track work items.

### US-2: View All Tasks
As a dev team member, I want to see a list of all tasks with their details displayed in a table, so I can get an overview of the team's work.

### US-3: View Single Task
As a dev team member, I want to view complete details of a specific task, so I can understand its full context.

### US-4: Update Tasks
As a dev team member, I want to edit any task field (title, description, status, priority, assignee, hours, tags), so I can keep information current.

### US-5: Delete Tasks
As a dev team member, I want to delete tasks that are no longer relevant, so the list stays clean and organized.

### US-6: Visual Priority Indicators
As a dev team member, I want to see color-coded priority badges (critical=red, high=yellow, medium=blue, low=green), so I can quickly identify important tasks.

## Component Breakdown

### Frontend Requirements
- Task list table displaying all fields
- Create task form with all input fields
- Edit task form (pre-populated with existing data)
- Delete button with confirmation dialog
- Priority badges with color coding
- Status dropdown with valid options
- Responsive layout
- API endpoint configuration via environment variable

### Backend Requirements
- `POST /tasks` - Create new task
- `GET /tasks` - Retrieve all tasks
- `GET /tasks/:id` - Retrieve single task by ID
- `PUT /tasks/:id` - Update existing task
- `DELETE /tasks/:id` - Delete task
- CORS configuration for frontend access
- Database connection via environment variables
- Input validation for required fields
- Health check endpoint for ALB
- JSON request/response handling

### Database Requirements
- `tasks` table with schema:
  - `id` (Primary Key, Auto-increment)
  - `title` (VARCHAR(255), NOT NULL)
  - `description` (TEXT)
  - `status` (VARCHAR(50), default: 'backlog')
  - `priority` (VARCHAR(20), default: 'medium')
  - `assigned_to` (VARCHAR(100))
  - `estimated_hours` (DECIMAL)
  - `tags` (VARCHAR(255))
  - `created_at` (TIMESTAMP, default: NOW())
  - `updated_at` (TIMESTAMP, auto-update on modification)
- Initialization script for table creation
- Proper indexes on `id` and `status`

## Deliverables
1. Backend Docker image with documented environment variables
2. Frontend Docker image with documented configuration
3. Database initialization SQL script
4. docker-compose.yml for local testing
5. README with:
   - Environment variables needed for each service
   - Port configurations
   - Health check endpoints
   - Local testing instructions
   - AWS deployment notes for infrastructure team

## Valid Values
- **Status options:** `backlog`, `todo`, `in_progress`, `in_review`, `done`
- **Priority options:** `low`, `medium`, `high`, `critical`