#!/bin/bash
SERVICES=(CoreConfigService EurekaService ZipkinService Registry Search Administration CoreInterface CloudCoreInterface CoreResourceAccessMonitor SemanticManager CoreResourceMonitor AuthenticationAuthorizationManager SymbioteClient AnomalyDetectionModule)
#SERVICES=(CoreConfigService AuthenticationAuthorizationManager CoreInterface AnomalyDetectionModule)

CoreConfigService_TAG=develop
EurekaService_TAG=master
ZipkinService_TAG=master
Registry_TAG=develop
Search_TAG=performance_improvements
Administration_TAG=develop
CoreInterface_TAG=develop
CloudCoreInterface_TAG=develop
CoreResourceAccessMonitor_TAG=develop
SemanticManager_TAG=develop
CoreResourceMonitor_TAG=develop
AuthenticationAuthorizationManager_TAG=4.0.0
SymbioteClient_TAG=master
AnomalyDetectionModule_TAG=1.0.2

HOSTNAME=""
AAM_OWNER=""
AAM_PASSWORD=""
SSL_PASSWORD=""

HOSTNAME_WILDCARD="\[\[docker.hostname\]\]"
AAM_OWNER_WILDCARD="\[\[docker.aam.owner\]\]"
AAM_PASSWORD_WILDCARD="\[\[docker.aam.password\]\]"
SSL_PASSWORD_WILDCARD="\[\[docker.ssl.password\]\]"

initConfig(){
	HOSTNAME=`grep hostname /home/config.txt | cut -d"=" -f 2`
	AAM_OWNER=`grep aam.owner /home/config.txt | cut -d"=" -f 2`
	AAM_PASSWORD=`grep aam.password /home/config.txt | cut -d"=" -f 2`
	SSL_PASSWORD=`grep ssl.password /home/config.txt | cut -d"=" -f 2`
}

checkConfig(){
	echo "Checking configuration"

	if [ ! -e /home/configuration/cert -o ! -e /home/configuration/cert/fullchain.pem -o ! -e /home/configuration/cert/privkey.pem -o ! -e /home/config.txt ]
	then
		>&2 echo "Need to supply privkey.pem and fullchain.pem in ./configuration/cert"
		exit 1
	fi
}

clone(){
	echo "Cloning core components"

	mkdir -p git/symbiote
	cd git/symbiote
	git clone https://github.com/symbiote-h2020/CoreConfigProperties.git

	cd /home

	for SERVICE in ${SERVICES[*]}
	do
		git clone https://github.com/symbiote-h2020/$SERVICE.git
	done
}

setup(){
	echo "Applying components' configuration"

	#create p12
	openssl pkcs12 -export -out /home/configuration/docker-ssl.pfx -inkey /home/configuration/cert/privkey.pem -in /home/configuration/cert/fullchain.pem -name "Docker SSL" -password pass:$SSL_PASSWORD

	replaceWildcards

	git config --global user.email "docker@symbiote-h2020.eu"
	git config --global user.name "Docker"


	cp /home/configuration/CoreConfigProperties/* /home/git/symbiote/CoreConfigProperties
	cd /home/git/symbiote/CoreConfigProperties
	git add *
	git commit -m "Initial docker changes"

	#Checkout proper branch/tag and copy properties
	for SERVICE in ${SERVICES[*]}
	do
		TAG_VAR=${SERVICE}_TAG
		TAG=${!TAG_VAR}
		cd /home/$SERVICE
		git checkout $TAG
		cp /home/configuration/$SERVICE/* /home/configuration/docker-ssl.pfx /home/$SERVICE/src/main/resources
	done
	
}

replaceWildcards(){
	#replace all wildcars in configuration files
	for FILE in `find /home/configuration -iname "*.properties"`
	do
		sed -i "s/$HOSTNAME_WILDCARD/$HOSTNAME/g" $FILE
		sed -i "s/$AAM_OWNER_WILDCARD/$AAM_OWNER/g" $FILE
		sed -i "s/$AAM_PASSWORD_WILDCARD/$AAM_PASSWORD/g" $FILE
		sed -i "s/$SSL_PASSWORD_WILDCARD/$SSL_PASSWORD/g" $FILE
	done
}


build(){
	echo "Building components"
	for SERVICE in ${SERVICES[*]}
	do
		cd /home/$SERVICE
		gradle clean assemble
	done
}

cleanConfiguration(){
	rm -r /home/config*
}

clone_setup_and_build(){
	initConfig
	checkConfig
	clone
	setup
	build
	cleanConfiguration
}

startService(){
	SERVICE_JAR=`find /home/$1/build/ -iname "*.jar"`
	if [ "$1" == "AuthenticationAuthorizationManager" -o "$1" == "EurekaService" -o "$1" == "ZipkinService" -o "$1" == "AnomalyDetectionModule" ]
	then
		SERVICE_JAR=`find /home/$1/build/ -iname "*run.jar"`
	fi
	FLAGS="-Xmx1024m -Duser.home=/home -Dspring.output.ansi.enabled=NEVER"

	#java $FLAGS -jar $SERVICE_JAR

	cd /home/$1

	echo "Starting $1"
	  
	# Make a new screen and give it a name
	screen -dmS $1 -L

	# Make screen cd to the service and start it
	# then cd back so the working dir stays in the root
	screen -S $1 -X chdir $1
	screen -S $1 -X exec java $FLAGS -jar $SERVICE_JAR
}

start(){
	#Wait for docker network to be up
	sleep 10

	startService CoreConfigService
	sleep 15
	startService EurekaService
	startService ZipkinService
	startService AuthenticationAuthorizationManager
	startService SemanticManager
	sleep 15
	startService CoreInterface
	startService CloudCoreInterface
	sleep 15
	startService Registry
	startService Search
	startService Administration
	startService CoreResourceAccessMonitor
	startService CoreResourceMonitor
	startService AnomalyDetectionModule
	startService SymbioteClient

	tail -f /dev/null

}


case "$1" in
 clone_setup_and_build)
   clone_setup_and_build
   ;;
 start)
   start
   ;;
 init_config)
   initConfig
   ;;
  *)
    echo "Usage: $0 COMMAND" 
esac
