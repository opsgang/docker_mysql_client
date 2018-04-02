#!/bin/bash
# vim: et sr sw=4 ts=4 smartindent:
#
# Tests for utility scripts provided with image.
#

RC=0
for i in 1 2 3 4; do docker rm -f t${i} 2>/dev/null ; done

echo "=== TEST 1 default entrypoint (help msg)"
docker run -i --rm --name t1 opsgang/aws_mysql_client:candidate || RC=1

echo "=== TEST 2 bespoke mysql cmd"
CMD="-u $DB_USER -p$DB_PASS -h $DB_HOST"
docker run -i --net bridge --rm --name t2 \
    opsgang/aws_mysql_client:candidate mysql -P 3306 --protocol=TCP $CMD -e 'show databases;' || RC=1

echo "=== TEST 3 /run_sql_from_file.sh"
docker run -i --rm --name t3 \
    --volumes-from $SHIPPABLE_CONTAINER_NAME \
    -e DB_HOST -e DB_PASS -e DB_USER \
    -e FILE=/fixtures/sql.example.gz \
    opsgang/aws_mysql_client:candidate /run_sql_from_file.sh || RC=1

mysql -e "USE example ; show tables;"

echo "=== TEST 4 /dump.sh to GZIPPED FILE"
export DUMP_OPTS="--opt --add-drop-database --databases example"
docker run -i --rm --name t3 \
    --volumes-from $SHIPPABLE_CONTAINER_NAME \
    -e DB_HOST -e DB_PASS -e DB_USER \
    -e GZIP=true -e DUMP_OPTS \
    -e DEST_PATH=/fixtures/example-test.sql.gz \
    opsgang/aws_mysql_client:candidate /dump.sh || RC=1

for i in 1 2 3 4; do docker rm -f t${i} 2>/dev/null ; done

exit $RC
