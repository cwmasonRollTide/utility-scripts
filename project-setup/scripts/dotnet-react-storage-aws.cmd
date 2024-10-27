:: This script is used to create a dotnet backend, react frontend, 
:: and either relational rds database or nosql dynamodb database
:: Included docker-compose file to run the application locally
:: as well as github action to deploy to aws and run terraform commands

:: Necessary Github Action Secrets:
:: AWS_ACCESS_KEY_ID
:: AWS_SECRET_ACCESS_KEY
:: AWS_REGION
:: TF_VAR_domain_name
:: TF_VAR_db_username
:: TF_VAR_db_password

@echo off
setlocal

:: Create the project
set /p "projectName=Enter the project name: "
set /p "solutionName=Enter the solution name: "

mkdir %projectName%
cd %projectName%

echo Creating the solution and projects...
mkdir Backend
cd Backend
dotnet new sln -n %solutionName%

set /p "frontendType=Choose the frontend type (1 - Vite, 2 - Create React App, 3 - Next.js): "
set /p "frontendLang=Choose the frontend language (1 - TypeScript, 2 - JavaScript): "

:: Create the frontend project
if "%frontendType%"=="1" (
    if "%frontendLang%"=="1" (
        call npm init vite@latest ../Client -- --template react-ts
    ) else (
        call npm init vite@latest ../Client -- --template react
    )
) else if "%frontendType%"=="2" (
    if "%frontendLang%"=="1" (
        call npx create-react-app ../Client --template typescript
    ) else (
        call npx create-react-app ../Client
    )
) else if "%frontendType%"=="3" (
    if "%frontendLang%"=="1" (
        call npx create-next-app@latest ../Client --typescript
    ) else (
        call npx create-next-app@latest ../Client
    )
)

:: Create the backend project
dotnet new webapi -n API
dotnet new classlib -n Application
dotnet new classlib -n Domain
dotnet new classlib -n Persistence

echo Adding projects to the solution...
dotnet sln add API/API.csproj
dotnet sln add Application/Application.csproj
dotnet sln add Domain/Domain.csproj
dotnet sln add Persistence/Persistence.csproj

echo Adding project references...
cd API
dotnet add reference ../Application/Application.csproj
cd ../Application
dotnet add reference ../Domain/Domain.csproj
dotnet add reference ../Persistence/Persistence.csproj
cd ../Persistence
dotnet add reference ../Domain/Domain.csproj
cd ..

echo Creating Docker and Docker Compose files...
cd ..
echo # Dockerfile for backend > Backend/backend.Dockerfile
echo FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build >> Backend/backend.Dockerfile
echo WORKDIR /app >> Backend/backend.Dockerfile
echo COPY . . >> Backend/backend.Dockerfile
echo RUN dotnet restore >> Backend/backend.Dockerfile
echo RUN dotnet publish -c Release -o out >> Backend/backend.Dockerfile
echo RUN mkdir /app/publish >> Backend/backend.Dockerfile
echo RUN cp -r /app/out /app/publish >> Backend/backend.Dockerfile
echo FROM mcr.microsoft.com/dotnet/aspnet:8.0 >> Backend/backend.Dockerfile
echo WORKDIR /app >> Backend/backend.Dockerfile
echo COPY --from=build /app/out . >> Backend/backend.Dockerfile
echo COPY --from=build /app/publish /app/publish >> Backend/backend.Dockerfile
echo ENTRYPOINT ["dotnet", "API.dll"] >> Backend/backend.Dockerfile

echo # Dockerfile for frontend > Client/frontend.Dockerfile
echo FROM node:18 AS build >> Client/frontend.Dockerfile
echo WORKDIR /app >> Client/frontend.Dockerfile
echo COPY . . >> Client/frontend.Dockerfile
echo RUN npm install >> Client/frontend.Dockerfile
echo RUN npm run build >> Client/frontend.Dockerfile
echo FROM nginx:stable-alpine >> Client/frontend.Dockerfile
echo COPY --from=build /app/dist /usr/share/nginx/html >> Client/frontend.Dockerfile
echo EXPOSE 80 >> Client/frontend.Dockerfile
echo CMD ["nginx", "-g", "daemon off;"] >> Client/frontend.Dockerfile

