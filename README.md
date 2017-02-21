# symbIoTe Core

symbIoTe is a mediator, an intermediary connecting applications and IoT platforms. The basic functionality is that of a registry service which lists platforms, their resources and properties, while also providing an way to map between the platforms' different APIs. 


###Project Build & Deployment

To retrieve, build and deploy the project, the process is the following:

 - Install RabbitMQ server:
  * RabbitMQ is a message queue framework (uses AMQP) that lets our services exchange informations and events.
  * After installation RabbitMQ server should be active in the background without necessity to start it every time you want to run the project.
  * Details: https://www.rabbitmq.com/download.html  (step by step with APT for Ubuntu/Debian)

 - Install MongoDB server:
  * Before you can launch the project, MongoDB server has to be up and running on your machine.
  * It stores the data in the default directory: '/data/db', which (if it does not exist yet) you have to create before launching the server. You can remove all of its contents if you want to rerun clean project.
  * After executing, Mongo server should show status 'waiting for connections on port 27017'.
  * Details: https://www.mongodb.com/download-center  (step by step with APT for Ubuntu/Debian)

 - Clone the Config Properties repository:
  * git clone the CoreConfigProperties repo to directory: `"{user.home}/git/symbiote/"`  (or any other you want, just make sure to change the path in CoreConfigService bootstrap.properties)
  
 - Clone the rest of the components:
  * If you just want to deploy but not develop/commit any changes, you can get all components straight from the superproject:
   `git clone --recursive https://github.com/symbiote-h2020/SymbioteCore.git`
  * If you want to download the repos for development purposes, you need to clone them individually into separate folders
   * For the symbIoTe Core you need the components:
    * CoreConfigService, Eureka, Zipkin, Administration, Registry, Search, CoreResourceMonitor, CoreResourceAccessMonitor, CoreAuthenticationAuthorizationManager, CoreInterface, CloudCoreInterface, CoreSecurityHandler (To be addeed)
     
 - Build the components:
  * Remember to change the path in ConfigService bootstrap.properties if you have changed the ConfigProperties location
  * Build everything using gradle:
    `gradle build`  (or `gradle build -x test` to skip tests)
  * Resulting jars are in build/libs directory
  * To execute the compiled jars, do:
    `java -jar build/libs/<component_name>.jar`

 - Run the services in order:
  * Run ConfigService first
  * Run EurekaService second
  * Run ZipkinService third
  * Run all remaining components in whichever order you like
  * Check that they were deployed successfully in the Eureka panel: localhost:8761/

##3. Accessing a resource

An application can use a resource by following these steps:

 1. Search for resource

  To search for resource we need to create a query to the symbIoTe Core. In our example we use http://core.symbiote.eu:8100/coreInterface/v1/query endpoint and provide parameters for query. All possible query parameters can be seen below:
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
  }
  ```
  #####NOTES:
   - To query using geospatial properties, all 3 properties need to be set: location_lat (latitude), location_long (longitude) and max_distance (distance from specified point in meters).
   - Text parameters allow substring searches using '*' character which can be placed at the beginning and/or end of the word to search for. For example querying for name: Sensor* finds all resources with name starting with Sensor, and search for name: *12* will find all resources containing string "12" in its name. Using substring search can be done for the following fields:
     - name
     - platform_name
     - owner
     - description
     - location_name
     - observed_property

  For our example lets search for resources with name *Sensor1*. We can do this by sending an HTTP GET request on symbIoTe Core Interface: http://core.symbiote.eu:8100/coreInterface/v1/query?name=Sensor1. Response contains a list of resources fulfilling the criteria:

  ```
  [
    {

      "platformId": "589c783a9bdddb2d2a7gea92",

      "platformName": "PlatformA",

      "owner": "PlatformAOwner",

      "name": "Sensor1",

      "id": "589dc62a9bdddb2d2a7ggab8",

      "description": "This is a test sensor",

      "locationName": "Poznan",

      "locationLatitude": 52.42179,

      "locationLongitude": 16.940144,

      "locationAltitude": 100,

      "observedProperties": [

        "Temperature"

      ]
      
    }
  ]
  ```
 
 2. Obtaining resource access URL

  To access the resource we need to ask symbIoTe Core for the access link. To do this,  we need to send an HTTP GET request on http://core.symbiote.eu:8100/coreInterface/v1/resourceUrls?id=589dc62a9bdddb2d2a7ggab8

  If we provided the correct id of the resource, we will get a response containing the URL to access the resource:
  ```
  {
    "589dc62a9bdddb2d2a7ggab8": "http://myplatform.eu:8101/rap/Sensor('589dc62a9bdddb2d2a7ggab8')"
  }
  ```
  
 3. Accessing the resource and triggering fetching of our example data

  For an application to access the URL link retrieved from the previous step, it has to send an HTTP GET request to the *Interworking Interface* of the platform, which forwards the access request to the RAP component. RAP searches for the a resource with the *internal id* specified in the URL. The method  created in section 2.1 is then called to retrieve the value of the resource.

  `HTTP GET` on http://myplatform.eu:8101/rap/Sensor('589dc62a9bdddb2d2a7ggab8') results in:

  ```
  {
    "headers": {
      "X-Application-Context": [
        "ResourceAccessProxy:8100"
      ],
      "Content-Type": [
        "application/json;charset=UTF-8"
      ],
      "Transfer-Encoding": [
        "chunked"
      ],
      "Date": [
        "Wed, 15 Feb 2017 14:12:49 GMT"
      ]
    },
    "body": {
      "resultTime": 1487167969540,
      "resourceId": "symbIoTeID1",
      "samplingTime": 1487167968540,
      "location": {
        "longitude": 16.940144,
        "latitude": 52.42179,
        "altitude": 100,
        "name": "Poznan",
        "description": "Poznan test"
      },
      "obsValue": {
        "value": 7,
        "obsProperty": {
          "label": "Temperature",
          "comment": "Air temperature"
        },
        "uom": {
          "symbol": "C",
          "label": "degree Celsius",
          "comment": null
        }
      }
    },
    "statusCode": "OK",
    "statusCodeValue": 200
  }
  ```
