DB_PORT=${DB_PORT:-5432}
DB_SYSTEM=${DB_SYSTEM:-postgres}
DOCKER_POSTGRES_NAME=${DOCKER_POSTGRES_NAME:-postgres}

for i in "$@"
do
    case $i in
    --db-port=*)
    DB_PORT="${i#*=}"
    shift # past argument=value
    ;;
    --db-admin-pass=*)
    DB_SYSTEM="${i#*=}"
    shift # past argument=value
    ;;
    --docker-postgres-name=*)
    DOCKER_POSTGRES_NAME="${i#*=}"
    shift # past argument=value
    ;;
    --help)
    echo "Usage: setup.sh [OPTION]"
    echo ""
    echo -e "  --docker-postgres-name=<postgres container name>"
    echo -e "\tSet docker postgres container name (default is postgres)"
    echo -e "  --db-port=<postgres server port>"
    echo -e "\tSet postgres server port (default is 5432)"
    echo -e "  --db-admin-pass=<database server administrator password>"
    echo -e "\tSet database administrator password (default is postgres)"
    echo -e "  --help"
    echo -e "\tdisplay this help and exit"
    exit 0
    ;;
    *)
	shift
	;;
    esac
done

docker run -d --name $DOCKER_POSTGRES_NAME -p $DB_PORT:5432 -e POSTGRES_PASSWORD=$DB_SYSTEM postgres:9.6
