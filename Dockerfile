FROM openjdk:8-jre-alpine

RUN apk add --no-cache --quiet \
    bash \
    curl \
    openssl

ENV NEO4J_SHA256=65e1de8a025eae4ba42ad3947b7ecbf758a11cf41f266e8e47a83cd93c1d83d2 \
    NEO4J_TARBALL=neo4j-community-3.2.3-unix.tar.gz
ARG NEO4J_URI=http://dist.neo4j.org/neo4j-community-3.2.3-unix.tar.gz

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


RUN wget https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases/download/3.2.0.4/apoc-3.2.0.4-all.jar -P  ./plugins
ENV NEO4J_dbms_security_procedures_unrestricted=apoc.warmup.\\\*


ENV NEO4J_AUTH=none
ENV NEO4J_dbms_logs_http_enabled=true


EXPOSE 7474 7473 7687

COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["neo4j"]
