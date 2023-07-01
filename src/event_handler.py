import json
import boto3
import logging

from user import User


logging.getLogger().setLevel(logging.DEBUG)


def download_and_parse_s3_object(bucket, object_key):
    """
    Download and parse an S3 object as JSON.

    :param bucket: S3 bucket name
    :param object_key: S3 object key
    :return: Parsed JSON object
    """
    # Create a boto3 client
    s3 = boto3.client("s3")

    # Download the object and read it
    s3_object = s3.get_object(Bucket=bucket, Key=object_key)
    s3_data = s3_object["Body"].read().decode("utf-8")

    # Parse the data as JSON and return
    return json.loads(s3_data)


def post_user_objects(user_data):
    """
    Create User objects from provided user data.

    :param user_data: List of dictionaries or single dictionary with user data
    :return: List of User objects
    """
    # Initialize an empty list to hold User objects
    user_objects = []

    # If user_data is a dictionary, convert it to a list
    if isinstance(user_data, dict):
        user_data = [user_data]

    # Create a User object for each dictionary and add to the list
    for user_dict in user_data:
        user = User(user_dict)
        user_objects.append(user)

    for user in user_objects:
        user.save()

    return user_objects


def event_handler(event, context):
    """
    AWS Lambda function handler.

    :param event: AWS Lambda function event
    :param context: AWS Lambda function context
    """
    logging.debug("Event: %s", event)

    # Get the bucket name and object key from the event
    bucket = event["Records"][0]["s3"]["bucket"]["name"]
    object_key = event["Records"][0]["s3"]["object"]["key"]

    logging.debug("Bucket: %s Object: %s", bucket, object_key)

    # Download and parse S3 object
    user_data = download_and_parse_s3_object(bucket, object_key)

    # Storing the user information in database
    post_user_objects(user_data)
