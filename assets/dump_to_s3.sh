#!/bin/bash
# vim: ts=4 sw=4 et sr smartindent:
#
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

yellow_i "This script has been superseded by /dump.sh which"
yellow_i "handles dumping to the local filesystem or an s3 url."
yellow_i ""
yellow_i "It is retained to maintain backwards-compatibility for"
yellow_i "users who are setting \$S3_FILE as opposed to \$DEST_PATH"
yellow_i ""
yellow_i "You are recommended to move to /dump.sh instead, and export"
yellow_i "\$DEST_PATH instead of \$S3_FILE."
yellow_i ""
yellow_i "This compatibility script will be removed in the next major release."

# ... for backwards compatibility
if [[ ! -z "$S3_FILE" ]]; then
    export DEST_PATH="$S3_FILE"
fi

dump
