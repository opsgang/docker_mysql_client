#!/bin/bash
# vim: ts=4 sw=4 et sr smartindent:
#
# To run, set the following vars in your environment:
#
# $DB_HOST: location of remote DB
# $DB_PORT: listening mysql port
# $DB_USER: the user to connect as
# $DB_PASS: the user's pword.
# $FILE: s3:// uri or absolute path to local file
#

. /functions || exit 1
REQUIRED_VARS="
    DB_HOST
    DB_PASS
    DB_USER
    FILE
"
# ... validate required vars
required_vars "$REQUIRED_VARS" || exit 1

MYSQL_OPTS="--host=$DB_HOST --port=$DB_PORT --user=$DB_USER --password=$DB_PASS"
[[ ! -z "$DB_NAME" ]] && MYSQL_OPTS="$MYSQL_OPTS $DB_NAME"

# ... test can connect to specific db
i "... verifying can connect to $DB_HOST:$DB_PORT (db ${DB_NAME:-NOT PROVIDED}) with provided creds"
if ! mysql $MYSQL_OPTS -e 'select "1";'
then
    e "... couldn't connect to mysql host:port<$DB_HOST:$DB_PORT> (db ${DB_NAME:-NOT PROVIDED})"
    exit 1
fi

LFILE=$FILE
if [[ $FILE =~ ^s3:// ]]; then
    LFILE=/var/tmp/$(basename $FILE)
    ! aws s3 cp "$FILE" $LFILE && e "... couldn't download $FILE to $LFILE" && exit 1
else
    [[ ! -r $LFILE ]] && e "... can not read file $LFILE" && exit 1
fi

i "... checking if gzipped"
if gunzip -t $LFILE 2>/dev/null
then
    UNZFILE=/var/tmp/my.sql
    i "... gunzipping to /var/tmp/my.sql"
    ! gunzip -c $LFILE >$UNZFILE && e "... failed to gunzip $LFILE" && exit 1
    LFILE=$UNZFILE
fi

# ... run
i "... running sql file"
mysql $MYSQL_OPTS < $LFILE
