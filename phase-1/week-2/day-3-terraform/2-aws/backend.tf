terraform {
  backend "s3" {
    bucket         = "tfstate-duy-f9c7c965"
    key            = "phase1/week2/day3.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "tfstate-lock"
    encrypt        = true
  }
}
