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
# $DEST_PATH: s3:// destination uri for dumpfile - must include filename
# $GZIP: - set with any value to gzip the file before storing to file system
#
. /functions || exit 1
dump
