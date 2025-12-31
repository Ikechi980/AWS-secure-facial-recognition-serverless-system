import json
import boto3
from common import response, require_keys, env

s3 = boto3.client("s3")

def handler(event, context):
    try:
        body = json.loads(event.get("body") or "{}")
        require_keys(body, ["objectKey", "contentType"])

        bucket = env("BUCKET_NAME")
        ttl = int(env("UPLOAD_URL_TTL_SECONDS"))

        object_key = body["objectKey"].strip()
        content_type = body["contentType"].strip()

        if not content_type.startswith("image/"):
            return response(400, {"message": "contentType must be an image/*"})

        url = s3.generate_presigned_url(
            ClientMethod="put_object",
            Params={
                "Bucket": bucket,
                "Key": object_key,
                "ContentType": content_type
            },
            ExpiresIn=ttl
        )

        return response(200, {
            "uploadUrl": url,
            "bucket": bucket,
            "objectKey": object_key,
            "expiresInSeconds": ttl
        })

    except ValueError as e:
        return response(400, {"message": str(e)})
    except Exception as e:
        return response(500, {"message": "internal_error", "detail": str(e)})
