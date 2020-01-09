TYCHO_REPOSITORY=https://repo1.maven.org/maven2/.m2e/connectors/m2eclipse-tycho/0.8.1/N/0.8.1.201704211436/
CDT_REPOSITORY=https://download.eclipse.org/tools/cdt/releases/9.10/
cd eclipse
DESTINATION=$(pwd)

echo "** Install Tycho Configurator ..."
./eclipse -nosplash -data ../idempiere -application org.eclipse.equinox.p2.director \
	-repository $TYCHO_REPOSITORY -destination "$DESTINATION" \
	-installIU org.sonatype.tycho.m2e.feature.feature.group

echo "** Install CDT Headless Build ..."
./eclipse -nosplash -data ../idempiere -application org.eclipse.equinox.p2.director \
	-repository $CDT_REPOSITORY -destination "$DESTINATION" \
	-installIU org.eclipse.cdt.managedbuilder.core

cd ..	
./eclipse/eclipse -nosplash -data ./idempiere -application org.eclipse.ant.core.antRunner -buildfile ./import.xml 

echo "** Clean and build workspace ..."
./eclipse/eclipse -nosplash \
	-application org.eclipse.cdt.managedbuilder.core.headlessbuild \
	-data ./idempiere \
	-build all
