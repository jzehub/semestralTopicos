# Task Manager Azure Container Apps Deployment Guide

This guide explains how the Task Manager app was deployed to Azure using:

- Azure Database for PostgreSQL Flexible Server
- Azure Container Registry
- Azure Container Apps
- Two containers: one for the backend and one for the frontend

## Final Architecture

The final deployment looks like this:

```text
User browser
  -> Frontend Container App
  -> Backend Container App
  -> Azure Database for PostgreSQL
```

The frontend and backend are deployed as separate Azure Container Apps.

The frontend is a static web app served by Nginx. The backend is a Flask API. The backend connects to Azure PostgreSQL using the `DATABASE_URL` environment variable.

## Resources Used

The Azure resources used were:

```text
Resource group: topicos2
Region: West US
Azure Container Registry: imgstop2
PostgreSQL server: task-manager-postgre-server.postgres.database.azure.com
PostgreSQL database: task-manager-bd
Container Apps environment: taskmanager-env
Backend Container App: taskmanager-backend
Frontend Container App: taskmanager-frontend
```

## Why We Used Azure PostgreSQL

At first, Azure SQL Database was considered. However, the app was already written for PostgreSQL.

The backend uses:

```python
postgresql://...
```

and the project dependencies include:

```text
psycopg2-binary
```

Also, the `database/init.sql` file uses PostgreSQL syntax, such as:

```sql
SERIAL PRIMARY KEY
CREATE OR REPLACE FUNCTION
language 'plpgsql'
```

Because of that, Azure Database for PostgreSQL Flexible Server was the best match. It avoided rewriting the backend database driver and schema.

## Backend Configuration

The backend reads the database connection from an environment variable:

```python
app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv(
    'DATABASE_URL',
    'postgresql://user:password@db:5432/taskmanager'
)
```

In Azure Container Apps, we provided the real database URL as a secret:

```text
postgresql://taskadmin:<password>@task-manager-postgre-server.postgres.database.azure.com:5432/task-manager-bd?sslmode=require
```

The password should not be hardcoded in `app.py`. It belongs in Azure as a secret.

## Backend Image Build and Push

Since Azure ACR Tasks were not allowed in the subscription, this command failed:

```powershell
az acr build --registry imgstop2 --image taskmanager-backend:latest ./backend
```

So we built the image locally with Docker and pushed it manually:

```powershell
az acr login --name imgstop2
docker build -t imgstop2.azurecr.io/taskmanager-backend:latest ./backend
docker push imgstop2.azurecr.io/taskmanager-backend:latest
```

## Container Apps Environment

The first attempt to create the Container Apps environment in East US failed because the subscription could not create Container Apps environments in that region.

Since the PostgreSQL server and Container Registry were in West US, we created the environment in West US:

```powershell
az containerapp env create --name taskmanager-env --resource-group topicos2 --location westus
```

## Backend Container App Deployment

The backend was deployed with external ingress on port `5000`:

```powershell
az containerapp create --name taskmanager-backend --resource-group topicos2 --environment taskmanager-env --image imgstop2.azurecr.io/taskmanager-backend:latest --target-port 5000 --ingress external --registry-server imgstop2.azurecr.io --registry-username imgstop2 --registry-password <acr-password> --secrets database-url="postgresql://taskadmin:<db-password>@task-manager-postgre-server.postgres.database.azure.com:5432/task-manager-bd?sslmode=require" --env-vars DATABASE_URL=secretref:database-url
```

The backend URL became:

```text
https://taskmanager-backend.whiteground-e475bfab.westus.azurecontainerapps.io
```

We tested:

```text
https://taskmanager-backend.whiteground-e475bfab.westus.azurecontainerapps.io/health
```

and:

```text
https://taskmanager-backend.whiteground-e475bfab.westus.azurecontainerapps.io/tasks
```

The `/tasks` endpoint returned:

```json
[]
```

That means the backend was running, connected to PostgreSQL, and the database had no tasks yet.

## How the Database Table Was Created

The `database/init.sql` file was not used during deployment because the backend image was built only from the `./backend` folder.

The table was created by this code in `backend/app.py`:

```python
if __name__ == '__main__':
    with app.app_context():
        db.create_all()
```

`db.create_all()` creates the table from the SQLAlchemy model if it does not already exist.

So:

- `init.sql` was not executed.
- SQLAlchemy created the `tasks` table.
- The indexes and trigger from `init.sql` were not created.

For this demo app, that is acceptable.

## Frontend Configuration

The frontend uses this JavaScript value:

```js
const API_URL = window.API_BASE_URL;
```

In `index.html`, the value starts as a placeholder:

```html
window.API_BASE_URL = '__API_BASE_URL__';
```

The frontend Dockerfile replaces that placeholder during image build:

