# Zurich Cloud Hackathon

## Introduction

This project implements an setup for a serverless application using a combination of AWS services like Lambda, DynamoDB, S3, and KMS. The main functionality of the application is to process JSON files uploaded to an S3 bucket and store the parsed data into a DynamoDB table.

## Infrastructure Management

The infrastructure is provisioned and managed through Terraform.

The Terraform script, organized as an aws_infra module stored in the modules directory, combines all necessary AWS resources.

Environment-specific Terraform configurations are maintained in separate scripts, allowing us to manage different environments (such as dev, test, prod) independently.

Upon executing the Terraform scripts, a `dist` folder is created. This folder is used for packaging the Python code and its dependencies into a zip file, which is then uploaded to the Lambda function.

## Code Organization

The Python code is stored in the `src` directory. This includes two primary classes, `User` and `Car`, each corresponding to a data entity in our application. 

These classes are implemented in an Object-Relational Mapping (ORM)-like fashion, allowing easy mapping of JSON data to Python objects and vice versa. 

Both classes include data validation using JSON Schema, ensuring the data integrity and consistency across our application.

## AWS Services 

The key AWS services used in this infrastructure include:

1. **AWS Lambda**: Used for executing the Python code. The code is packaged into a zip file along with its dependencies and uploaded to the Lambda function.

2. **AWS DynamoDB**: This NoSQL database service is used for storing the parsed data from JSON files. A table with additional indexes for improved query performance is created to store User data.

3. **AWS S3**: Serves as the data source where JSON files are stored. The bucket triggers the Lambda function whenever a new file is uploaded.

4. **AWS KMS**: Provides encryption and decryption services to ensure the security of sensitive data.

5. **AWS IAM**: Defines a role and policy for the Lambda function to ensure it has necessary permissions to interact with other AWS services.

## Key Decisions 

1. **Data Validation**: Implemented JSON Schema validation to maintain data integrity and consistency.

2. **ORM-like Classes**: User and Car data are managed using ORM-like classes, providing a clean and efficient way to work with data entities.

3. **Support for Single or Multiple Users**: The Python code is designed to handle both individual and multiple user entries within the same JSON file. This flexibility allows the system to process a varying number of user data at any given time, making it efficient and versatile in handling different types of input data.

## Conclusion

The architecture of this project leverages the benefits of a serverless design, Infrastructure as Code, and modular coding practices. This combination facilitates efficient development, easy scaling, and cost-effective management of resources.