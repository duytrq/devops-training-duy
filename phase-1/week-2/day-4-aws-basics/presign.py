import argparse
import boto3


def generate_presigned_url(bucket: str, key: str, expires_in: int) -> str:
    s3_client = boto3.client("s3")

    return s3_client.generate_presigned_url(
        ClientMethod="get_object",
        Params={
            "Bucket": bucket,
            "Key": key,
        },
        ExpiresIn=expires_in,
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate an S3 presigned URL.")
    parser.add_argument("--bucket", required=True, help="S3 bucket name")
    parser.add_argument("--key", required=True, help="S3 object key")
    parser.add_argument("--expires-in", type=int, default=300, help="TTL in seconds")
    args = parser.parse_args()

    url = generate_presigned_url(args.bucket, args.key, args.expires_in)
    print(url)


if __name__ == "__main__":
    main()