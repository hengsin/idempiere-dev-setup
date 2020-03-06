TYCHO_REPOSITORY=https://repo1.maven.org/maven2/.m2e/connectors/m2eclipse-tycho/0.8.1/N/0.8.1.201704211436/
CDT_REPOSITORY=https://download.eclipse.org/tools/cdt/releases/9.10/
ECLIPSE=${ECLIPSE:-eclipse}
IDEMPIERE_SOURCE_FOLDER=${IDEMPIERE_SOURCE_FOLDER:-idempiere}

for i in "$@"
do
    case $i in
    --source=*)
    IDEMPIERE_SOURCE_FOLDER="${i#*=}"
    shift # past argument=value
    ;;
    --eclipse=*)
    ECLIPSE="${i#*=}"
    shift # past argument=value
    ;;
    --help)
    echo "Usage: setup-ws.sh [OPTION]"
    echo ""
    echo -e "  --eclipse=<eclipse ide folder>"
    echo -e "\tSet eclipse ide folder (default is eclipse)"
    echo -e "  --source=<idempiere source folder>"
    echo -e "\tSet idempiere source folder (default is idempiere)"
    echo -e "  --help"
    echo -e "\tdisplay this help and exit"
    exit 0
    ;;
    *)
	shift
	;;
    esac
done

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
if [[ $IDEMPIERE_SOURCE_FOLDER == "/*" ]]; then
	:
else
	IDEMPIERE_SOURCE_FOLDER="$DIR/$IDEMPIERE_SOURCE_FOLDER"	
fi

cd $ECLIPSE
DESTINATION=$(pwd)

echo
echo "*** Install Tycho Configurator ***"
./eclipse -nosplash -data "$IDEMPIERE_SOURCE_FOLDER" -application org.eclipse.equinox.p2.director \
	-repository $TYCHO_REPOSITORY -destination "$DESTINATION" \
	-installIU org.sonatype.tycho.m2e.feature.feature.group

echo
echo "*** Install CDT Headless Build ***"
./eclipse -nosplash -data $IDEMPIERE_SOURCE_FOLDER -application org.eclipse.equinox.p2.director \
	-repository $CDT_REPOSITORY -destination "$DESTINATION" \
	-installIU org.eclipse.cdt.managedbuilder.core

./eclipse -nosplash -data "$IDEMPIERE_SOURCE_FOLDER" -application org.eclipse.ant.core.antRunner -buildfile "$DIR/setup-ws.xml" -Didempiere="$IDEMPIERE_SOURCE_FOLDER"

./eclipse -nosplash -data "$IDEMPIERE_SOURCE_FOLDER" -application org.eclipse.ant.core.antRunner -buildfile "$DIR/loadtargetplatform.xml" -Didempiere="$IDEMPIERE_SOURCE_FOLDER"

echo
echo "*** Build workspace at $IDEMPIERE_SOURCE_FOLDER ***"

./eclipse -nosplash \
	-application org.eclipse.cdt.managedbuilder.core.headlessbuild \
	-data "$IDEMPIERE_SOURCE_FOLDER" \
	-cleanBuild all
	
cd "$DIR"
