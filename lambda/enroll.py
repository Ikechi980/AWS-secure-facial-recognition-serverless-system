import json
import boto3
from common import response, require_keys, env, now_iso

rek = boto3.client("rekognition")
ddb = boto3.resource("dynamodb")

def handler(event, context):
    try:
        body = json.loads(event.get("body") or "{}")
        require_keys(body, ["employeeId", "objectKey"])

        bucket = env("BUCKET_NAME")
        table_name = env("DDB_TABLE_NAME")
        collection_id = env("COLLECTION_ID")
        project = env("PROJECT_NAME")
        environment = env("ENVIRONMENT")

        employee_id = body["employeeId"].strip()
        object_key = body["objectKey"].strip()

        # Index face directly from S3 (NO BYTES)
        result = rek.index_faces(
            CollectionId=collection_id,
            Image={
                "S3Object": {
                    "Bucket": bucket,
                    "Name": object_key
                }
            },
            ExternalImageId=employee_id,
            DetectionAttributes=[],
            MaxFaces=1,
            QualityFilter="AUTO"
        )

        face_records = result.get("FaceRecords", [])
        if not face_records:
            return response(400, {
                "message": "No face detected. Use a clear front-facing image."
            })

        face_id = face_records[0]["Face"]["FaceId"]

        # Audit log
        table = ddb.Table(table_name)
        table.put_item(Item={
            "pk": f"EMP#{employee_id}",
            "sk": f"ENROLL#{now_iso()}",
            "eventType": "ENROLL",
            "employeeId": employee_id,
            "faceId": face_id,
            "bucket": bucket,
            "objectKey": object_key,
            "project": project,
            "environment": environment,
            "ts": now_iso()
        })

        return response(200, {
            "message": "enrolled",
            "employeeId": employee_id,
            "faceId": face_id
        })

    except ValueError as e:
        return response(400, {"message": str(e)})
    except rek.exceptions.InvalidParameterException as e:
        return response(400, {
            "message": "rekognition_invalid_parameter",
            "detail": str(e)
        })
    except Exception as e:
        return response(500, {
            "message": "internal_error",
            "detail": str(e)
        })
