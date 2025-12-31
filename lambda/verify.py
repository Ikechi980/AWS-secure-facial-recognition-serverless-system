import json
import boto3
from decimal import Decimal
from common import response, require_keys, env, now_iso

rek = boto3.client("rekognition")
ddb = boto3.resource("dynamodb")

def handler(event, context):
    try:
        body = json.loads(event.get("body") or "{}")
        require_keys(body, ["objectKey"])

        bucket = env("BUCKET_NAME")
        table_name = env("DDB_TABLE_NAME")
        collection_id = env("COLLECTION_ID")
        threshold = Decimal(env("FACE_THRESHOLD"))
        project = env("PROJECT_NAME")
        environment = env("ENVIRONMENT")

        object_key = body["objectKey"].strip()

        result = rek.search_faces_by_image(
            CollectionId=collection_id,
            Image={
                "S3Object": {
                    "Bucket": bucket,
                    "Name": object_key
                }
            },
            FaceMatchThreshold=float(threshold),
            MaxFaces=1
        )

        matches = result.get("FaceMatches", [])

        matched_employee = None
        similarity = None
        is_match = False

        if matches:
            top = matches[0]
            raw_similarity = top.get("Similarity")
            similarity = Decimal(str(raw_similarity))
            matched_employee = top["Face"].get("ExternalImageId")
            is_match = True

        table = ddb.Table(table_name)

        table.put_item(Item={
            "pk": f"VERIFY#{matched_employee or 'UNKNOWN'}",
            "sk": now_iso(),
            "eventType": "VERIFY",
            "matchedEmployeeId": matched_employee or "NONE",
            "bucket": bucket,
            "objectKey": object_key,
            "similarity": similarity if similarity else Decimal("-1"),
            "isMatch": is_match,
            "project": project,
            "environment": environment,
            "ts": now_iso()
        })

        return response(200, {
            "isMatch": is_match,
            "employeeId": matched_employee,
            "similarity": float(similarity) if similarity else None,
            "threshold": float(threshold)
        })

    except ValueError as e:
        return response(400, {"message": str(e)})

    except Exception as e:
        return response(500, {
            "message": "internal_error",
            "detail": str(e)
        })