echo version: '3' > docker-compose.yml
echo services: >> docker-compose.yml
echo   backend: >> docker-compose.yml
echo     build: >> docker-compose.yml
echo       context: ./Backend >> docker-compose.yml
echo       dockerfile: backend.Dockerfile >> docker-compose.yml
echo     ports: >> docker-compose.yml
echo       - "5000:80" >> docker-compose.yml

set /p "storageType=Choose the storage type (1 - DynamoDB, 2 - Amazon RDS PostgreSQL): "

if "%storageType%"=="1" (
    echo   dynamodb-local: >> docker-compose.yml
    echo     image: amazon/dynamodb-local >> docker-compose.yml
    echo     ports: >> docker-compose.yml
    echo       - "8000:8000" >> docker-compose.yml
) else if "%storageType%"=="2" (
    echo   db: >> docker-compose.yml
    echo     image: postgres:14.1 >> docker-compose.yml
    echo     environment: >> docker-compose.yml
    echo       POSTGRES_USER: myuser >> docker-compose.yml
    echo       POSTGRES_PASSWORD: mypassword >> docker-compose.yml
    echo     ports: >> docker-compose.yml
    echo       - "5432:5432" >> docker-compose.yml
)

echo   frontend: >> docker-compose.yml
echo     build: >> docker-compose.yml
echo       context: ./Client >> docker-compose.yml
echo       dockerfile: frontend.Dockerfile >> docker-compose.yml
echo     ports: >> docker-compose.yml
echo       - "3000:80" >> docker-compose.yml
echo     depends_on: >> docker-compose.yml
echo       - backend >> docker-compose.yml

:: Create the terraform project
echo Creating Terraform project...
mkdir infrastructure
cd infrastructure

echo variable "domain_name" { >> variables.tf
echo   type        = string >> variables.tf
echo   description = "The domain name for the website" >> variables.tf
echo } >> variables.tf

echo variable "db_username" { >> variables.tf
echo   type        = string >> variables.tf
echo   description = "The username for the database" >> variables.tf
echo } >> variables.tf

echo variable "db_password" { >> variables.tf
echo   type        = string >> variables.tf
echo   description = "The password for the database" >> variables.tf
echo } >> variables.tf

echo variable "environment" { >> variables.tf
echo   type        = string >> variables.tf
echo   description = "The environment (dev or prod)" >> variables.tf
echo   default     = "dev" >> variables.tf
echo } >> variables.tf

echo provider "aws" { > main.tf
echo   region = "us-east-2" >> main.tf
echo } >> main.tf

echo data "aws_availability_zones" "available" {} >> main.tf

echo resource "aws_vpc" "main" { >> main.tf
echo   cidr_block = "10.0.0.0/16" >> main.tf
echo } >> main.tf

echo resource "aws_internet_gateway" "main" { >> main.tf
echo   vpc_id = aws_vpc.main.id >> main.tf
echo } >> main.tf

echo resource "aws_subnet" "public" { >> main.tf
echo   count             = 2 >> main.tf
echo   cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index) >> main.tf
echo   availability_zone = data.aws_availability_zones.available.names[count.index] >> main.tf
echo   vpc_id            = aws_vpc.main.id >> main.tf
echo } >> main.tf

echo resource "aws_security_group" "backend" { >> main.tf
echo   name        = "backend-security-group-${var.environment}" >> main.tf
echo   description = "Security group for the backend" >> main.tf
echo   vpc_id      = aws_vpc.main.id >> main.tf
echo   ingress { >> main.tf
echo     from_port   = 80 >> main.tf
echo     to_port     = 80 >> main.tf
echo     protocol    = "tcp" >> main.tf
echo     cidr_blocks = ["10.0.0.0/16"] >> main.tf
echo   } >> main.tf
echo } >> main.tf

