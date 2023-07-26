#!/bin/bash 
DB_PORT=${DB_PORT:-5432}
DB_SYSTEM=${DB_SYSTEM:-postgres}
DOCKER_POSTGRES_NAME=${DOCKER_POSTGRES_NAME:-postgres}
DOCKER_POSTGRES_VERSION=${DOCKER_POSTGRES_VERSION:-15.3}

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
    --db-port)
    DB_PORT="$2"
    shift
    shift
    ;;
    --db-admin-pass)
    DB_SYSTEM="$2"
    shift
    shift
    ;;
    --docker-postgres-name)
    DOCKER_POSTGRES_NAME="$2"
    shift
    shift
    ;;
    --docker-postgres-version)
    DOCKER_POSTGRES_VERSION="$2"
    shift 
    shift
    ;;
    --help)
    echo "Usage: docker-postgres.sh [OPTION]"
    echo ""
    echo -e "  --docker-postgres-name <postgres container name>"
    echo -e "\tSet docker postgres container name (default is postgres)"
    echo -e "  --docker-postgres-version <postgres version>"
    echo -e "\tSet version of docker postgres image to install (default is 15.3)"
    echo -e "  --db-port <postgres server port>"
    echo -e "\tSet postgres server port (default is 5432)"
    echo -e "  --db-admin-pass <database server administrator password>"
    echo -e "\tSet database administrator password (default is postgres)"
    echo -e "  --help"
    echo -e "\tdisplay this help and exit"
    exit 0
    ;;
    --*)
    echo "Unknown option $1"
    exit 1
    ;;
    *)
    POSITIONAL_ARGS+=("$1") # save positional arg
    shift
    ;;
    esac
done

docker run -d --name $DOCKER_POSTGRES_NAME -p $DB_PORT:5432 -e POSTGRES_PASSWORD=$DB_SYSTEM postgres:$DOCKER_POSTGRES_VERSION
