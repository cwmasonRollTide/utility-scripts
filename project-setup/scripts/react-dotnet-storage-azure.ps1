# PowerShell script for setting up a full-stack .NET and React project with Azure deployment
# Assumes you have the Azure CLI installed and logged in
# Assumes you have the Docker Desktop installed
# Assumes you have the .NET SDK installed
# Assumes you have the Node.js installed
# Assumes you will host this code in an Azure DevOps pipeline for deployment to work

Add-Type -AssemblyName System.Windows.Forms

$folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
$folderBrowser.Description = 'Select the folder to scan'
$folderBrowser.RootFolder = [System.Environment+SpecialFolder]::MyComputer
$folderBrowser.ShowNewFolderButton = $true

if ($folderBrowser.ShowDialog() -eq 'OK') {
    $baseDirectory = $folderBrowser.SelectedPath
} else {
    Write-Host "No folder selected, exiting script."
    exit
}
# Set the base directory as the current directory
Set-Location $baseDirectory

Write-Host "Creating the project..."
$projectName = Read-Host "Enter the project name"
$solutionName = Read-Host "Enter the solution name"

# Create project directory and set as current directory
New-Item -Path $projectName -ItemType Directory
Set-Location $projectName

# Create solution and projects
Write-Host "Creating the solution and projects..."
New-Item -Path "Backend" -ItemType Directory
Set-Location "Backend"
dotnet new sln -n $solutionName

# Create backend projects
dotnet new webapi -n "API"
dotnet new classlib -n "Application"
dotnet new classlib -n "Domain"
dotnet new classlib -n "Persistence"

# Add projects to the solution
dotnet sln add "API/API.csproj"
dotnet sln add "Application/Application.csproj"
dotnet sln add "Domain/Domain.csproj"
dotnet sln add "Persistence/Persistence.csproj"

# Add project references
Set-Location "API"
dotnet add reference "../Application/Application.csproj"
Set-Location "../Application"
dotnet add reference "../Domain/Domain.csproj"
dotnet add reference "../Persistence/Persistence.csproj"
Set-Location "../Persistence"
dotnet add reference "../Domain/Domain.csproj"
Set-Location ".."

# Create Dockerfile for backend
@"
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
RUN dotnet restore
RUN dotnet publish -c Release -o /app

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app .
ENTRYPOINT ["dotnet", "API.dll"]
"@ | Out-File -FilePath "API/Dockerfile"

# Create frontend project
$frontendType = Read-Host "Choose the frontend type (1 - Vite, 2 - Create React App, 3 - Next.js)"
$frontendLang = Read-Host "Choose the frontend language (1 - TypeScript, 2 - JavaScript)"
Set-Location ".."
New-Item -Path "Frontend" -ItemType Directory
Set-Location "Frontend"
switch ($frontendType) {
    "1" {
        if ($frontendLang -eq "1") {
            Start-Process npm -ArgumentList "init vite@latest . --template react-ts" -NoNewWindow -Wait
        } else {
            Start-Process npm -ArgumentList "init vite@latest . --template react" -NoNewWindow -Wait
        }
    }
    "2" {
        if ($frontendLang -eq "1") {
            Start-Process npx -ArgumentList "create-react-app . --template typescript" -NoNewWindow -Wait
        } else {
            Start-Process npx -ArgumentList "create-react-app ." -NoNewWindow -Wait
        }
    }
    "3" {
        if ($frontendLang -eq "1") {
            Start-Process npx -ArgumentList "create-next-app@latest . --typescript" -NoNewWindow -Wait
        } else {
            Start-Process npx -ArgumentList "create-next-app@latest ." -NoNewWindow -Wait
        }
    }
}

# Create Dockerfile for frontend
@"
FROM node:18 AS build
WORKDIR /app
COPY . .
RUN npm install
RUN npm run build

FROM nginx:stable-alpine
COPY --from=build /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
"@ | Out-File -FilePath "Dockerfile"

# Prompt for MongoDB database name
$mongoDbName = Read-Host "Enter the MongoDB database name"

# Docker Compose setup
Set-Location ".."
@"
version: '3'
services:
  backend:
    build:
      context: ./Backend
      dockerfile: API/Dockerfile
    ports:
      - "5000:80"
  frontend:
    build:
      context: ./Frontend
      dockerfile: Dockerfile
    ports:
      - "3000:80"
    depends_on:
      - backend
  db:
    image: mongo
    environment:
      MONGO_INITDB_DATABASE: $mongoDbName
    ports:
      - "27017:27017"
    volumes:
      - mongo-data:/data/db
volumes:
  mongo-data:
"@ | Out-File -FilePath "docker-compose.yml"

# Azure DevOps pipeline setup in github workflows
New-Item -Path ".github/workflows" -ItemType Directory
Set-Location ".github/workflows"
@"
name: Deploy to Azure
on:
  push:
    branches:
      - main
      - dev
jobs:
  build-and-deploy:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v2
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: `{${ secrets.AZURE_CREDENTIALS }}`
      - name: Build and push Docker images
        run: |
          docker-compose build
          docker tag backend ${ secrets.AZURE_REGISTRY }/backend:$solutionName
          docker tag frontend ${ secrets.AZURE_REGISTRY }/frontend:$solutionName
          az acr login --name ${ secrets.AZURE_REGISTRY }
          docker push ${ secrets.AZURE_REGISTRY }/backend:$solutionName
          docker push ${ secrets.AZURE_REGISTRY }/frontend:$solutionName
      - name: Deploy Backend to Azure Container Instances
        id: deploy-backend
        run: |
          az container create --resource-group ${ secrets.AZURE_RESOURCE_GROUP } --name $projectName-backend --image ${ secrets.AZURE_REGISTRY }/backend:$solutionName --dns-name-label $projectName-backend --ports 80
          echo "::set-output name=backend_url::$(az container show --resource-group ${ secrets.AZURE_RESOURCE_GROUP } --name $projectName-backend --query ipAddress.fqdn --output tsv)"
      - name: Deploy Frontend to Azure Container Instances
        run: |
          az container create --resource-group ${ secrets.AZURE_RESOURCE_GROUP } --name $projectName-frontend --image ${ secrets.AZURE_REGISTRY }/frontend:$solutionName --dns-name-label $projectName-frontend --ports 80 --environment-variables REACT_APP_BACKEND_URL=http://${ steps.deploy-backend.outputs.backend_url }
"@ | Out-File -FilePath "deploy.yml"

Write-Host "Executing dotnet restore..."
Set-Location "../.."
Set-Location "Backend"
dotnet restore
Write-Host "Finished!"


