# vim: et sr sw=4 ts=4 smartindent syntax=dockerfile:
FROM opsgang/aws_env:stable

LABEL \
      name="opsgang/aws_mysql_client"  \
      vendor="sortuniq"                \
      description="\
... adds mysql client and utility scripts;\n\
    to execute sql in a local file or S3.\n\
    or mysqldump to local storage or S3.\n\
    In all cases, files can be gzipped. \
"

COPY assets /assets

RUN cp -a assets/. /   \
    && chmod a+x /*.sh \
    && apk --no-cache --update add mysql-client \
    && rm -rf /var/cache/apk/* /assets 2>/dev/null

CMD ["bash", "-C", "/usage.sh"]
