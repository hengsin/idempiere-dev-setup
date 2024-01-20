#!/bin/bash 
DOCKER_POSTGRES_CREATE=false
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

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
    --help)
    echo "Usage: setup.sh [OPTION]"
    echo ""
    echo -e "  --docker-postgres-create"
    echo -e "\tCreate and run docker postgres container (default false)"
    echo -e "  --docker-postgres-name <postgres container name>"
    echo -e "\tSet docker postgres container name (default is postgres)"
    echo -e "  --db-name <idempiere database name>"
    echo -e "\tSet idempiere database name (default is idempiere)"
    echo -e "  --db-host <database server host name>"
    echo -e "\tSet idempiere database server host name (default is localhost)"
    echo -e "  --db-port <idempiere database server port>"
    echo -e "\tSet idempiere database server port (default is 5432)"
    echo -e "  --db-user <idempiere database user name>"
    echo -e "\tSet idempiere database user name (default is adempiere)"
    echo -e "  --db-pass <idempiere database user password>"
    echo -e "\tSet idempiere database user password (default is adempiere)"
    echo -e "  --db-admin-pass <database server administrator password>"
    echo -e "\tSet database administrator password (default is postgres)"
    echo -e "  --http-host <host ip>"
    echo -e "\tSet http address/ip to listen to (default is 0.0.0.0, i.e all available address)"
    echo -e "  --http-port <http port>"
    echo -e "\tSet http port to listen to (default is 8080)"
    echo -e "  --https-port <http port>"
    echo -e "\tSet https/ssl port to listen to (default is 8443)"
    echo -e "  --load-idempiere-env"
    echo -e "\tLoad environment variable values from idempiereEnv.properties (if exists)"
    echo -e "  --eclipse <eclipse ide folder>"
    echo -e "\tSet eclipse ide folder (default is eclipse)"
    echo -e "  --source <idempiere source folder>"
    echo -e "\tSet idempiere source folder (default is idempiere)"
    echo -e "  --skip-setup-db"
    echo -e "\tDo not create/sync idempiere db, setup connection properties (idempiere.properties) and setup jetty server (jettyhome)"
    echo -e "  --branch <branch name>"
    echo -e "\tCheckout branch instead of master"
    echo -e "  --repository-url <git repository url>"
    echo -e "\tSet git repository URL to clone source from (default is $SOURCE_URL)"
    echo -e "  --skip-migration-script"
    echo -e "\tDo not run migration scripts against existing db (default will run)"
    echo -e "  --help"
    echo -e "\tdisplay this help and exit"
    exit 0
    ;;
    --docker-postgres-create) 
    DOCKER_POSTGRES_CREATE=true
    shift
    ;;
    --docker-postgres-name)
    DOCKER_POSTGRES_NAME="$2"
    shift # past argument
    shift # past value
    ;;
    --db-name)
    DB_NAME="$2"
    shift # past argument
    shift # past value
    ;;
    --db-host)
    DB_HOST="$2"
    shift # past argument
    shift # past value
    ;;
    --db-port)
    DB_PORT="$2"
    shift # past argument
    shift # past value
    ;;
    --db-user)
    DB_USER="$2"
    shift # past argument
    shift # past value
    ;;
    --db-pass)
    DB_PASS="$2"
    shift # past argument
    shift # past value
    ;;
    --db-admin-pass)
    DB_SYSTEM="$2"
    shift # past argument
    shift # past value
    ;;    
    --http-host)
    IDEMPIERE_HOST="$2"
    shift # past argument
    shift # past value
    ;;
    --http-port)
    IDEMPIERE_PORT="$2"
    shift # past argument
    shift # past value
    ;;
    --https-port)
    IDEMPIERE_SSL_PORT="$2"
    shift # past argument
    shift # past value
    ;;
    --load-idempiere-env) 
    LOAD_IDEMPIERE_ENV=true
    shift
    ;;
    --eclipse)
    ECLIPSE="$2"
    shift # past argument
    shift # past value
    ;;
    --source)
    IDEMPIERE_SOURCE_FOLDER="$2"
    shift # past argument
    shift # past value
    ;;
    --skip-setup-db) 
    SETUP_DB=false
    shift
    ;;
    --branch) 
    CLONE_BRANCH=true
    BRANCH_NAME="$2"
    shift # past argument
    shift # past value
    ;;
    --skip-migration-script)
    MIGRATE_EXISTING_DATABASE=false
    shift
    ;;
    --repository-url)
    SOURCE_URL="$2"
    shift # past argument
    shift # past value
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

if [ ! -f eclipse-jee-2023-12-R-linux-gtk-x86_64.tar.gz ]; then
        echo
        echo "*** Download Eclipse ***"
        echo
   	 wget https://download.eclipse.org/technology/epp/downloads/release/2023-12/R/eclipse-jee-2023-12-R-linux-gtk-x86_64.tar.gz
fi
if [ ! -d $ECLIPSE ]; then
        echo
        echo "*** Extract Eclipse ***"
        echo
        tar --warning=no-unknown-keyword -xvf eclipse-jee-2023-12-R-linux-gtk-x86_64.tar.gz
        ECLIPSE=eclipse
fi

export JAVA_HOME=$(pwd)/eclipse/plugins/org.eclipse.justj.openjdk.hotspot.jre.full.linux.x86_64_17.0.9.v20231028-0858/jre

JAVA_MAJOR_VERSION=$($JAVA_HOME/bin/java -version 2>&1 | sed -E -n 's/.* version "([^.-]*).*"/\1/p' | cut -d' ' -f1)

if [ "$JAVA_MAJOR_VERSION" != "17" ]; then
	echo -e "Please set the JAVA_HOME environment variable pointing to a JDK 17 installation folder"
	echo -e "For e.g, export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64"
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
        if [ "$CLONE_BRANCH" = true ] ; then
                git -C $IDEMPIERE_SOURCE_FOLDER checkout $BRANCH_NAME
        fi
fi
if [ ! -f apache-groovy-binary-4.0.13.zip ]; then
	echo
	echo "*** Download groovy ***"
	echo
	wget https://archive.apache.org/dist/groovy/4.0.13/distribution/apache-groovy-binary-4.0.13.zip
	unzip apache-groovy-binary-4.0.13.zip
fi
if [ ! -d "groovy-4.0.13" ]; then
	echo
	echo "*** Extract Groovy ***"
	echo
	unzip apache-groovy-binary-4.0.13.zip
fi

echo
echo "*** Run Maven Build ***"
echo
cd "$IDEMPIERE_SOURCE_FOLDER"
mvn verify

cd ..
./setup-ws.sh --source "$IDEMPIERE_SOURCE_FOLDER"

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

if [ "$DOCKER_POSTGRES_CREATE" = true ] ; then
	./docker-postgres.sh --db-port $DB_PORT --db-admin-pass $DB_SYSTEM --docker-postgres-name $DOCKER_POSTGRES_NAME
	sleep 5
        docker ps -a
fi

if [ "$SETUP_DB" = true ] ; then
	./setup-db.sh --source "$IDEMPIERE_SOURCE_FOLDER" --db-name $DB_NAME --db-host $DB_HOST --db-port $DB_PORT --db-user $DB_USER --db-pass $DB_PASS \
		--db-admin-pass $DB_SYSTEM --http-host $IDEMPIERE_HOST --http-port $IDEMPIERE_PORT --https-port $IDEMPIERE_SSL_PORT --run-migration-script $MIGRATE_EXISTING_DATABASE
fi