echo resource "aws_security_group" "frontend" { >> main.tf
echo   name        = "frontend-security-group-${var.environment}" >> main.tf
echo   description = "Security group for the frontend" >> main.tf
echo   vpc_id      = aws_vpc.main.id >> main.tf
echo   ingress { >> main.tf
echo     from_port   = 80 >> main.tf
echo     to_port     = 80 >> main.tf
echo     protocol    = "tcp" >> main.tf
echo     cidr_blocks = ["0.0.0.0/0"] >> main.tf
echo   } >> main.tf
echo } >> main.tf

echo resource "aws_ecs_cluster" "main" { >> main.tf
echo   name = "my-cluster-${var.environment}" >> main.tf
echo } >> main.tf

echo resource "aws_ecs_task_definition" "backend" { >> main.tf
echo   family                   = "backend-task-${var.environment}" >> main.tf
echo   network_mode             = "awsvpc" >> main.tf
echo   requires_compatibilities = ["FARGATE"] >> main.tf
echo   cpu                      = 256 >> main.tf
echo   memory                   = 512 >> main.tf
echo   container_definitions    = jsonencode([ >> main.tf
echo     { >> main.tf
echo       name      = "backend-container-${var.environment}" >> main.tf
echo       image     = "backend-image-${var.environment}" >> main.tf
echo       essential = true >> main.tf
echo       portMappings = [ >> main.tf
echo         { >> main.tf
echo           containerPort = 80 >> main.tf
echo           hostPort      = 80 >> main.tf
echo         } >> main.tf
echo       ] >> main.tf
echo     } >> main.tf
echo   ]) >> main.tf
echo } >> main.tf

echo resource "aws_ecs_task_definition" "frontend" { >> main.tf
echo   family                   = "frontend-task-${var.environment}" >> main.tf
echo   network_mode             = "awsvpc" >> main.tf
echo   requires_compatibilities = ["FARGATE"] >> main.tf
echo   cpu                      = 256 >> main.tf
echo   memory                   = 512 >> main.tf
echo   container_definitions    = jsonencode([ >> main.tf
echo     { >> main.tf
echo       name      = "frontend-container-${var.environment}" >> main.tf
echo       image     = "frontend-image-${var.environment}" >> main.tf
echo       essential = true >> main.tf
echo       portMappings = [ >> main.tf
echo         { >> main.tf
echo           containerPort = 80 >> main.tf
echo           hostPort      = 80 >> main.tf
echo         } >> main.tf
echo       ] >> main.tf
echo     } >> main.tf
echo   ]) >> main.tf
echo } >> main.tf

echo resource "aws_ecs_service" "backend" { >> main.tf
echo   name            = "backend-service-${var.environment}" >> main.tf
echo   cluster         = aws_ecs_cluster.main.id >> main.tf
echo   task_definition = aws_ecs_task_definition.backend.arn >> main.tf
echo   desired_count   = 1 >> main.tf
echo   launch_type     = "FARGATE" >> main.tf
echo   network_configuration { >> main.tf
echo     security_groups  = [aws_security_group.backend.id] >> main.tf
echo     subnets          = aws_subnet.public[*].id >> main.tf
echo     assign_public_ip = true >> main.tf
echo   } >> main.tf
echo } >> main.tf

echo resource "aws_ecs_service" "frontend" { >> main.tf
echo   name            = "frontend-service-${var.environment}" >> main.tf
echo   cluster         = aws_ecs_cluster.main.id >> main.tf
echo   task_definition = aws_ecs_task_definition.frontend.arn >> main.tf
echo   desired_count   = 1 >> main.tf
echo   launch_type     = "FARGATE" >> main.tf
echo   network_configuration { >> main.tf
echo     security_groups  = [aws_security_group.frontend.id] >> main.tf
echo     subnets          = aws_subnet.public[*].id >> main.tf
echo     assign_public_ip = true >> main.tf
echo   } >> main.tf
echo } >> main.tf

echo resource "aws_lb" "frontend" { >> main.tf
echo   name               = "frontend-lb-${var.environment}" >> main.tf
echo   internal           = false >> main.tf
echo   load_balancer_type = "application" >> main.tf
echo   security_groups    = [aws_security_group.frontend.id] >> main.tf
echo   subnets            = aws_subnet.public[*].id >> main.tf
echo } >> main.tf

