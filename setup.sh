CREATE_DOCKER_POSTGRES=false
DOCKER_POSTGRES_NAME=${DOCKER_POSTGRES_NAME:-postgres}
LOAD_IDEMPIERE_ENV=false
SETUP_DB=true
CLONE_BRANCH=false
SOURCE_URL=https://github.com/idempiere/idempiere.git
IDEMPIERE_SOURCE_FOLDER=${IDEMPIERE_SOURCE_FOLDER:-idempiere}
IDEMPIERE_HOST=${IDEMPIERE_HOST:-0.0.0.0}
IDEMPIERE_PORT=${IDEMPIERE_PORT:-8080}
IDEMPIERE_SSL_PORT=${IDEMPIERE_SSL_PORT:-8443}
DB_NAME=${DB_NAME:-idempiere}
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}
DB_USER=${DB_USER:-adempiere}
DB_PASS=${DB_PASS:-adempiere}
DB_SYSTEM=${DB_SYSTEM:-postgres}
ECLIPSE=${ECLIPSE:-eclipse}
MIGRATE_EXISTING_DATABASE=${MIGRATE_EXISTING_DATABASE:-true}

for i in "$@"
do
    case $i in
    --help)
    echo "Usage: setup.sh [OPTION]"
    echo ""
    echo -e "  --create-docker-postgres"
    echo -e "\tCreate and run docker postgres 9.6 container"
    echo -e "  --docker-postgres-name=<postgres container name>"
    echo -e "\tSet docker postgres container name (default is postgres)"
    echo -e "  --db-name=<idempiere database name>"
    echo -e "\tSet idempiere database name (default is idempiere)"
    echo -e "  --db-host=<database server host name>"
    echo -e "\tSet idempiere database server host name (default is localhost)"
    echo -e "  --db-port=<idempiere database server port>"
    echo -e "\tSet idempiere database server port (default is 5432)"
    echo -e "  --db-user=<idempiere database user name>"
    echo -e "\tSet idempiere database user name (default is adempiere)"
    echo -e "  --db-pass=<idempiere database user password>"
    echo -e "\tSet idempiere database user password (default is adempiere)"
    echo -e "  --db-admin-pass=<database server administrator password>"
    echo -e "\tSet database administrator password (default is postgres)"
    echo -e "  --http-host=<host ip>"
    echo -e "\tSet http address/ip to listen to (default is 0.0.0.0, i.e all available address)"
    echo -e "  --http-port=<http port>"
    echo -e "\tSet http port to listen to (default is 8080)"
    echo -e "  --https-port=<http port>"
    echo -e "\tSet https/ssl port to listen to (default is 8443)"
    echo -e "  --load-idempiere-env"
    echo -e "\tLoad environment variable values from idempiereEnv.properties (if exists)"
    echo -e "  --eclipse=<eclipse ide folder>"
    echo -e "\tSet eclipse ide folder (default is eclipse)"
    echo -e "  --source=<idempiere source folder>"
    echo -e "\tSet idempiere source folder (default is idempiere)"
    echo -e "  --skip-setup-db"
    echo -e "\tDo not create/sync idempiere db, setup connection properties (idempiere.properties) and setup jetty server (jettyhome)"
    echo -e "  --branch=<branch name>"
    echo -e "\tCheckout branch instead of master"
    echo -e "  --repository-url=<git repository url>"
    echo -e "\tSet git repository URL to clone source from (default is $SOURCE_URL)"
    echo -e "  --skip-migration-script"
    echo -e "\tDo not run migration scripts against existing db (default will run)"
    echo -e "  --help"
    echo -e "\tdisplay this help and exit"
    exit 0
    ;;
	--create-docker-postgres) 
	CREATE_DOCKER_POSTGRES=true
	shift
	;;
	--docker-postgres-name=*)
    DOCKER_POSTGRES_NAME="${i#*=}"
    shift # past argument=value
    ;;
	--db-name=*)
    DB_NAME="${i#*=}"
    shift # past argument=value
    ;;
    --db-host=*)
    DB_HOST="${i#*=}"
    shift # past argument=value
    ;;
    --db-port=*)
    DB_PORT="${i#*=}"
    shift # past argument=value
    ;;
    --db-user=*)
    DB_USER="${i#*=}"
    shift # past argument=value
    ;;
    --db-pass=*)
    DB_PASS="${i#*=}"
    shift # past argument=value
    ;;
    --db-admin-pass=*)
    DB_SYSTEM="${i#*=}"
    shift # past argument=value
    ;;    
    --http-host=*)
    IDEMPIERE_HOST="${i#*=}"
    shift # past argument=value
    ;;
    --http-port=*)
    IDEMPIERE_PORT="${i#*=}"
    shift # past argument=value
    ;;
    --https-port=*)
    IDEMPIERE_SSL_PORT="${i#*=}"
    shift # past argument=value
    ;;
	--load-idempiere-env) 
	LOAD_IDEMPIERE_ENV=true
	shift
	;;
	--eclipse=*)
    ECLIPSE="${i#*=}"
    shift # past argument=value
    ;;
    --source=*)
    IDEMPIERE_SOURCE_FOLDER="${i#*=}"
    shift # past argument=value
    ;;
	--skip-setup-db) 
	SETUP_DB=false
	shift
	;;
	--branch=*) 
	CLONE_BRANCH=true
        BRANCH_NAME="${i#*=}"
	shift
	;;
	--skip-migration-script)
    MIGRATE_EXISTING_DATABASE=false
    shift
    ;;
        --repository-url=*)
        SOURCE_URL="${i#*=}"
        shift
        ;;
	*)
	shift
	;;
    esac
