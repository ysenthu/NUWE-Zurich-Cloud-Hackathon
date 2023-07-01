import jsonschema


class Car:
    """
    A class representing a Car with attributes
    """

    CAR_SCHEMA = {
        "type": "object",
        "properties": {
            "make": {"type": "string"},
            "model": {"type": "string"},
            "year": {"type": "integer"},
            "color": {"type": "string"},
            "plate": {"type": "string"},
            "mileage": {"type": "integer"},
            "fuelType": {"type": "string"},
            "transmission": {"type": "string"},
        },
        "required": [
            "make",
            "model",
            "year",
            "color",
            "plate",
            "mileage",
            "fuelType",
            "transmission",
        ],
    }

    def __init__(self, car_dict):
        """
        Initialize Car instance with attributes from dictionary.

        :param car_dict: dict containing Car attributes
        """
        self.validate(car_dict)

        for key, value in car_dict.items():
            setattr(self, key, value)

    @classmethod
    def validate(cls, car_dict):
        """
        Validate car_dict against CAR_SCHEMA.

        :param car_dict: dict to validate
        :raise: jsonschema.exceptions.ValidationError if validation fails
        """
        jsonschema.validate(car_dict, cls.CAR_SCHEMA)
