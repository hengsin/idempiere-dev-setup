CREATE_DOCKER_POSTGRES=false
LOAD_IDEMPIERE_ENV=false
SETUP_DB=true

for i in "$@"
do
    case $i in
    --help)
    echo "Usage: setup.sh [OPTION]"
    echo ""
    echo -e "  --create-docker-postgres"
    echo -e "\tCreate and run docker postgres 9.6 container"
    echo -e "  --load-idempiere-env"
    echo -e "\tLoad environment variable values from idempiereEnv.properties (if exists)"
    echo -e "  --skip-setup-db"
    echo -e "\tSkip the step to create/sync idempiere db, setup connection properties (idempiere.properties) and the setup of jetty server (jettyhome)"
    echo -e "  --help"
    echo -e "\tdisplay this help and exit"
    exit 0
    ;;
	--create-docker-postgres) CREATE_DOCKER_POSTGRES=true;;
	--load-idempiere-env) LOAD_IDEMPIERE_ENV=true;;
	--skip-setup-db) SETUP_DB=false;;
	*)
	;;
    esac
done

if [ ! -d idempiere ]; then
	echo "** Clone iDempiere ..."
	git clone https://github.com/idempiere/idempiere.git idempiere
fi
if [ ! -f groovy-all-2.4.17.jar ]; then
	echo "** Download groovy-all ..."
	wget https://repo1.maven.org/maven2/org/codehaus/groovy/groovy-all/2.4.17/groovy-all-2.4.17.jar
fi
if [ ! -f eclipse-jee-2019-12-R-linux-gtk-x86_64.tar.gz ]; then
	echo "** Download Eclipse ..."
    wget http://www.mirrorservice.org/sites/download.eclipse.org/eclipseMirror/technology/epp/downloads/release/2019-12/R/eclipse-jee-2019-12-R-linux-gtk-x86_64.tar.gz
fi
if [ ! -d eclipse ]; then
	echo "** Extract Eclipse ... "
	tar -xf eclipse-jee-2019-12-R-linux-gtk-x86_64.tar.gz
fi

echo "** Run Maven Build ..."
cd idempiere
mvn verify

cd ..
./import.sh

sleep 1

IDE_PREFERENCE=eclipse/configuration/.settings/org.eclipse.ui.ide.prefs
if [ ! -d eclipse/configuration/.settings ]; then
	mkdir eclipse/configuration/.settings
fi
if [ ! -f eclipse/configuration/.settings/org.eclipse.ui.ide.prefs ]; then
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
	./docker-postgres.sh
fi

if [ "$SETUP_DB" = true ] ; then
	./setup-db.sh
fi