echo resource "aws_lb_target_group" "frontend" { >> main.tf
echo   name        = "frontend-target-group-${var.environment}" >> main.tf
echo   port        = 80 >> main.tf
echo   protocol    = "HTTP" >> main.tf
echo   vpc_id      = aws_vpc.main.id >> main.tf
echo   target_type = "ip" >> main.tf
echo } >> main.tf

echo resource "aws_lb_listener" "frontend" { >> main.tf
echo   load_balancer_arn = aws_lb.frontend.arn >> main.tf
echo   port              = 80 >> main.tf
echo   protocol          = "HTTP" >> main.tf
echo   default_action { >> main.tf
echo     type             = "forward" >> main.tf
echo     target_group_arn = aws_lb_target_group.frontend.arn >> main.tf
echo   } >> main.tf
echo } >> main.tf

echo resource "aws_route53_zone" "main" { >> main.tf
echo   name = var.domain_name >> main.tf
echo } >> main.tf

echo resource "aws_route53_record" "frontend" { >> main.tf
echo   zone_id = aws_route53_zone.main.zone_id >> main.tf
echo   name    = var.domain_name >> main.tf
echo   type    = "A" >> main.tf
echo   alias { >> main.tf
echo     name                   = aws_lb.frontend.dns_name >> main.tf
echo     zone_id                = aws_lb.frontend.zone_id >> main.tf
echo     evaluate_target_health = true >> main.tf
echo   } >> main.tf
echo } >> main.tf

echo resource "aws_acm_certificate" "frontend" { >> main.tf
echo   domain_name       = var.domain_name >> main.tf
echo   validation_method = "DNS" >> main.tf
echo } >> main.tf

echo resource "aws_route53_record" "cert_validation" { >> main.tf
echo   name    = tolist(aws_acm_certificate.frontend.domain_validation_options)[0].resource_record_name >> main.tf
echo   type    = tolist(aws_acm_certificate.frontend.domain_validation_options)[0].resource_record_type >> main.tf
echo   zone_id = aws_route53_zone.main.zone_id >> main.tf
echo   records = [tolist(aws_acm_certificate.frontend.domain_validation_options)[0].resource_record_value] >> main.tf
echo   ttl     = 60 >> main.tf
echo } >> main.tf

echo resource "aws_lb_listener" "frontend_https" { >> main.tf
echo   load_balancer_arn = aws_lb.frontend.arn >> main.tf
echo   port              = 443 >> main.tf
echo   protocol          = "HTTPS" >> main.tf
echo   ssl_policy        = "ELBSecurityPolicy-2016-08" >> main.tf
echo   certificate_arn   = aws_acm_certificate.frontend.arn >> main.tf
echo   default_action { >> main.tf
echo     type             = "forward" >> main.tf
echo     target_group_arn = aws_lb_target_group.frontend.arn >> main.tf
echo   } >> main.tf
echo } >> main.tf

if "%storageType%"=="1" (
    echo resource "aws_dynamodb_table" "main" { >> main.tf
    echo   name           = "my-table-${var.environment}" >> main.tf
    echo   billing_mode   = "PROVISIONED" >> main.tf
    echo   read_capacity  = 5 >> main.tf
    echo   write_capacity = 5 >> main.tf
    echo   hash_key       = "id" >> main.tf
    echo   attribute { >> main.tf
    echo     name = "id" >> main.tf
    echo     type = "S" >> main.tf
    echo   } >> main.tf
    echo } >> main.tf
) else if "%storageType%"=="2" (
    echo resource "aws_db_instance" "main" { >> main.tf
    echo   allocated_storage    = 20 >> main.tf
    echo   engine               = "postgres" >> main.tf
    echo   engine_version       = "14.1" >> main.tf
    echo   instance_class       = "db.t3.micro" >> main.tf
    echo   username             = var.db_username >> main.tf
    echo   password             = var.db_password >> main.tf
    echo   parameter_group_name = "default.postgres14" >> main.tf
    echo   skip_final_snapshot  = true >> main.tf
    echo } >> main.tf
)

echo resource "aws_cloudwatch_log_group" "backend" { >> main.tf
echo   name = "/ecs/backend-${var.environment}" >> main.tf
echo } >> main.tf

