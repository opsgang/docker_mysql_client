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

t_bespoke_cmd() {
    local t="TEST 2" rc=0
    local cmd="" exp="" out=""
    echo "=== $t bespoke mysql cmd"
    exp="example information_schema mysql performance_schema sys"
    cmd="-u $DB_USER -p$DB_PASS -h $DB_HOST"
    out=$(
        set -o pipefail ;
        docker run -i --net bridge --rm --name t2 \
        opsgang/$IMG:candidate mysql $cmd -e 'show databases;' \
        | sort || exit 1
    ) || rc=1

    diff -wb <(echo $out) <(echo $exp) >/dev/null 2>&1 || rc=1

    if [[ $rc -ne 0 ]]; then
        echo "ERROR: $t failed."
        echo "ERROR: got: " $out
        echo "ERROR: exp: " $exp
        return 1
    fi

    return 0
}

t_run_gzip_file() {

    echo "=== TEST 3 /run_sql_from_file.sh (gzipped local)"
    docker run -i --rm --name t3 \
        --volumes-from $SHIPPABLE_CONTAINER_NAME \
        -e DB_HOST -e DB_PASS -e DB_USER \
        -e FILE=/fixtures/example.sql.gz \
        opsgang/aws_mysql_client:candidate /run_sql_from_file.sh || rc=1

    out=$(mysql -e 'use example; select count(*) AS foo from offices \G ')
    echo "-->>$out<--"

    rc=1
    if [[ $rc -ne 0 ]]; then
        echo "ERROR: $t failed."
        echo "ERROR: got: " $out
        echo "ERROR: exp: foo --- 0" 
        return 1
    fi

    return 0
}

setup_db || exit 1

RC=0

dc

# TEST 2
# Container usage msg
echo "=== TEST 1 default entrypoint (help msg)"
docker run -i --rm --name t1 opsgang/aws_mysql_client:candidate || RC=1

# TEST 2
# Bespoke cmd: list databases as $OUT, and compare $OUT to $EXP
t_bespoke_cmd || RC=1

# TEST 3
# Load from file. Check offices table has expected col.
t_run_gzip_file || RC=1

# TEST 4
# Load from file. Check offices table has expected col.
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

echo "=== TEST 6 /run_sql_from_file.sh (gzipped s3)"
docker run -i --rm --name t3 \
    --volumes-from $SHIPPABLE_CONTAINER_NAME \
    -e TEST_STUBS=true \
    -e DB_HOST -e DB_PASS -e DB_USER \
    -e FILE=s3://foo/bar/example.sql.gz \
    opsgang/aws_mysql_client:candidate /run_sql_from_file.sh || RC=1

dc

exit $RC
