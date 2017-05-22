 symbIoTe Core

symbIoTe is a mediator, an intermediary connecting applications and IoT platforms. The basic functionality is that of a registry service which lists platforms, their resources and properties, while also providing an way to map between the platforms' different APIs. 


### Project Build & Deployment

To retrieve, build and deploy the project, the process is the following:

#### Install RabbitMQ server:
  * RabbitMQ is a message queue framework (uses AMQP) that lets our services exchange informations and events.
  * After installation RabbitMQ server should be active in the background without necessity to start it every time you want to run the project. 
    * Details: https://www.rabbitmq.com/download.html  (step by step with APT for Ubuntu/Debian)

#### Install MongoDB server:
  * Before you can launch the project, MongoDB server has to be up and running on your machine.
  * It stores the data in the default directory: `/data/db`, which (if it does not exist yet) you have to create before launching the server. You can remove all of its contents if you want to rerun clean project.  After executing, Mongo server should show status 'waiting for connections on port 27017'.
    * Details: https://www.mongodb.com/download-center  (step by step with APT for Ubuntu/Debian)

#### Clone the Config Properties repository:
  * git clone the CoreConfigProperties repo to directory: `{user.home}/git/symbiote/`  (or any other you want, just make sure to change the path in CoreConfigService bootstrap.properties)
  
#### Clone the rest of the components:
  * If you just want to deploy but not develop/commit any changes, you can get all components straight from the superproject:
   `git clone --recursive https://github.com/symbiote-h2020/SymbioteCore.git`
  * If you want to download the repos for development purposes, you need to clone them individually into separate folders
   * For the symbIoTe Core you need the components:
     * CoreConfigService
     * Eureka
     * Zipkin
     * Administration
     * AuthenticationAuthorizationManager
     * Registry
     * Search
     * SemanticManager
     * CoreResourceMonitor
     * CoreResourceAccessMonitor
     * CoreInterface
     * CloudCoreInterface
     
#### Setup your the Core Authentication and Authorization Manager (CoreAAM)

* You need to create a JavaKeystore containing your CoreAAM certificate:
  * self-signed
  * with CA property enabled
  * with the following encryption params
    * SIGNATURE_ALGORITHM=SHA256withECDSA
    * CURVE_NAME=secp256r1
    * KEY_PAIR_GEN_ALGORITHM=ECDSA
  * with the CN value set according to AAMConstants.java field AAM_CORE_AAM_INSTANCE_ID value
  * with the certificate entry name "symbiote_core_aam"

  This keystore will be used to self-initiliaze the AAM codes as Core AAM.
  
* You need an SSL certificate(s) for your Core AAM and for your CoreInterface to secure communication between the clients and your platform instance. Should they be deployed on the same host, the certificate can be reused in both components.
  * Issue the certificate  using e.g. https://letsencrypt.org/
    Note: A certificate can be obtained using the certbot shell tool (https://certbot.eff.org/) only for resolvable domain name.
  * Instructions for the Ubuntu (Debian) machine are the following: 
    1. Install certbot
        ```
        $ sudo apt-get install software-properties-common
        $ sudo add-apt-repository ppa:certbot/certbot
        $ sudo apt-get update
        $ sudo apt-get install certbot python-certbot-apache
        ```
    2. Obtain the certificate by executing:
        ```
        $ certbot --apache certonly
        ```
        _Note: Apache port (80 by default) should be accessible from outside on your firewall._
        _Select option **Standalone** (option 2) and enter your domain name._
    3. Upon successful execution navigate to the location: 
        ```
        /etc/letsencrypt/live/<domain_name>/ 
        ```
        where you can find your certificate and private key
        * 5 files in total, cert.pem  chain.pem  fullchain.pem  privkey.pem  README


* Create a Java Keystore with the issued SSL certificate, required for Core AAM deployment
  Use the KeyStore Explorer application to create JavaKeystore (http://keystore-explorer.org/downloads.html):
    1. (optionally) Inspect obtained files using Examine --> Examine File
    2. Create a new Keystore --> PKCS #12
    3. Tools --> Import Key Pair --> PKCS #8
    4. Deselect Encrypted Private Key
    5. Browse and set your private key (privkey.pem)
    6. Browse and set your certificate (fullchain.pem)
    7. Import --> enter alias for the certificate for this keystore
    8. Enter password
    9. File --> Save --> enter previously set password  --> <filename>.p12

    Filename will be used as configuration parameter of the Core AAM component.
    `server.ssl.key-store=classpath:<filename>.p12`
    
    If you do not want to use KeyStore Explorer find some helpful resources below:
    * https://community.letsencrypt.org/t/how-to-get-certificates-into-java-keystore/25961/19
    * http://stackoverflow.com/questions/34110426/does-java-support-lets-encrypt-certificates

* After the previous actions, configure the CoreAAM resources
    * You need to enter appropriate values in the file `src/main/resources/bootstrap.properties` manually for each deployment, using the comments within the file itself.
    * You also need to copy to the `src/main/resources/` directory:
        * the JavaKeyStore file containing the self-signed Core AAM cert+key that you have generated
        * the keystore generated for your SSL cerfitiface

#### Build the components:
  * Remember to change the path in ConfigService **bootstrap.properties** if you have changed the ConfigProperties location
  * Build everything using gradle:
    `gradle build`  (or `gradle build -x test` to skip tests)
  * The default location of jars after `gradle build` is `build/libs`
  * To execute the compiled jars, do:
    `java -jar <component_name>.jar` (without moving jars, `java -jar <component_name>.jar`)
    * For the Search component, you may need to use:
    `java -noverify -jar Search-<version>.jar`
    

 - Run the services in order:
    * Run ConfigService first
    * Run EurekaService second
    * Run ZipkinService third
    * Run all remaining components in whichever order you like
    * Check that they were deployed successfully in the Eureka panel: localhost:8761/

#### Veryfing that components are working
* Core AAM
    * Verify that everything is ok by going to:
    `https://<yourCAAMHostname>:<selected port>/get_ca_cert`
    * There you should see the connection green and the content is your Core AAM instance's certificate (the self signed you have generated) in PEM format.
* Core Interface
    * Verify that everything is ok by going to:
    `https://<yourCoreInterfaceHostname>:8100/coreInterface/v1/get_ca_cert`
    * There you should see the connection green and the content is Core AAM instance's certificate in PEM format.

