# Secure AWS Facial Recognition Access System

A production-style facial recognition access control system built on AWS.  
This project simulates how real-world gate devices authenticate employees using facial recognition while keeping credentials and sensitive logic off the edge.

The system separates **admin enrollment** from **gate verification**, mirrors real access control architectures, and emphasizes security boundaries, auditability, and least privilege.

---
# Architectural Diagram

![alt text](<AWS Facial Recognition System.png>)


## Why I Built This

Most facial recognition demos stop at “it works.”

This project goes further and answers harder questions:

- How do you secure enrollment without exposing credentials to devices?
- How do you let gate devices authenticate users without logging in?
- How do you prevent image uploads from becoming a security risk?
- How do you audit every access attempt?

This system is designed the way an actual enterprise access control product would be.

---

## High-Level Architecture

**One API Gateway. Two trust planes. Clear separation of responsibility.**

### Admin Plane (Authenticated)
- Used only by administrators
- Protected by Amazon Cognito
- Handles employee enrollment

### Gate Plane (Unauthenticated)
- Used by physical gate devices or kiosks
- No credentials stored on the device
- Uses short-lived S3 presigned URLs
- All identity decisions happen server-side

This mirrors how real badge readers and access gates work.

---

## System Flow

### Enrollment Flow (Admin)
1. Admin logs in via Cognito
2. Admin uploads employee image
3. Image is stored securely in S3
4. Lambda indexes the face into Amazon Rekognition
5. Employee metadata is recorded for verification and auditing

### Verification Flow (Gate Device)
1. Gate device captures or uploads an image
2. Device requests a presigned S3 upload URL
3. Image is uploaded directly to S3 (no credentials exposed)
4. Gate calls verification endpoint
5. Rekognition compares the image against enrolled faces
6. Access is granted or denied
7. Verification attempt is logged to DynamoDB

---

## Core AWS Services Used

- **Amazon API Gateway**  
  REST API with separate admin and gate security models

- **AWS Lambda**  
  Serverless business logic for presigning, enrollment, and verification

- **Amazon Rekognition**  
  Face indexing and facial comparison

- **Amazon S3**  
  Secure image storage with blocked public access and logical prefixes

- **Amazon DynamoDB**  
  Audit and verification event logging

- **Amazon Cognito**  
  Authentication for admin enrollment only

- **AWS KMS**  
  Encryption at rest for stored images and logs

- **Amazon CloudWatch**  
  Logs and metrics for all Lambda executions

---

## Security Design Decisions

- Gate devices **never authenticate**
- No AWS credentials are stored on the client
- Image uploads use **short-lived presigned URLs**
- Admin actions are fully authenticated and isolated
- Verification logic runs only on the backend
- All access attempts are auditable

These decisions intentionally reduce blast radius and credential exposure.

---

## UI Behavior

The UI is intentionally designed to behave like a real gate:
The authenticated user is enrolled by admin while the unauthenticated user is not.

- **Access Granted**  
  Green banner with confirmation message

  ![alt text](image.png)

- **Access Denied**  
  Red banner with rejection message

  ![alt text](image-1.png)

- Similarity scores are hidden by default
- Debug mode exists only for development and testing

This keeps the product behavior clean while still allowing inspection during development.

---

## Example Results

### Successful Authentication
- Employee was enrolled by admin
- Facial match exceeded threshold
- Access granted

### Failed Authentication
- Employee was not enrolled
- Facial match not found
- Access denied

Both outcomes are logged for audit purposes.

---

## What This Project Demonstrates

- Real-world AWS serverless architecture
- Secure API design with multiple trust zones
- Proper use of presigned S3 uploads
- Facial recognition with Rekognition
- Thoughtful security boundaries
- Auditability and observability
- Clean separation between admin and device workflows

---

## What I Would Do Next

If this were going to production:
- Add liveness detection
- Introduce device identity and rate limiting
- Expand audit queries and dashboards
- Add alerting for suspicious access patterns

---

## Final Notes

This is not a demo built to impress visually.  
It’s built to show **how I think about systems, security, and architecture**.

That was the goal.

