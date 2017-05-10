[1]: https://github.com/opsgang/docker_aws_env "github repo for aws_env docker image"
# docker\_aws\_mysql\_client

... opsgang/aws\_env with mysql client - default CMD will execute a file of sql (optionally gzipped)

**Execute arbitrary SQL or run an optionally-gzipped file of sql commands stored on the host or in S3.**

See [opsgang/aws\_env][1] for other functionality available in this container.

## BUILDING

**master branch built at shippable.com**

[![Run Status](https://api.shippable.com/projects/590c212289d0490700d769bc/badge?branch=master)](https://app.shippable.com/github/opsgang/docker_aws_mysql_client)

# EXAMPLES

**Most examples below use /run\_sql\_from\_file.sh as the helper script to run.**
**Run container's default entrypoint to see about other available helper scripts**
**... or look in [the assets dir in github](assets)**

```bash

# ... run arbitary sql query

CMD="mysql -h host.example.com --port 1234 -u bob -p$(cat db_password.txt) my_db"
QUERY="select 1;"
docker run -t --rm opsgang/aws_mysql_client:stable $CMD -e "$QUERY"

```

```bash
# ... sql script stored in s3, using host's IAM - file can be gzipped or not.
export FILE=s3://some-bucket/path/to/sql #

export DB_HOST="localhost" DB_USER="bob" DB_PASS="$(cat secret.txt)" # change values as needed

docker run -t --rm \
    --env DB_HOST --env DB_USER --env DB_PASS --env FILE \
    opsgang/aws_mysql_client:stable /bin/bash -c /run_sql_from_file.sh
```

```bash
# ... sql script in S3, passing AWS creds - file can be gzipped or not
export file=s3://some-bucket/path/to/sql #

export DB_HOST="localhost" DB_USER="bob" DB_PASS="$(cat secret.txt)" # change values as needed
export AWS_DEFAULT_REGION AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY # these should be defined already

docker run -t --rm \
    --env DB_HOST --env DB_USER --env DB_PASS --env FILE \
    --env AWS_DEFAULT_REGION --env AWS_ACCESS_KEY_ID --env AWS_SECRET_ACCESS_KEY \
    opsgang/aws_mysql_client:stable /bin/bash -c /run_sql_from_file.sh

```

```bash

# ... sql script on container's host at /path/to/sqlfile - file can be gzipped or not.
# (we will mount it on the container at /sqlfile)
export FILE=/sqlfile

export DB_HOST="localhost" DB_USER="bob" DB_PASS="$(cat secret.txt)" # change values as needed

docker run -t --rm \
    -v /path/to/sqlfile:/sqlfile \
    --env DB_HOST --env DB_USER --env DB_PASS --env FILE \
    opsgang/aws_mysql_client:stable /bin/bash -c /run_sql_from_file.sh


```

