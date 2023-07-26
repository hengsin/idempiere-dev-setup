#!/bin/bash
JAVA_OPTIONS=${JAVA_OPTIONS:--Xmx2048M}
KEY_STORE_PASS=${KEY_STORE_PASS:-myPassword}
KEY_STORE_ON=${KEY_STORE_ON:-idempiere.org}
KEY_STORE_OU=${KEY_STORE_OU:-iDempiere Github}
KEY_STORE_O=${KEY_STORE_O:-iDempiere}
KEY_STORE_L=${KEY_STORE_L:-myTown}
KEY_STORE_S=${KEY_STORE_S:-CA}
KEY_STORE_C=${KEY_STORE_C:-US}
IDEMPIERE_HOST=${IDEMPIERE_HOST:-0.0.0.0}
IDEMPIERE_PORT=${IDEMPIERE_PORT:-8080}
IDEMPIERE_SSL_PORT=${IDEMPIERE_SSL_PORT:-8443}
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}
DB_NAME=${DB_NAME:-idempiere}
DB_USER=${DB_USER:-adempiere}
DB_PASS=${DB_PASS:-adempiere}
DB_SYSTEM=${DB_SYSTEM:-postgres}
MAIL_HOST=${MAIL_HOST:-0.0.0.0}
MAIL_USER=${MAIL_USER:-info}
MAIL_PASS=${MAIL_PASS:-info}
MAIL_ADMIN=${MAIL_ADMIN:-info@idempiere}
MIGRATE_EXISTING_DATABASE=${MIGRATE_EXISTING_DATABASE:-true}
IDEMPIERE_SOURCE_FOLDER=${IDEMPIERE_SOURCE_FOLDER:-idempiere}

if [[ -n "$DB_PASS_FILE" ]]; then
    echo "DB_PASS_FILE set as $DB_PASS_FILE..."
    DB_PASS=$(cat $DB_PASS_FILE)
fi

if [[ -n "$DB_ADMIN_PASS_FILE" ]]; then
    echo "DB_ADMIN_PASS_FILE set as $DB_ADMIN_PASS_FILE..."
    DB_SYSTEM=$(cat $DB_ADMIN_PASS_FILE)
fi

if [[ -n "$MAIL_PASS_FILE" ]]; then
    echo "MAIL_PASS_FILE set as $MAIL_PASS_FILE..."
    MAIL_PASS=$(cat $MAIL_PASS_FILE)
fi

if [[ -n "$KEY_STORE_PASS_FILE" ]]; then
    echo "KEY_STORE_PASS_FILE set as $KEY_STORE_PASS_FILE..."
    KEY_STORE_PASS=$(cat $KEY_STORE_PASS_FILE)
fi

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
    --db-name)
    DB_NAME="$2"
    shift # past argument
    shift # past value
    ;;
    --db-pass)
    DB_PASS="$2"
    shift
    shift
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
    --db-admin-pass)
    DB_SYSTEM="$2"
    shift # past argument
    shift # past value
    ;;
    --source)
    IDEMPIERE_SOURCE_FOLDER="$2"
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
    --run-migration-script)
    MIGRATE_EXISTING_DATABASE="$2"
    shift # past argument
    shift # past value
    ;;
    --help)
    echo "Usage: setup-db.sh [OPTION]"
    echo ""
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
    echo -e "  --source <idempiere source folder>"
    echo -e "\tSet idempiere source folder (default is idempiere)"
    echo -e "  --run-migration-script <true/false>"
    echo -e "\tRun migration scripts against existing db (default is true)"
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

export PGPASSWORD=$DB_SYSTEM 
if ! psql -h $DB_HOST -p $DB_PORT -U postgres -d postgres -c "\q" > /dev/null 2>&1 ; then
	export PGPASSWORD=$DB_PASS
	if ! psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "\q" > /dev/null 2>&1 ; then
		echo "Bad postgres admin password and couldn't connect to idempiere database $DB_NAME using the provided credential.";
		echo "Please fix the db credential parameters and rerun the setup script or set up the connection properties file manually after completion of the script."
		exit 0;
	fi
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
if [[ $IDEMPIERE_SOURCE_FOLDER == "/*" ]]; then
	:
else
	IDEMPIERE_SOURCE_FOLDER="$DIR/$IDEMPIERE_SOURCE_FOLDER"	
fi

CWD=$(pwd)
PRODUCT_FOLDER=$IDEMPIERE_SOURCE_FOLDER/org.idempiere.p2/target/products/org.adempiere.server.product/linux/gtk/x86_64
cd $PRODUCT_FOLDER
echo -e "$JAVA_HOME\n$JAVA_OPTIONS\n$IDEMPIERE_HOME\n$KEY_STORE_PASS\n$KEY_STORE_ON\n$KEY_STORE_OU\n$KEY_STORE_O\n$KEY_STORE_L\n$KEY_STORE_S\n$KEY_STORE_C\n$IDEMPIERE_HOST\n$IDEMPIERE_PORT\n$IDEMPIERE_SSL_PORT\nN\n2\n$DB_HOST\n$DB_PORT\n$DB_NAME\n$DB_USER\n$DB_PASS\n$DB_SYSTEM\n$MAIL_HOST\n$MAIL_USER\n$MAIL_PASS\n$MAIL_ADMIN\nY\n" | ./console-setup-alt.sh

export PGPASSWORD=$DB_PASS
if ! psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "\q" > /dev/null 2>&1 ; then
	cd utils
	echo "Database '$DB_NAME' not found, starting import..."
	echo -e "\n" | ./RUN_ImportIdempiere.sh
	echo "Synchronizing database..."
	./RUN_SyncDB.sh
	cd ..
	echo "Signing database..."
	./sign-database-build.sh
else
	echo "Database '$DB_NAME' is found..."
	if [ "$MIGRATE_EXISTING_DATABASE" = true ]; then
		cd utils
		echo "MIGRATE_EXISTING_DATABASE is equal to 'true'. Synchronizing database..."
		./RUN_SyncDB.sh
		cd ..
		echo "Signing database..."
		./sign-database-build.sh
	else
		echo "MIGRATE_EXISTING_DATABASE is equal to 'false'. Skipping..."
	fi
fi
    
cd "$CWD"
cp -r -f $PRODUCT_FOLDER/jettyhome $IDEMPIERE_SOURCE_FOLDER
cp -f $PRODUCT_FOLDER/*.properties $IDEMPIERE_SOURCE_FOLDER
cp -f $PRODUCT_FOLDER/hazelcast.xml $IDEMPIERE_SOURCE_FOLDER
cp $IDEMPIERE_SOURCE_FOLDER/org.idempiere.p2/target/products/org.adempiere.server.product/linux/gtk/x86_64/.idpass  $IDEMPIERE_SOURCE_FOLDER
