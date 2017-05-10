# vim: et sr sw=4 ts=4 smartindent syntax=dockerfile:
FROM opsgang/aws_env:stable

MAINTAINER jinal--shah <jnshah@gmail.com>
LABEL \
      name="opsgang/aws_mysql_client"  \
      vendor="sortuniq"                \
      description="\
... adds mysql client;\n\
... includes default script to execute \
sql from a file (can be gzipped) from S3 \
or container file system (e.g. mounted)\
"

COPY assets /assets

RUN cp -a assets/. /   \
    && chmod a+x /*.sh \
    && apk --no-cache --update add mysql-client \
    && rm -rf /var/cache/apk/* /assets 2>/dev/null

CMD ["bash", "-C", "/usage.sh"]
