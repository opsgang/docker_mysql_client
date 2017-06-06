#!/bin/bash
# vim: ts=4 sw=4 et sr smartindent:
#
# To run, set the following vars in your environment:
#
# $DB_HOST: location of remote DB
# $DB_PORT: listening mysql port
# $DB_USER: the user to connect as
# $DB_PASS: the user's pword.
# $DUMP_OPTS: - passed to container
# $GZIP: - set with any value to gzip the file before shipping to S3
# $S3_FILE: s3:// destination uri for dumpfile - must include filename
#
. /functions || exit 1

REQUIRED_VARS="
    DB_HOST
    DB_PASS
    DB_USER
    S3_FILE
"
# ... validate required vars
required_vars "$REQUIRED_VARS" || exit 1

MYSQL_OPTS="--host=$DB_HOST --port=$DB_PORT --user=$DB_USER --password=$DB_PASS"

# ... test can connect to specific db
i "... verifying can connect to $DB_HOST:$DB_PORT with provided creds"
if ! mysql $MYSQL_OPTS -e 'select "1";'
then
    e "... couldn't connect to mysql host:port<$DB_HOST:$DB_PORT>"
    exit 1
fi

LFILE=/var/tmp/$(basename $S3_FILE)

rc=0
if [[ -z "$GZIP" ]]; then
    i "... dumping to file"
    mysqldump $MYSQL_OPTS $DUMP_OPTS --result-file=$LFILE || rc=1
else
    i "... dumping to file, gzipped"
    set -o pipefail
    mysqldump $MYSQL_OPTS $DUMP_OPTS | gzip -c >$LFILE || rc=1
fi
[[ $rc -ne 0 ]] && e "... failed to dump $DB_HOST to file" && exit 1

i "... uploading file to s3"
! aws s3 cp $LFILE $S3_FILE && e "... couldn't upload $LFILE to $S3_FILE" && exit 1

exit 0