done

if [ -z "$JAVA_HOME" ]; then
	echo -e "Please set the JAVA_HOME environment variable pointing to a JDK 11 installation folder"
	echo -e "For e.g, export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64"
	exit 0
fi

if [ ! -f $JAVA_HOME/bin/java ]; then
	echo -e "Please set the JAVA_HOME environment variable pointing to a JDK 11 installation folder"
	echo -e "For e.g, export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64"
	exit 0
fi

JAVA_MAJOR_VERSION=$($JAVA_HOME/bin/java -version 2>&1 | sed -E -n 's/.* version "([^.-]*).*"/\1/p' | cut -d' ' -f1)

if [ "$JAVA_MAJOR_VERSION" != "11" ]; then
	echo -e "Please set the JAVA_HOME environment variable pointing to a JDK 11 installation folder"
	echo -e "For e.g, export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64"
	exit 0
fi

if [ ! -d $IDEMPIERE_SOURCE_FOLDER ]; then
	echo
	echo "*** Clone iDempiere ***"
	echo
	if [ "$CLONE_BRANCH" = true ] ; then
		git clone --branch $BRANCH_NAME $SOURCE_URL $IDEMPIERE_SOURCE_FOLDER
	else
		git clone $SOURCE_URL $IDEMPIERE_SOURCE_FOLDER
	fi	
else
	git -C $IDEMPIERE_SOURCE_FOLDER pull
fi
if [ ! -f apache-groovy-binary-3.0.7.zip ]; then
	echo
	echo "*** Download groovy ***"
	echo
	wget https://archive.apache.org/dist/groovy/3.0.7/distribution/apache-groovy-binary-3.0.7.zip
	unzip apache-groovy-binary-3.0.7.zip
fi
if [ ! -d "groovy-3.0.7" ]; then
	echo
	echo "*** Extract Groovy ***"
	echo
	unzip apache-groovy-binary-3.0.7.zip
fi
if [ ! -f eclipse-jee-2022-03-R-linux-gtk-x86_64.tar.gz ]; then
	echo
	echo "*** Download Eclipse ***"
	echo
    wget https://download.eclipse.org/technology/epp/downloads/release/2022-09/R/eclipse-jee-2022-09-R-linux-gtk-x86_64.tar.gz
fi
if [ ! -d $ECLIPSE ]; then
	echo
	echo "*** Extract Eclipse ***"
	echo
	tar -xvf eclipse-jee-2022-09-R-linux-gtk-x86_64.tar.gz
	ECLIPSE=eclipse
fi

echo
echo "*** Run Maven Build ***"
echo
cd "$IDEMPIERE_SOURCE_FOLDER"
mvn verify

cd ..
./setup-ws.sh --source="$IDEMPIERE_SOURCE_FOLDER"

sleep 1

IDE_PREFERENCE=$ECLIPSE/configuration/.settings/org.eclipse.ui.ide.prefs
if [ ! -d $ECLIPSE/configuration/.settings ]; then
	mkdir $ECLIPSE/configuration/.settings
fi
if [ ! -f $ECLIPSE/configuration/.settings/org.eclipse.ui.ide.prefs ]; then
	echo "MAX_RECENT_WORKSPACES=10" >> $IDE_PREFERENCE
	echo "RECENT_WORKSPACES=$PWD/idempiere"  >> $IDE_PREFERENCE
	echo "RECENT_WORKSPACES_PROTOCOL=3" >> $IDE_PREFERENCE
	echo "SHOW_RECENT_WORKSPACES=false" >> $IDE_PREFERENCE
	echo "SHOW_WORKSPACE_SELECTION_DIALOG=true" >> $IDE_PREFERENCE
	echo "eclipse.preferences.version=1" >> $IDE_PREFERENCE
fi

if [ "$LOAD_IDEMPIERE_ENV" = true ] ; then
	envFile="idempiereEnv.properties"

	if [ -f "$envFile" ]; then
	  while IFS='=' read -r key value
	  do
		key=$(echo $key | sed 's/^ADEMPIERE[_]//')
		eval ${key}=\${value}    
	  done < "$envFile"
	  
	  set
	fi
fi

if [ "$CREATE_DOCKER_POSTGRES" = true ] ; then
	./docker-postgres.sh --db-port=$DB_PORT --db-admin-pass=$DB_SYSTEM --docker-postgres-name=$DOCKER_POSTGRES_NAME
fi

if [ "$SETUP_DB" = true ] ; then
	./setup-db.sh --source="$IDEMPIERE_SOURCE_FOLDER" --db-name=$DB_NAME --db-host=$DB_HOST --db-port=$DB_PORT --db-user=$DB_USER --db-pass=$DB_PASS \
		--db-admin-pass=$DB_SYSTEM --http-host=$IDEMPIERE_HOST --http-port=$IDEMPIERE_PORT --https-port=$IDEMPIERE_SSL_PORT --run-migration-script=$MIGRATE_EXISTING_DATABASE
fi
