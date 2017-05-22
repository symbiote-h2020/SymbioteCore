# SymbIoTe Core

symbIoTe is a mediator, an intermediary connecting applications and IoT platforms. The basic functionality is that of a registry service which lists platforms, their resources and properties, while also providing a way to map between the platforms' different APIs. 

## Project Build & Deployment

####  Install [Java Runtime Environment](https://java.com/download) 
* You need Oracle Java 8 version 101+ [(Letsencrypt certificate compatibility)](https://letsencrypt.org/docs/certificate-compatibility/)
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

## Accessing resources
An application can use a resource by following these steps:

#### 3.1 Search for resource
To search for resource we need to create a query to the symbIoTe Core. In our example, we use https://core.symbiote.eu:8100/coreInterface/v1/query endpoint and provide parameters for querying. All possible query parameters can be seen below:
```
Query parameters {
         platform_id:           String
         platform_name:         String
         owner:                 String
         name:                  String
         id:                    String
         description:           String
         location_name:         String
         location_lat:          Double
         location_long:         Double
         max_distance:          Integer
         observed_property:     List<String>
         resource_type: 	String 
}
```
##### NOTE 1:
To query using geospatial properties, all 3 properties need to be set: *location_lat* (latitude), *location_long* (longitude) and *max_distance*(distance from specified point in meters).

##### NOTE 2:
Text parameters allow substring searches using '\*' character which can be placed at the beginning and/or end of the word to search for. For example, querying for name "Sensor\*" finds all resources with name starting with Sensor, and querying for name "\*12\*" will find all resources containing string "12" in its name. Using substring search can be done for the following fields:

* name
* platform_name
* owner
* description
* location_name
* observed_property

For our example lets search for resources with name *Stationary 1*. We do it by sending *HTTP GET* request on symbIoTe Core Interface (e.g. https://core.symbiote.eu:8100/coreInterface/v1/query?name=Stationary 1). The response contains a list of resources fulfilling the criteria:
```
{
  "resources": [
    {
      "platformId": "test1Plat",
      "platformName": "Test 1 Plat",
      "owner": null,
      "name": "Stationary 1",
      "id": "591ae23eb80b283c012fdf26",
      "description": "This is stationary 1",
      "locationName": "SomeLocation",
      "locationLatitude": 25.864716,
      "locationLongitude": 5.349014,
      "locationAltitude": 35,
      "observedProperties": [
        "temperature",
        "humidity"
      ],
      "resourceType": [
        "https://www.symbiote-h2020.eu/ontology/core#StationarySensor"
      ]
    }
  ]
}
```
##### 3.1.2 SPARQL query endpoint
In release 0.2.0, an additional endpoint was created to allow sending *SPARQL* queries to symbIoTe Core. To send *SPARQL* queries, we need to send a request by using *HTTP POST* to the url: https://core.symbiote.eu:8100/coreInterface/v1/sparqlQuery. The endpoint accepts the following payload:
```
{ 
    "sparqlQuery" : "<sparql>",
    "outputFormat" : "<format>"
    
}
```
Possible output formats include: SRX, XML, JSON, SRJ, SRT, THRIFT, SSE, CSV, TSV, SRB, TEXT, COUNT, TUPLES, NONE, RDF, RDF_N3, RDF_XML, N3, TTL, TURTLE, GRAPH, NT, N_TRIPLES, TRIG. SPARQL allows for powerful access to all the meta information stored within symbIoTe Core. Below you can find few example queries:

* Query all resources of the core
```
 { 
    "sparqlQuery" : "PREFIX cim: <http://www.symbiote-h2020.eu/ontology/core#> PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#> SELECT ?res ?resourceName WHERE { ?res a cim:Resource. ?res rdfs:label ?resourceName . }",
    "outputFormat" : "TEXT"
}
```
returns the following output:
```
------------------------------------------------------------------------------------------------------
| res                                                                        | resourceName          |
======================================================================================================
| <http://www.symbiote-h2020.eu/ontology/resources/591ae23eb80b283c012fdf26> | "Stationary 1"        |
| <http://www.symbiote-h2020.eu/ontology/resources/591ae5edb80b283c012fdf29> | "Actuating Service 1" |
------------------------------------------------------------------------------------------------------
```
* Query for Actuating Services and display information about input they are requiring: name and datatype
```
{ 
    "sparqlQuery" : "PREFIX cim: <http://www.symbiote-h2020.eu/ontology/core#> PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#> SELECT ?res ?resourceName ?inputName ?inputDatatype WHERE { ?res a cim:ActuatingService. ?res rdfs:label ?resourceName . ?res cim:hasInputParameter ?input . ?input cim:name ?inputName . ?input cim:datatype ?inputDatatype }",
    "outputFormat" : "TEXT"
}
```
returns the following output:
```
--------------------------------------------------------------------------------------------------------------------------------------
| res                                                                        | resourceName          | inputName     | inputDatatype |
======================================================================================================================================
| <http://www.symbiote-h2020.eu/ontology/resources/591af131b80b2847be1d62eb> | "Actuating Service 1" | "inputParam1" | "xsd:string"  |
--------------------------------------------------------------------------------------------------------------------------------------
```

#### 3.2 Obtaining resource access URL
To access the resource we need to ask symbIoTe Core for the access url. To do so, we need to send a *HTTP GET* request on https://core.symbiote.eu:8100/coreInterface/v1/resourceUrls?id=589dc62a9bdddb2d2a7ggab8. To access the endpoint, we need to specify *X-Auth-Token* header with a valid platform token of the user that is trying to access the resources. 

##### 3.3.1 Request a platform token directly
In this case, you can request a platform token from the PAAM of the platform which owns the resources you are interested in. For that, you have to issue a *HTTP POST* request to https://myplatform.eu:8102/paam/login containing the following:
```
{
  "username" : "The username name used when registering to the PLATFORM",
  "password" : "The password name used when registering to the PLATFORM"
}
```
The token will be contained in the *X-Auth-Token* header field of the response.

##### NOTE:
If you do not know the PAAM url, then you can issue a *HTTP GET* request to https://core.symbiote.eu:8100/coreInterface/v1/get_available_aams and distinguishing the desired PAAM by the *platform id*. 

##### 3.3.2 Request a platform token by providing a core token
In this case, first you have to get a core token. For that, you have to issue a "HTTP POST" request to https://core.symbiote.eu:8100/coreInterface/v1/login containing the following:
```
{
  "username" : "The username name used when registering to the symbIoTe CORE",
  "password" : "The password name used when registering to the symbIoTe CORE"
}
```
Then, you have to get the url of the PAAM as described above and issue a *HTTP POST* request to https://myplatform.eu:8102/paam/login containing the core token in the *X-Auth-Token* header field. The platform token will be included in the *X-Auth-Token* header field of the response.

##### 3.3.3 Get the resource urls
If we provide correct ids of the resources along with a valid platform token, we will get a response containing URLs to access the resources:
```
{  
	"589dc62a9bdddb2d2a7ggab8": "https://myplatform.eu:8102/rap/Sensor('589dc62a9bdddb2d2a7ggab8')",
	"589dc62a9bdddb2d2a7ggab9": "https://myplatform.eu:8102/rap/Sensor('589dc62a9bdddb2d2a7ggab9')"
 }
 ```
 
#### 3.3 Accessing the resource and triggering fetching of our example data
##### NOTE:
First, you have to get a valid platform token and included it in the *X-Auth-Token* header field as described above. The same token used to get the resource url can also be used for accessing the resource if it is still valid.  

As stated previously, RAP can be configured to support different interfaces for accessing the data:
* OData
* REST

The applications can:
* Read current value from resource
* Read history values from resource
* Write value into resource

3.3.1 OData access
* GET  https://myplatform.eu:8102/rap/Sensor('symbioteId')/Observations? $top=1
* GET https://myplatform.eu:8102/rap/Sensor('symbioteId')/Observations
  Historical readings can be filtered, using the option $filter.
  Operators supported: 
  * Equals
  * Not Equals
  * Less Than
  * Greater Than
  * And
  * Or
* PUT https://myplatform.eu:8102/rap/Actuator(‘actuatorId')/ActuatingService(‘serviceId')
```
{
    "inputParameters":
    [  
        { 
             "name": “prop1Name",
             "value": “prop1Value“
        },
        {
              "name": “prop2Name",
              "value": “prop2Value“
        },
        …
    ]
}
```

##### 3.3.2 REST access
* GET https://myplatform.eu:8102/rap/Sensor/{symbioteId}
* GET https://myplatform.eu:8102/rap/Sensor/{symbioteId}/history
* POST https://myplatform.eu:8102/rap/Service(‘symbioteId')
```
{
    "inputParameters":
    [  
        { 
             "name": “prop1Name",
             "value": “prop1Value“
        },
        {
              "name": “prop2Name",
              "value": “prop2Value“
        },
        …
    ]
} 
```

##### 3.3.3 Push feature 
Applications can receive notifications from resources, through SymbIoTe RAP WebSocket. The client shall open a WebSocket connection towards a Server at ws://IP:PORT/rap/notification, where IP and PORT are the Interworking Interface parameters of the platform.

To subscribe (or unsubscribe) to resources you have to send a message to the WebSocket specifying:
```
{
"action": SUBSCRIBE / UNSUBSCRIBE
"ids": [id1, id2, id3, ...]
}
```
Afterwards, notifications will be automatically received by the application from the WebSocket.
