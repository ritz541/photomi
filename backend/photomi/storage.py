import boto3
import os
import logging
from botocore.config import Config
from typing import BinaryIO

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class R2Storage:
    def __init__(self):
        # Get credentials from environment variables
        self.account_id = os.getenv("R2_ACCOUNT_ID")
        self.access_key = os.getenv("ACCESS_KEY")
        self.secret_key = os.getenv("SECRET_KEY")
        self.bucket_name = os.getenv("BUCKET_NAME")

        if not all([self.account_id, self.access_key, self.secret_key, self.bucket_name]):
            raise ValueError(
                "Missing required environment variables for R2 configuration")

        # Create R2 client
        self.s3_client = boto3.client(
            's3',
            endpoint_url=f'https://{self.account_id}.r2.cloudflarestorage.com',
            aws_access_key_id=self.access_key,
            aws_secret_access_key=self.secret_key,
            config=Config(
                region_name='auto',
                s3={
                    'addressing_style': 'virtual'
                }
            )
        )

    def upload_file(self, file_obj: BinaryIO, filename: str) -> bool:
        """
        Upload a file to R2 storage

        Args:
            file_obj: File object to upload
            filename: Name to store the file as

        Returns:
            bool: True if successful, False otherwise
        """
        try:
            self.s3_client.upload_fileobj(file_obj, self.bucket_name, filename)
            logger.info(f"Successfully uploaded file: {filename}")
            return True
        except Exception as e:
            logger.error(f"Error uploading file {filename}: {e}")
            return False

    def get_presigned_url(self, filename: str, expiration: int = 3600) -> str:
        """
        Generate a presigned URL for accessing a file

        Args:
            filename: Name of the file to generate URL for
            expiration: Time in seconds for URL to be valid (default 1 hour)

        Returns:
            str: Presigned URL
        """
        try:
            url = self.s3_client.generate_presigned_url(
                'get_object',
                Params={'Bucket': self.bucket_name, 'Key': filename},
                ExpiresIn=expiration
            )
            logger.debug(f"Generated presigned URL for file: {filename}")
            return url
        except Exception as e:
            logger.error(f"Error generating presigned URL for {filename}: {e}")
            return ""
