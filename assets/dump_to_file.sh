#!/bin/bash
# vim: ts=4 sw=4 et sr smartindent:
#
# mysqldump to local file
#
# You are expected to mount a host volume so this file is available
# for later actions.
#
# To run, set the following vars in your environment:
#
# $DB_HOST: location of remote DB
# $DB_PORT: listening mysql port
# $DB_USER: the user to connect as
# $DB_PASS: the user's pword.
# $DUMP_OPTS: - passed to container
# $LFILE: s3:// destination uri for dumpfile - must include filename
# $GZIP: - set with any value to gzip the file before storing to file system
#
. /functions || exit 1

REQUIRED_VARS="
    DB_HOST
    DB_PASS
    DB_USER
    LFILE
"
# ... validate required vars
required_vars "$REQUIRED_VARS" || exit 1

if [[ -z "$DUMP_OPTS" ]]; then
    DUMP_OPTS="--opt --add-drop-database --all-databases"
    i "... will dump all databases."
    i "DUMP_OPTS: $DUMP_OPTS"
fi

LFILE="$(realpath -- $LFILE)"
LDIR="$(dirname $LFILE)"
if [[ ! -d "$LDIR" ]]; then
    e "... dir in container ($LDIR) for $LFILE does not exist."
    e "... are you sure you mounted a vol from your host?"
    exit 1
fi

MYSQL_OPTS="--host=$DB_HOST --port=$DB_PORT --user=$DB_USER --password=$DB_PASS"

# ... test can connect to specific db
i "... verifying can connect to $DB_HOST:$DB_PORT with provided creds"
if ! mysql $MYSQL_OPTS -e 'select "1";'
then
    e "... couldn't connect to mysql host:port<$DB_HOST:$DB_PORT>"
    exit 1
fi

rc=0
if [[ -z "$GZIP" ]]; then
    i "... dumping to file"
    mysqldump $MYSQL_OPTS $DUMP_OPTS --result-file=$LFILE || rc=1
else
    i "... dumping to file, gzipped"
    set -o pipefail
    mysqldump $MYSQL_OPTS $DUMP_OPTS | gzip -c >$LFILE || rc=1
fi
[[ $rc -ne 0 ]] && e "... failed to dump $DB_HOST to file $LFILE" && exit 1

exit 0

