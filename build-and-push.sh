#!/bin/bash

# Build and Push Docker Images to Docker Hub
# This script builds the backend and frontend Docker images, tags them, and pushes them to Docker Hub.

# Set environment variables or use defaults (update these with your actual values)
DOCKER_USERNAME=${DOCKER_USERNAME:-"your-dockerhub-username"}
BACKEND_REPO=${BACKEND_REPO:-"backend-repo"}
FRONTEND_REPO=${FRONTEND_REPO:-"frontend-repo"}
TAG=${TAG:-"latest"}

# Prompt for Docker Hub password if not set
if [ -z "$DOCKER_PASSWORD" ]; then
    echo "Enter your Docker Hub password:"
    read -s DOCKER_PASSWORD
fi

# Login to Docker Hub
echo "Logging into Docker Hub..."
echo "$DOCKER_PASSWORD" | docker login -u $DOCKER_USERNAME --password-stdin

# Build and push backend image
echo "Building backend image..."
cd backend
docker build -t $DOCKER_USERNAME/$BACKEND_REPO:$TAG .
echo "Pushing backend image..."
docker push $DOCKER_USERNAME/$BACKEND_REPO:$TAG
cd ..

# Build and push frontend image
echo "Building frontend image..."
cd frontend
docker build -t $DOCKER_USERNAME/$FRONTEND_REPO:$TAG .
echo "Pushing frontend image..."
docker push $DOCKER_USERNAME/$FRONTEND_REPO:$TAG
cd ..

echo "All images built and pushed successfully!"