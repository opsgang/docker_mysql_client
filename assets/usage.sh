#!/bin/bash
# vim: ts=4 sw=4 et sr smartindent:
#
# prints usage info from each available entrypoint
#
. /functions
bold_i "... see https://github.com/opsgang/docker_aws_mysql_client README for more info."
bold_i "docker run [ ... docker opts ] $THIS_IMAGE_NAME <... entrypoint>\n"

bold_i "RUN ARBITRARY SQL ..."
cat << EOF

    # e.g. ... run a select against my_db
    MYSQL_CONN="mysql -h host.example.com --port 1234 -u bob -p\${MY_PASSWORD}"
    QUERY="select count(id) from my_table;"
    docker run -t --rm $THIS_IMAGE_NAME \$MYSQL_CONN my_db -e "\$QUERY"

EOF

bold_i "... OR USE ENTRYPOINT SCRIPTS\n"

s=/run_sql_from_file.sh
ep="/bin/bash -c $s"
yellow_i "--- $s\n"
i "... run sql from file (optionally gzipped)."
i "    The file can be in S3, or available to container e.g. via a volume or docker copy"
cat << EOF

    # e.g. ... sql script stored in s3, using host's IAM. File can be gzipped or not.
    export FILE=s3://some-bucket/path/to/file.sql.gz
    export DB_HOST="localhost" DB_USER="bob" DB_PASS="\${MY_PASSWORD}"
    docker run -t --rm \\
        --env DB_HOST --env DB_USER --env DB_PASS --env FILE \\
            $THIS_IMAGE_NAME $ep

EOF

s=/dump_to_s3.sh
ep="/bin/bash -c $s"
yellow_i "--- $s\n"
i "... mysqldump and send result to an S3 location, optionally gzipped"
i "    The file can be in S3, or available to container e.g. via a volume or docker copy"
cat << EOF

    # e.g. ... dump my_db with some mysqldump options, and ship gzipped to S3. 
    export S3_FILE=s3://some-bucket/path/to/my.sql.gz
    export DB_HOST="localhost" DB_USER="bob" DB_PASS="\${MY_PASSWORD}"
    export GZIP=true
    export DUMP_OPTS="--opt --add-drop-database --databases my_db"
    docker run -t --rm \\
        --env DB_HOST --env DB_USER --env DB_PASS --env S3_FILE --env DUMP_OPTS \\
            $THIS_IMAGE_NAME $ep

EOF

s=/dump_to_file.sh
ep="/bin/bash -c $s"
yellow_i "--- $s\n"
i "... mysqldump to a local file, optionally gzipped"
i "    Mount a host volume to the container so you can use the local file after."
cat << EOF

    # e.g. ... dump my_db with some mysqldump options, to host path /my/dir/dump.sql.gz
    # Here we mount /my/dir to /project in container.
    #
    export LFILE=/project/dump.sql.gz # output path INSIDE container.
    export DB_HOST="localhost" DB_USER="bob" DB_PASS="\${MY_PASSWORD}"
    export GZIP=true
    export DUMP_OPTS="--opt --add-drop-database --databases my_db"
    # DUMP_OPTS defaults to "--opt --add-drop-database --all-databases"
    docker run -t --rm \\
        -v /my/dir:/project \\
        --env DB_HOST --env DB_USER --env DB_PASS --env LFILE --env DUMP_OPTS \\
            $THIS_IMAGE_NAME $ep

EOF

bold_i "... OR USE YOUR OWN SCRIPT"
cat << EOF

    # e.g. mount script.py (that needs vars SOME_VAR and OTHER_VAR)
    docker run -t --rm \\
        -v /path/to/my/script.py:/my_script.py:ro \\
        --env SOME_VAR --env OTHER_VAR \\
            $THIS_IMAGE_NAME /bin/python /my_script.py

EOF

cat << EOF

        Container also includes toolset from opsgang/aws_env e.g. awscli, python, credstash
        ... see https://github.com/opsgang/docker_aws_env for more info

EOF
