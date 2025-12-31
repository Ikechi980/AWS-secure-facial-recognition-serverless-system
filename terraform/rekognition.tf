resource "aws_rekognition_collection" "faces" {
  collection_id = local.rek_collection
}
