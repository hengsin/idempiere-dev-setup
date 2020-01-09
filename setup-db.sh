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
MIGRATE_EXISTING_DATABASE=${MIGRATE_EXISTING_DATABASE:false}

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

CWD=$(pwd)
PRODUCT_FOLDER=idempiere/org.idempiere.p2/target/products/org.adempiere.server.product/linux/gtk/x86_64
cd $PRODUCT_FOLDER
echo -e "$JAVA_HOME\n$IDEMPIERE_HOME\n$KEY_STORE_PASS\n$KEY_STORE_ON\n$KEY_STORE_OU\n$KEY_STORE_O\n$KEY_STORE_L\n$KEY_STORE_S\n$KEY_STORE_C\n$IDEMPIERE_HOST\n$IDEMPIERE_PORT\n$IDEMPIERE_SSL_PORT\nN\n2\n$DB_HOST\n$DB_PORT\n$DB_NAME\n$DB_USER\n$DB_PASS\n$DB_SYSTEM\n$MAIL_HOST\n$MAIL_USER\n$MAIL_PASS\n$MAIL_ADMIN\nY\n" | ./console-setup-alt.sh

if ! PGPASSWORD=$DB_PASS psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "\q" > /dev/null 2>&1 ; then
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
	if [[ "$MIGRATE_EXISTING_DATABASE" == "true" ]]; then
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
cp -r -f ./$PRODUCT_FOLDER/jettyhome ./idempiere
cp -f ./$PRODUCT_FOLDER/*.properties ./idempiere
cp -f ./$PRODUCT_FOLDER/hazelcast.xml ./idempiere
