#!/bin/bash -meu

if [ "$1" == "neo4j" ]; then

    # Env variable naming convention:
    # - prefix NEO4J_
    # - double underscore char '__' instead of single underscore '_' char in the setting name
    # - underscore char '_' instead of dot '.' char in the setting name
    # Example:
    # NEO4J_dbms_tx__log_rotation_retention__policy env variable to set
    #       dbms.tx_log.rotation.retention_policy setting

    # Backward compatibility - map old hardcoded env variables into new naming convention (if they aren't set already)
    # Set some to default values if unset
    : ${NEO4J_dbms_connectors_default__listen__address:="0.0.0.0"}
    : ${NEO4J_dbms_connector_http_listen__address:="0.0.0.0:7474"}
    : ${NEO4J_dbms_connector_https_listen__address:="0.0.0.0:7473"}
    : ${NEO4J_dbms_connector_bolt_listen__address:="0.0.0.0:7687"}
    : ${NEO4J_ha_host_coordination:="$(hostname):5001"}
    : ${NEO4J_ha_host_data:="$(hostname):6001"}

    if [ -d /conf ]; then
        find /conf -type f -exec cp {} conf \;
    fi

    if [ -d /ssl ]; then
        NEO4J_dbms_directories_certificates="/ssl"
    fi

    if [ -d /plugins ]; then
        NEO4J_dbms_directories_plugins="/plugins"
    fi

    if [ -d /logs ]; then
        NEO4J_dbms_directories_logs="/logs"
    fi

    if [ -d /import ]; then
        NEO4J_dbms_directories_import="/import"
    fi

    if [ -d /metrics ]; then
        NEO4J_dbms_directories_metrics="/metrics"
    fi

    if [ "${NEO4J_AUTH:-}" == "none" ]; then
        NEO4J_dbms_security_auth__enabled=false
    elif [[ "${NEO4J_AUTH:-}" == neo4j/* ]]; then
        password="${-#neo4j/}"
        if [ "${password}" == "neo4j" ]; then
            echo "Invalid value for password. It cannot be 'neo4j', which is the default."
            exit 1
        fi
        # Will exit with error if users already exist (and print a message explaining that)
        bin/neo4j-admin set-initial-password "${password}" || true
    elif [ -n "${NEO4J_AUTH:-}" ]; then
        echo "Invalid value for NEO4J_AUTH: '${NEO4J_AUTH}'"
        exit 1
    fi

    # list env variables with prefix NEO4J_ and create settings from them
    unset NEO4J_AUTH NEO4J_SHA256 NEO4J_TARBALL
    for i in $( set | grep ^NEO4J_ | awk -F'=' '{print $1}' | sort -rn ); do
        setting=$(echo ${i} | sed 's|^NEO4J_||' | sed 's|_|.|g' | sed 's|\.\.|_|g')
        value=$(echo ${!i})
        if [[ -n ${value} ]]; then
            if grep -q -F "${setting}=" conf/neo4j.conf; then
                # Remove any lines containing the setting already
                sed --in-place "/${setting}=.*/d" conf/neo4j.conf
            fi
            # Then always append setting to file
            echo "${setting}=${value}" >> conf/neo4j.conf
        fi
    done

    [ -f "${EXTENSION_SCRIPT:-}" ] && . ${EXTENSION_SCRIPT}

    ## Now begins the actual Execution
    exec bin/neo4j console &
    while ! curl -s -I http://localhost:7474 | grep -q "200 OK"; do
        echo 'Waiting for DB to come up...'
        sleep 20
    done
    echo 'Made Warm Up call. Wait 3-4 minutes--------------------------------------------------'
    bin/cypher-shell 'CALL apoc.warmup.run();'
    fg %1
    echo ''
    echo 'Warmed Up & Ready!'

elif [ "$1" == "dump-config" ]; then
    if [ -d /conf ]; then
        cp --recursive conf/* /conf
    else
        echo "You must provide a /conf volume"
        exit 1
    fi
else
    exec "$@"
fi