```dockerfile
ARG API_BASE_URL=http://localhost:5000
RUN sed -i "s|__API_BASE_URL__|${API_BASE_URL}|g" /usr/share/nginx/html/index.html
```

So when we built the frontend image, we passed the backend URL:

```powershell
docker build --build-arg API_BASE_URL=https://taskmanager-backend.whiteground-e475bfab.westus.azurecontainerapps.io -t imgstop2.azurecr.io/taskmanager-frontend:latest ./frontend
```

Then we pushed it:

```powershell
docker push imgstop2.azurecr.io/taskmanager-frontend:latest
```

## Frontend Container App Deployment

The frontend was deployed with external ingress on port `80`:

```powershell
az containerapp create --name taskmanager-frontend --resource-group topicos2 --environment taskmanager-env --image imgstop2.azurecr.io/taskmanager-frontend:latest --target-port 80 --ingress external --registry-server imgstop2.azurecr.io --registry-username imgstop2 --registry-password <acr-password>
```

The frontend URL became:

```text
https://taskmanager-frontend.whiteground-e475bfab.westus.azurecontainerapps.io
```

## How the Frontend Connects to the Backend

The frontend container does not directly connect to the backend container internally.

Instead:

```text
User browser
  -> loads frontend HTML/JS from frontend Container App
  -> frontend JavaScript calls backend public URL
  -> backend talks to PostgreSQL
```

The browser makes API calls like:

```text
https://taskmanager-backend.whiteground-e475bfab.westus.azurecontainerapps.io/tasks
```

This works because the frontend image was built with the backend URL as `API_BASE_URL`.

The backend allows cross-origin browser requests because Flask CORS is enabled:

```python
CORS(app)
```

## Main Issues and Solutions

### Issue 1: Azure SQL Database did not match the app

The app was written for PostgreSQL, but Azure SQL Database is Microsoft SQL Server.

Solution:

Use Azure Database for PostgreSQL Flexible Server instead of Azure SQL Database.

### Issue 2: PowerShell did not accept Linux line continuations

Commands using `\` failed in PowerShell.

Example of failing syntax:

```powershell
az containerapp env create \
  --name taskmanager-env \
  --resource-group topicos2
```

Solution:

Use one-line PowerShell commands or PowerShell backticks:

```powershell
az containerapp env create --name taskmanager-env --resource-group topicos2 --location westus
```

or:

```powershell
az containerapp env create `
  --name taskmanager-env `
  --resource-group topicos2 `
  --location westus
```

### Issue 3: ACR Tasks were not allowed

`az acr build` failed with:

```text
ACR Tasks requests are not permitted
```

Solution:

Build the Docker image locally and push it manually:

```powershell
docker build -t imgstop2.azurecr.io/taskmanager-backend:latest ./backend
docker push imgstop2.azurecr.io/taskmanager-backend:latest
```

### Issue 4: Docker Desktop was not running

Docker commands failed because the Docker Desktop Linux engine was unavailable.

Solution:

Open Docker Desktop, wait for it to start, then run:

```powershell
docker version
```

After Docker was running, local builds worked.

### Issue 5: Docker was not authenticated to ACR

The image push failed with:

```text
authentication required
```

Solution:

Run:

```powershell
az acr login --name imgstop2
```

Then push the image again.

### Issue 6: Azure Portal rejected the image tag

The Portal showed:

```text
Selected tag uses an invalid operating system ''
```

Solution:

Use the CLI instead of the Portal, or rebuild the image with explicit Linux platform/provenance settings if needed.

### Issue 7: East US could not create Container Apps Environment

Creating the environment in `eastus` failed due to subscription or regional limits.

Solution:

Create the Container Apps environment in `westus`, matching the PostgreSQL server and Container Registry region:

```powershell
az containerapp env create --name taskmanager-env --resource-group topicos2 --location westus
```

### Issue 8: Container App could not pull from private ACR

Container Apps could not retrieve registry credentials automatically.

Solution:

Enable ACR admin credentials:

```powershell
az acr update --name imgstop2 --admin-enabled true
```

Get credentials:

```powershell
az acr credential show --name imgstop2
```

Then pass them during `az containerapp create`:

```powershell
--registry-username imgstop2 --registry-password <acr-password>
```

## Important Security Notes

During deployment, some secrets were used directly in commands.

For a real project, rotate:

- PostgreSQL password
- ACR password

Then update the Azure Container App secrets.

Also, avoid hardcoding passwords in source code. Use Container Apps secrets and environment variables instead.

## Final Result

The app was successfully deployed with:

- Backend running in Azure Container Apps
- Frontend running in Azure Container Apps
- Data stored in Azure Database for PostgreSQL
- Images stored in Azure Container Registry

The frontend can create, read, update, and delete tasks by calling the backend API over HTTPS.