echo resource "aws_cloudwatch_log_group" "frontend" { >> main.tf
echo   name = "/ecs/frontend-${var.environment}" >> main.tf
echo } >> main.tf

echo resource "aws_cloudwatch_log_stream" "backend" { >> main.tf
echo   name           = "backend-log-stream-${var.environment}" >> main.tf
echo   log_group_name = aws_cloudwatch_log_group.backend.name >> main.tf
echo } >> main.tf

echo resource "aws_cloudwatch_log_stream" "frontend" { >> main.tf
echo   name           = "frontend-log-stream-${var.environment}" >> main.tf
echo   log_group_name = aws_cloudwatch_log_group.frontend.name >> main.tf
echo } >> main.tf

cd ..

echo node_modules/ > .gitignore
echo bin/ >> .gitignore
echo obj/ >> .gitignore

:: Create the Github Action CI/CD
mkdir .github
cd .github
mkdir workflows
cd workflows

echo name: Deploy to AWS >> deploy.yml
echo on: >> deploy.yml
echo   push: >> deploy.yml
echo     branches: >> deploy.yml
echo       - main >> deploy.yml
echo       - dev >> deploy.yml
echo jobs: >> deploy.yml
echo   deploy: >> deploy.yml
echo     runs-on: ubuntu-latest >> deploy.yml
echo     steps: >> deploy.yml
echo       - uses: actions/checkout@v2 >> deploy.yml
echo       - name: Configure AWS credentials >> deploy.yml
echo         uses: aws-actions/configure-aws-credentials@v1 >> deploy.yml
echo         with: >> deploy.yml
echo           aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }} >> deploy.yml
echo           aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }} >> deploy.yml
echo           aws-region: us-east-2 >> deploy.yml
echo       - name: Login to Amazon ECR >> deploy.yml
echo         id: login-ecr >> deploy.yml
echo         uses: aws-actions/amazon-ecr-login@v1 >> deploy.yml
echo       - name: Build, tag, and push backend image to Amazon ECR >> deploy.yml
echo         env: >> deploy.yml
echo           ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }} >> deploy.yml
echo           ECR_REPOSITORY: backend >> deploy.yml
echo           IMAGE_TAG: ${{ github.sha }} >> deploy.yml
echo         run: ^| >> deploy.yml
echo           docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG -f backend.Dockerfile ./Backend >> deploy.yml
echo           docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG >> deploy.yml
echo       - name: Build, tag, and push frontend image to Amazon ECR >> deploy.yml
echo         env: >> deploy.yml
echo           ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }} >> deploy.yml
echo           ECR_REPOSITORY: frontend >> deploy.yml
echo           IMAGE_TAG: ${{ github.sha }} >> deploy.yml
echo         run: ^| >> deploy.yml
echo           docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG -f frontend.Dockerfile . >> deploy.yml
echo           docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG >> deploy.yml
echo       - name: Terraform Init >> deploy.yml  
echo         run: terraform init ./infrastructure >> deploy.yml
echo       - name: Terraform Plan >> deploy.yml
echo         run: terraform plan -var "environment=${{ github.ref == 'refs/heads/main' && 'prod' || 'dev' }}" -var "domain_name=${{ secrets.TF_VAR_domain_name }}" -var "db_username=${{ secrets.TF_VAR_db_username }}" -var "db_password=${{ secrets.TF_VAR_db_password }}" ./infrastructure >> deploy.yml
echo       - name: Terraform Apply >> deploy.yml
echo         if: github.ref == 'refs/heads/main' ^|^| github.ref == 'refs/heads/dev' >> deploy.yml
echo         run: terraform apply -auto-approve -var "environment=${{ github.ref == 'refs/heads/main' && 'prod' || 'dev' }}" -var "domain_name=${{ secrets.TF_VAR_domain_name }}" -var "db_username=${{ secrets.TF_VAR_db_username }}" -var "db_password=${{ secrets.TF_VAR_db_password }}" ./infrastructure >> deploy.yml
cd ../..
echo Executing dotnet restore...
cd Backend
dotnet restore
echo Finished!
endlocal