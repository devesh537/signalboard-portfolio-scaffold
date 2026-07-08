bucket         = "signalboard-tfstate-<your-account-id>"
key            = "dev/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "signalboard-tf-locks"
encrypt        = true
