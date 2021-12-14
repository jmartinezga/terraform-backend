# terraform-backend

Script to create a Terraform backend.

## Description

Terraform is an administrative tool that manages your infrastructure,
and so ideally the infrastructure that is used by Terraform should exist
outside of the infrastructure that Terraform manages.

So, this script provision S3 bucket for Terraform backend, which provides recommended settings.

- Enable Default Encryption
- Enable Versioning
- Enable Public Access Block

## Requirements

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html)

## Usage

```sh
sh terraform-backen.sh
```

## Input file

*config.json*
```json
{
  "account_id" : "365101756910",
  "region"     : "eu-west-1"
}
```

## License

Apache 2 Licensed. See LICENSE for full details.