# main.py
import os
import boto3
import jsonschema
from botocore.exceptions import BotoCoreError, ClientError

from car import Car


class User:
    """
    A class representing a User with several attributes and methods
    to interact with DynamoDB
    """

    USER_SCHEMA = {
        "type": "object",
        "properties": {
            "id": {"type": "string"},
            "name": {"type": "string"},
            "surname": {"type": "string"},
            "birthdate": {"type": "string", "format": "date"},
            "address": {"type": "string"},
            "car": {"type": "object"},
            "fee": {"type": "integer"},
        },
        "required": ["id", "name", "surname", "birthdate", "address", "car", "fee"],
    }

    def __init__(self, user_dict, table_name="UserTable"):
        """
        Initialize User instance with attributes from dictionary.

        :param user_dict: dict containing User attributes
        :param table_name: DynamoDB table name
        """

        self.validate(user_dict)

        # Creating the car instance
        car_dict = user_dict.pop("car")
        self.car = Car(car_dict)

        for key, value in user_dict.items():
            setattr(self, key, value)

        self.dynamodb = boto3.resource("dynamodb")
        self.table = self.dynamodb.Table(os.getenv("TABLE"))

    def validate(cls, user_dict):
        """
        Validate user_dict against USER_SCHEMA.

        :param user_dict: dict to validate
        :raise: jsonschema.exceptions.ValidationError if validation fails
        """
        jsonschema.validate(user_dict, cls.USER_SCHEMA)

    def to_dict(self):
        """
        Convert the User instance to a dictionary.

        :return: dict representing the User instance
        """
        user_dict = vars(self).copy()
        user_dict["car"] = vars(self.car)
        user_dict.pop("dynamodb")
        user_dict.pop("table")
        return user_dict

    def save(self):
        """
        Save the User instance to the DynamoDB table.

        :return: boolean, operation success status
        """
        try:
            self.table.put_item(Item=self.to_dict())
        except BotoCoreError as e:
            print(f"Cannot connect to AWS: {e}")
            return False
        except ClientError as e:
            print(f"Unexpected error: {e}")
            return False
        return True
