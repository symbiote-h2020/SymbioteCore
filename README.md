# symbIoTe Core

symbIoTe is a mediator, an intermediary connecting applications and IoT platforms. The basic functionality is that of a registry service which lists platforms, their resources and properties, while also providing an way to map between the platforms' different APIs. 


###Project Build & Deployment

To retrieve, build and deploy the project in either domain (Core/Cloud), the process is the following:

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
    * CoreConfigService, Eureka, Zipkin, Administration, Registry, Search, ResourceMonitor, ResourceAccessMonitor, CoreAuthenticationAuthorizationManager, CoreInterface, CloudCoreInterface, CoreSecurityHandler (TB addeed)
     
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

