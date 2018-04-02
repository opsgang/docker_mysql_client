#!/bin/bash
# vim: et sr sw=4 ts=4 smartindent:
#
# Tests for utility scripts provided with image.
#

# container should print usage info when no args.
docker rm -f t1 2>/dev/null || true
docker rm -f def_out 2>/dev/null || true

echo "running default output"
docker run -i --rm --name def_out opsgang/aws_mysql_client:candidate || exit 1

echo "running show databases"

CMD="-u $DB_USER -p$DB_PASS -h $DB_HOST"
docker run -i --net bridge --rm --name t1 \
    opsgang/aws_mysql_client:candidate mysql -P 3306 --protocol=TCP $CMD -e 'show databases;' || exit 1

docker rm -f t1 2>/dev/null || true

echo "dir:$PWD/t/fixtures"
ls -l $PWD/t/fixtures
docker run -i --rm --name t2 \
    -v $PWD/t/fixtures:/fixtures \
    -e DB_HOST -e DB_PASS -e DB_USER \
    -e FILE=/fixtures/sql.example.gz \
    opsgang/aws_mysql_client:candidate /bin/bash -c "ls -l /fixtures"
