#!/bin/bash
# vim: et sr sw=4 ts=4 smartindent:
#
# Tests for utility scripts provided with image.
#

setup_db() {
    export DB_HOST=172.17.0.3 DB_PASS=Pword666 DB_USER=tester
    mysql -e "CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';" || return 1
    mysql -e "GRANT ALL ON *.* TO '${DB_USER}'@'%'; FLUSH PRIVILEGES;" || return 1
    mysql -e "CREATE DATABASE example;" || return 1
    return 0
}

dc() {
    for i in 1 2 3 4 5; do
        docker rm -f t${i} 2>/dev/null
    done
}

setup_db || exit 1

RC=0

dc

echo "=== TEST 1 default entrypoint (help msg)"
docker run -i --rm --name t1 opsgang/aws_mysql_client:candidate || RC=1

echo "=== TEST 2 bespoke mysql cmd"
CMD="-u $DB_USER -p$DB_PASS -h $DB_HOST"
o=$(
    docker run -i --net bridge --rm --name t2 \
    opsgang/$IMG:candidate mysql $CMD -e 'show databases;' || exit 1
) || rc=1

echo "=== TEST 3 /run_sql_from_file.sh (gzipped local)"
docker run -i --rm --name t3 \
    --volumes-from $SHIPPABLE_CONTAINER_NAME \
    -e DB_HOST -e DB_PASS -e DB_USER \
    -e FILE=/fixtures/sql.example.gz \
    opsgang/aws_mysql_client:candidate /run_sql_from_file.sh || RC=1

mysql -e "USE example ; show tables;"

echo "=== TEST 4 /dump.sh to GZIPPED FILE"
export DUMP_OPTS="--opt --add-drop-database --databases example"
docker run -i --rm --name t4 \
    --volumes-from $SHIPPABLE_CONTAINER_NAME \
    -e DB_HOST -e DB_PASS -e DB_USER \
    -e GZIP=true -e DUMP_OPTS \
    -e DEST_PATH=/fixtures/example-test.sql.gz \
    opsgang/aws_mysql_client:candidate /dump.sh || RC=1

echo "=== TEST 5 /dump.sh to S3"
export DUMP_OPTS="--opt --add-drop-database --databases example"
docker run -i --rm --name t5 \
    --volumes-from $SHIPPABLE_CONTAINER_NAME \
    -e TEST_STUBS=true \
    -e DB_HOST -e DB_PASS -e DB_USER \
    -e GZIP=true -e DUMP_OPTS \
    -e DEST_PATH=s3://foo/bar/example.sql.gz \
    opsgang/aws_mysql_client:candidate /dump.sh || RC=1

dc

exit $RC
