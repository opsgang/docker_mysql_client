#!/bin/bash
# vim: et sr sw=4 ts=4 smartindent:
#
# Tests for utility scripts provided with image.
#

# container should print usage info when no args.
docker rm -f t1 2>/dev/null || true
docker rm -f def_out 2>/dev/null || true

echo "running default output"
docker run -i --rm --name def_out opsgang/aws_mysql_client:candidate

echo "running show databases"
docker run -i --rm --name t1 \
    opsgang/aws_mysql_client:candidate mysql -P 3306 --protocol=TCP -u t -pPword666 -h localhost -e 'show databases;'

docker rm -f t1 2>/dev/null || true

#docker run -i --rm --name t2 \
#    -v $PWD/t/fixtures:/fixtures \
#    -e DB_HOST -e DB_PASS -e DB_USER \
#    -e FILE=/fixtures/sql.example.gz \
#    opsgang/aws_mysql_client:candidate /run_sql_from_file.sh
