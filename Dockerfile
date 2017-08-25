FROM openjdk:8-jre-alpine

RUN apk add --no-cache --quiet \
    bash \
    curl \
    openssl

ENV NEO4J_SHA256=7d90638e65798ef057f32742fb4f8c87d4d2f13d7c06d7a4c093320bd4df3191 \
    NEO4J_TARBALL=neo4j-enterprise-3.2.1-unix.tar.gz
ARG NEO4J_URI=http://dist.neo4j.org/neo4j-enterprise-3.2.1-unix.tar.gz

COPY ./local-package/* /tmp/

RUN curl --fail --silent --show-error --location --remote-name ${NEO4J_URI} \
    && echo "${NEO4J_SHA256}  ${NEO4J_TARBALL}" | sha256sum -csw - \
    && tar --extract --file ${NEO4J_TARBALL} --directory /var/lib \
    && mv /var/lib/neo4j-* /var/lib/neo4j \
    && rm ${NEO4J_TARBALL} \
    && mv /var/lib/neo4j/data /data \
    && ln -s /data /var/lib/neo4j/data   


WORKDIR /var/lib/neo4j
VOLUME /data

# Disable security
ENV NEO4J_AUTH=none

# APOC procedure for warmup
RUN wget https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases/download/3.2.0.4/apoc-3.2.0.4-all.jar -P  ./plugins
ENV NEO4J_dbms_security_procedures_unrestricted=apoc.warmup.\\\*

# Db upgrades & backups
ENV NEO4J_dbms_allow__format__migration=true
ENV NEO4J_dbms_backup_enabled=true
ENV NEO4J_dbms_backup_address=0.0.0.0:6362
ENV NEO4J_dbms_connectors_default__listen__address=0.0.0.0

# HTTP logging
ENV NEO4J_dbms_logs_http_enabled=true
# Query logging
ENV NEO4J_dbms_logs_query_enabled=true
ENV NEO4J_dbms_logs_query_threshold=10
ENV NEO4J_dbms_logs_query_time__logging__enabled=true
ENV NEO4J_dbms_logs_query_page__logging__enabled=true


EXPOSE 7474 7473 7687

COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["neo4j"]
