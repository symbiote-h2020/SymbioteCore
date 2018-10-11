# SymbIoTe Core

symbIoTe is a mediator, an intermediary connecting applications and IoT platforms. The basic functionality is that of a registry service which lists platforms, their resources and properties, while also providing a way to map between the platforms' different APIs. 

## Interworking Interface Documentation
There are 2 kinds of interworking interfaces in the SymbIoTe Core:
* The _coreInterface_ which serves northbound traffic coming from 3rd parties (e.g. applications searching for resources).
 The interface description can be found [here](https://symbiote-h2020.github.io/SymbioteCore/coreInterface/)
* The _cloudCoreInterface_ which serves southbound traffic coming from IoT platforms (e.g. applications). The interface description can be found [here](https://symbiote-h2020.github.io/SymbioteCore/cloudCoreInterface/)

## Project Build & Deployment

###  Install [Java Runtime Environment](https://java.com/download) 
* You need Oracle Java 8 version 101+ [(Letsencrypt certificate compatibility)](https://letsencrypt.org/docs/certificate-compatibility/)
### Install RabbitMQ server:
* RabbitMQ is a message queue framework (uses AMQP) that lets our services exchange informations and events.
* After installation RabbitMQ server should be active in the background without necessity to start it every time you want to run the project. 
    * Details: https://www.rabbitmq.com/download.html  (step by step with APT for Ubuntu/Debian)

### Install MongoDB server:
* Before you can launch the project, MongoDB server has to be up and running on your machine.
* It stores the data in the default directory: `/data/db`, which (if it does not exist yet) you have to create before launching the server. You can remove all of its contents if you want to rerun clean project.  After executing, Mongo server should show status 'waiting for connections on port 27017'.
    * Details: https://www.mongodb.com/download-center  (step by step with APT for Ubuntu/Debian)

### Clone the Config Properties repository:
* git clone the CoreConfigProperties repo to directory: `{user.home}/git/symbiote/`  (or any other you want, just make sure to change the path in CoreConfigService bootstrap.properties)
  
### Clone the rest of the components:
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

### Setup your the Core Authentication and Authorization Manager (CoreAAM)

#### Core AAM certificate

You need to create a PKCS12 keystore containing a certificate:

* self-signed
* with CA property enabled
*  with the following encryption params
   * SIGNATURE_ALGORITHM=SHA256withECDSA
   * CURVE_NAME=secp256r
   * KEY_PAIR_GEN_ALGORITHM=ECDSA
* with the CN value set according to AAMConstants.java field CORE_AAM_INSTANCE_ID value (e.g. currently SymbIoTe_Core_AAM)
* with the certificate entry name "symbiote_core_aam"

This keystore will be used to self-initiliaze the AAM codes as Core AAM.

#### SSL certificate

To secure communication between the clients and your platform instance you need an SSL certificate(s) for your Core AAM and for your CoreInterface. Should they be deployed on the same host, the certificate can be reused in both components.

##### How to issue the certificate

* Issue using e.g. https://letsencrypt.org/
* A certificate can be obtained using the certbot shell tool (https://certbot.eff.org/) only for resolvable domain name.

Instructions for the Ubuntu (Debian) machine are the following:

1. Install certbot:
   ```
   sudo apt-get install software-properties-common
   sudo add-apt-repository ppa:certbot/certbot
   sudo apt-get update
   sudo apt-get install certbot python-certbot-apache
   ```
2. Obtain the certificate by executing
   ```
   certbot --apache certonly
   ```
   Apache port (80 by default) should be accessible from outside on your firewall.
   Select option Standalone (option 2) and enter your domain name.
   
3. Upon successful execution navigate to the location:
   ```
   /etc/letsencrypt/live/<domain_name>/ 
   ```
where you can find your certificate and private key (5 files in total, cert.pem, chain.pem, fullchain.pem, privkey.pem, README).

##### How to create a Java Keystore with the issued SSL certificate, required for Core AAM deployment

Create a Java Keystore containing the certificate. Use the [KeyStore Explorer](http://keystore-explorer.org/dow
nloads.html) application to create JavaKeystore:

1. (optionally) Inspect obtained files using Examine --> Examine File
2. Create a new Keystore --> PKCS #
3. Tools --> Import Key Pair --> PKCS #
4. Deselect Encrypted Private Key
   Browse and set your private key (*privkey.pem*)
   Browse and set your certificate (*fullchain.pem*)
5. Import --> enter alias for the certificate for this keystore
6. Enter password
7. File --> Save --> enter previously set password  --> <filename>.p12    
  Filename will be used as configuration parameter of the Platform AAM component.   
  `server.ssl.key-store=classpath:<filename>.p12`

If you do not want to use KeyStore Explorer find some helpful resources below:  
* https://community.letsencrypt.org/t/how-to-get-certificates-into-java-keystore/25961/19  
* http://stackoverflow.com/questions/34110426/does-java-support-lets-encrypt-certificates


##### Configuring the CoreAAM resources

Once one has done previous actions, you need to fix the file 'src/main/resources/bootstrap.properties' manually for each deployment using the template below or comments from the file itself.
```
spring.cloud.config.enabled=true
spring.application.name=AuthenticationAuthorizationManager
logging.file=logs/AuthenticationAuthorizationManager.log
  
# username and password of the AAM module (of your choice)
aam.deployment.owner.username=TODO
aam.deployment.owner.password=TODO
# name of the CAAM keystore file you need to put in your src/main/resources directory
aam.security.KEY_STORE_FILE_NAME=TODO.p12
# name of the root ca certificate entry in the Keystore you were given
aam.security.ROOT_CA_CERTIFICATE_ALIAS=symbiote_core_aam
# name of the certificate entry in the Keystore you were given
aam.security.CERTIFICATE_ALIAS=symbiote_core_aam
# symbiote keystore password
aam.security.KEY_STORE_PASSWORD=TODO
# symbiote certificate private key password
aam.security.PV_KEY_PASSWORD=TODO
#JWT validity time in milliseconds - how long the tokens issued to your users (apps) are valid... think maybe of an hour, day, week?
aam.deployment.token.validityMillis=TODO
# allowing offline validation of foreign tokens by signature trust-chain only. Useful when foreign tokens are expected to be used along with no internet access
aam.deployment.validation.allow-offline=false
# HTTPS only
# name of the keystore containing the letsencrypt (or other) certificate and key pair for your AAM host's SSL, you need to put it also in your src/main/resources directory
server.ssl.key-store=classpath:TODO.p12
# SSL keystore password
server.ssl.key-store-password=TODO
# SSL certificate private key password
server.ssl.key-password=TODO
# http to https redirect
security.require-ssl=true

```
You also need to copy to the `src/main/resources/` directory:

1. the generated in step 2.4.1 keystore Platform AAM symbiote certificate and keys
2. the generated in step 2.4.2 keystore generated for your SSL cerfitiface

### Build the components:
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

### Veryfing that the components are working

#### Veryfing that Core AAM is working

Verify all is ok by going to:
```
https://<yourCAAMHostname>:<selected port>/get_available_aams
```
There you should see the connection green and the content are the available symbiote security endpoints (currently only your Core AAM as no platforms are registered in it yet)

Also you can check that the certificate listed there matches the one you get here:
```
https://<yourCAAMHostname>:<selected port>/get_component_certificate/platform/SymbIoTe_Core_AAM/component/aam
```

#### Veryfing that CoreInterface is working
Verify all is ok by going to:
```
https://<yourCoreInterfaceHostname>/aam/get_component_certificate/platform/SymbIoTe_Core_AAM/component/aam
```
There you should see the connection green and the content is Core AAM instance's certificate in PEM format.

#### Core AAM management

Mainly via the Administration interface or using some APIs:

e.g. To manage your local users you can use the AMQP API listening on:
```
rabbit.queue.manage.user.request=symbIoTe-AuthenticationAuthorizationManager-manage_user_request
rabbit.routingKey.manage.user.request=symbIoTe.AuthenticationAuthorizationManager.manage_user_request
```
With the following contents:   

| **Request payload**                                                                                                                                                                                                                                                                                                                                                                                    | **Response**                                                                                                                                                     |
|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| <div> OperationType#CREATE  [UserManagementRequest](https://github.com/symbiote-h2020/SymbIoTeSecurity/blob/develop/src/main/java/eu/h2020/symbiote/security/communication/payloads/UserManagementRequest.java) <ul><li> admin credentials // for operation authorization</li><li>user credentials (username, password) </li><li>user details (recovery mail, federated ID)</li></ul></div>                                                             | [ManagementStatus](https://github.com/symbiote-h2020/SymbIoTeSecurity/blob/develop/src/main/java/eu/h2020/symbiote/security/commons/enums/ManagementStatus.java) |
| <div>OperationType#UPDATE  [UserManagementRequest](https://github.com/symbiote-h2020/SymbIoTeSecurity/blob/develop/src/main/java/eu/h2020/symbiote/security/communication/payloads/UserManagementRequest.java) <ul><li>admin credentials // for operation authorization </li><li> user credentials // for operation authorization </li><li>user credentials (password to store new password) </li><li>user details (recovery mail, federated ID)</li></ul></div> | [ManagementStatus](https://github.com/symbiote-h2020/SymbIoTeSecurity/blob/develop/src/main/java/eu/h2020/symbiote/security/commons/enums/ManagementStatus.java) |
| <div> OperationType#DELETE  [UserManagementRequest](https://github.com/symbiote-h2020/SymbIoTeSecurity/blob/develop/src/main/java/eu/h2020/symbiote/security/communication/payloads/UserManagementRequest.java) <ul><li>admin credentials // for operation authorization</li><li> user credentials (username to find user in repository)</li></ul></div>                                                                                       | [ManagementStatus](https://github.com/symbiote-h2020/SymbIoTeSecurity/blob/develop/src/main/java/eu/h2020/symbiote/security/commons/enums/ManagementStatus.java) |
| <div> OperationType#FORCED_UPDATE  [UserManagementRequest](https://github.com/symbiote-h2020/SymbIoTeSecurity/blob/develop/src/main/java/eu/h2020/symbiote/security/communication/payloads/UserManagementRequest.java) mandatory fields<ul><li>admin credentials // for operation authorization</li><li>user credentials (username to resolve user, password to store new password)</li></ul></div> | [ManagementStatus](https://github.com/symbiote-h2020/SymbIoTeSecurity/blob/develop/src/main/java/eu/h2020/symbiote/security/commons/enums/ManagementStatus.java) |


## Test integrated resource

After our resource have been shared with Core we can test if we can find and access it properly.

### Search for resource

#### Searching by configurable query

To search for resource we need to create a query to the symbIoTe Core. In our example we use [https://core.symbiote.eu:8100/coreInterface/v1/query](http://core.symbiote.eu:8100/coreInterface/v1/) endpoint and provide parameters for querying. Requests need properly generated security headers. More on topic of secure access to symbIoTe component can be read on [SymbIoTeSecurity](https://github.com/symbiote-h2020/SymbIoTeSecurity) project page.

All possible query parameters can be seen below:

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
         resource_type:         String
}
```

**_NOTE 1:_**   To query using geospatial properties, all 3 properties need to be set: _location\_lat_ (latitude), _location\_long_ (longitude) and _max\_distance_ (distance from specified point in meters).

**_NOTE 2:_**   Text parameters allow substring searches using &#39;\*&#39; character which can be placed at the beginning and/or end of the word to search for. For example querying for name "_Sensor\*"_ finds all resources with name starting with _Sensor,_ and search for name "\*12\*" will find all resources containing string "12" in its name. Using substring search can be done for the following fields:

- name
- platform_name
- owner
- description
- location_name
- observed_property

For our example lets search for resources with name _Stationary 1_. We do it by sending a  _HTTP GET_ request on symbIoTe Core Interface ( [https://core.symbiote.eu:8100/coreInterface/v1/query?name=Stationary 1](http://core.symbiote.eu:8100/coreInterface/v1/query)). Response contains a list of resources fulfilling the criteria:

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
        "http://www.symbiote-h2020.eu/ontology/core#StationarySensor"
      ],
         "ranking": 0.5
         }
  ]
}
```

#### SPARQL query endpoint

Starting with Release 0.2.1, an additional endpoint was created to allow sending SPARQL queries to symbIoTe Core. To send SPARQL requests we need to send request by using _HTTP POST_ to the url: [https://core.symbiote.eu:8100/coreInterface/v1/sparqlQuery](http://core.symbiote.eu:8100/coreInterface/v1/)

The endpoint accepts the following payload:

```
{
  "sparqlQuery" : "<sparql>",
  "outputFormat" : "<format>"
}
```
Possible output formats include: SRX, **XML** , **JSON** , SRJ, SRT, THRIFT, SSE, **CSV** , TSV, SRB, **TEXT** , **COUNT, TUPLES, NONE, RDF, RDF\_N3, RDF\_XML, N3,** TTL **,** TURTLE ****,** GRAPH, NT, N\_TRIPLES, TRIG

SPARQL allows for powerful access to all the meta information stored within symbIoTe Core. Below you can find few example queries

- Query all resources of the core

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

- Query for Services and display information about input they are requiring: name and datatype

```
{
  "sparqlQuery" : "PREFIX cim: <http://www.symbiote-h2020.eu/ontology/core#> PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#> SELECT ?res ?resourceName ?inputName ?inputDatatype WHERE { ?res a cim:Service. ?res rdfs:label ?resourceName . ?res cim:hasInputParameter ?input . ?input cim:name ?inputName . ?input cim:datatype ?inputDatatype }",
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

### Obtaining resource access URL

To access the resource we need to ask symbIoTe Core for the access link. To do so we need to send _HTTP GET_ request on *https://core.symbiote.eu/coreInterface/v1/resourceUrls*, with ids of the resources as parameters. For our example, we want urls of 2 resources, so request looks like: *https://core.symbiote.eu/coreInterface/v1/resourceUrls?id=589dc62a9bdddb2d2a7ggab8,589dc62a9bdddb2d2a7ggab9*. To access the endpoint we need to specify security headers, as described in [SymbIoTeSecurity](https://github.com/symbiote-h2020/SymbIoTeSecurity)

#### Get the resource urls

If we provide correct ids of the resources along with a valid security credentials in the header, we will get a response containing URLs to access the resources:
```
{
  "589dc62a9bdddb2d2a7ggab8": "https://myplatform.eu:8102/rap/Sensor(&#39;589dc62a9bdddb2d2a7ggab8&#39;)",
  "589dc62a9bdddb2d2a7ggab9": "https://myplatform.eu:8102/rap/Sensor(&#39;589dc62a9bdddb2d2a7ggab9&#39;)"
}
```

### Accessing the resource and triggering fetching of our example data

In order to access the resources, you need to create a valid Security Request. For that, you can either integrate the Security Handler offered by the symbIoTe framework (implemented in Java) or develop a custom implementation for creating the Security Request. More information can be found in [SymbIoTeSecurity](https://github.com/symbiote-h2020/SymbIoTeSecurity) repository.

As stated previously, RAP can be configured to support different interfaces for accessing the data:

- OData
- REST

The applications can:

1. Read current value from resource
2. Read history values from resource
3. Write value into resource

#### OData access

1. _GET https://myplatform.eu:8102/rap/{Model}s('symbioteId')/Observations?$top=1_
2. _GET https://myplatform.eu:8102/rap/{Model}s('symbioteId')/Observations_
   Historical readings can be filtered, using the option _$filter._
   Operators supported:
   1. Equals
   2. Not Equals
   3. Less Than
   4. Greater Than
   5. And
   6. Or
3. _PUT_ _https://myplatform.eu:8102/__rap/{Model}s('serviceId')_   
    ***Request body:***   

    ```
    {
      "capability":
      [ 
        {
          "restriction1": “value1",
        },
        {
          "restriction2": “value2",
        },
        …
      ]
    }
    ```

The keyword _{Model}_ depends on the Information Model used to register devices: can be _Sensor_, _Actuator_, _Light_, _Curtain_, etc..
The same reasoning applies for _capability, restriction_ and _value._

#### REST access

1. _GET https://myplatform.eu:8102/rap/Sensor/{symbioteId}_
2. _GET https://myplatform.eu:8102/rap/Sensor/{symbioteId}/history_
3. _POST https://myplatform.eu:8102/rap/Service('symbioteId')_   
    ***Request body:***   
    
    ```
    {
      "capability":
      [ 
        {
          "restriction1": “value1",
        },
        {
          "restriction2": “value2",
        },
        …
      ]
    }
    ```
#### Push feature

Applications can receive notifications from resources, through SymbIoTe RAP WebSocket.
``
Client shall open a WebSocket connection towards a Server at

```
ws://IP:PORT/notification
```

, where IP and PORT are the Interworking Interface parameters.

To subscribe (or unsubscribe) to resources you have to send a message to the WebSocket specifying:
```
{
  "action": "SUBSCRIBE" / "UNSUBSCRIBE"
  "ids": ["id1", "id2", "id3", ...]
}
```
Afterwards notifications will be automatically received by the application from the WebSocket.

