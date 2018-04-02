#!/bin/bash
# vim: et sr sw=4 ts=4 smartindent:
#
# Tests for utility scripts provided with image.
#

# container should print usage info when no args.
default_cmd() {
    export
}

default_cmd

echo "candidate images:"
docker images | grep candidate

docker run -t --rm --name t1 \
    opsgang/aws_mysql_client:candidate /bin/bash -c "mysql -u t -p Pword666 -h localhost -e 'show databases;'"

docker rm -f t1 2>/dev/null || true
