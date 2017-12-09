
# Create a Apache TomEE 7.0.4 Plus S2I builder image for OpenShift CP v3.6+

## A. Creating the S2I builder image and testing it.

### Files and Directories  
| File                   | Required? | Description                                                  |
|------------------------|-----------|--------------------------------------------------------------|
| Dockerfile             | Yes       | Defines the base builder image                               |
| s2i/bin/assemble       | Yes       | Script that builds the application                           |
| s2i/bin/usage          | No        | Script that prints the usage of the builder                  |
| s2i/bin/run            | Yes       | Script that runs the application                             |
| s2i/bin/save-artifacts | No        | Script for incremental builds that saves the built artifacts |
| test/run               | No        | Test script for the builder image                            |
| test/test-app          | Yes       | Test application source code                                 |

#### Dockerfile
The *Dockerfile* installs all of the necessary tools and libraries that are needed to build and run a Java Web application on Apache TomEE v7.0.4 Plus appliction server.  Executing a docker build will produce an S2I builder image for the Apache TomEE v7.0.4 application server.  Both source and binary (war files) formats of the application are supported.  When a *pom.xml* file is present in the application source directory, **Apache Maven** will be used to build the application source code.  Alternatively, if a *build.gradle* file is present, **Gradle** will be used to build the application source.

#### S2I scripts

##### assemble
The *assemble* script executes the following steps:
1. Copies the application source code from */tmp/src* to the home directory of the container base image (tomee7-plus-centos7).  */opt/app-root/src* is the application **Source** directory and also the home directory of the container base image.
2. Checks the value of the environment variable *BUILD_TYPE*.  By default, the value of this variable is set to 'Maven'.  For executing 'Gradle' builds, the value of this enviroment variable should be set to 'Gradle'.
3. Checks if *pom.xml* file exists in **Source** directory. If the file exists and *BUILD_TYPE* is set to 'Maven', a Maven Build is executed.  If the Maven build succeeds (returns 0) then the built application binary (.war) file is copied to the Apache TomEE webapps directory */usr/local/tomee/webapps*. A new image containing both the built application and the application runtime (Apache TomEE) are committed and saved as the *application container image*.
4. Checks if *build.gradle* file exists in **Source** directory. If the file exists and *BUILD_TYPE* is set to 'Gradle', then a Gradle Build is executed.  If the Gradle build succeeds (returns 0) then the built application binary (.war) file is copied to the Apache TomEE webapps directory */usr/local/tomee/webapps*.  A new image containing both the built application and the application runtime (Apache TomEE) are committed and saved as the *application container image*.
5. If the application build fails in steps 3 or 4, then an error message is returned and execution is stopped. In this case, no *application container image* is created.
6. If a *pom.xml* or *build.gradle* file does not exist in the **Source** directory then the contents of this directory is assumed to contain application binaries (war, ear files).  These files will be copied to the Apache TomEE webapps directory */usr/local/tomee/webapps*.  Finally, a new container image containing both the application binaries and application server runtime (Apache TomEE) will be committed and saved as a new *application container image*.

The script also restores any saved artifacts from the previous image build.   

##### run
The *run* script is used to start the application server runtime (Apache TomEE).

##### save-artifacts (optional)
The *save-artifacts* script allows a new build to reuse content (dependencies) from a previous version of the application image.

##### usage (optional) 
The *usage* script prints out instructions on how to use the Apache TomEE S2I builder image in order to produce an **application container image**.

#### Create the Apache TomEE v7.0.4 Plus S2I builder image
The following command will create a S2I builder image named tomee7-plus-centos7 based on the Dockerfile.
```
docker build -t tomee7-plus-centos7 .
```
The builder image can also be created by invoking the *make* command.  A *Makefile* is included.

The command *s2i usage tomee7-plus-centos7* will print out the help info defined in the *usage* script.

#### Testing the S2I builder image
The builder image can be tested using the following commands:
```
docker build -t tomee7-plus-centos7-candidate .
IMAGE_NAME=tomee7-plus-centos7-candidate test/run
```
The builder image can also be tested by using the *make test* command since a *Makefile* is included.

#### Creating the application container image
The application container image combines the builder image with application source code, which is served using application server (Apache TomEE) installed via the *Dockerfile*, compiled using the *assemble* script, and run using the *run* script.
The following command will create the application container image:

**Usage:**
```
s2i build <location of source code> <S2I builder image name> <application container image name>
```

```
s2i build test/test-app tomee7-plus-centos7 tomee7-jaxrs-app
---> Building and installing application from source...
```
Based on the logic defined in the *assemble* script, s2i will create an application container image using the supplied S2I builder image as a base image and the application source code from the *test/test-app* directory. 

#### Running the application container image
Running the application image is as simple as invoking the docker run command:
```
docker run -d -p 8080:8080 tomee7-jaxrs-app
```
The application, should now be accessible at  [http://localhost:8080](http://localhost:8080).

#### Using the saved artifacts script
Rebuilding the application using the saved artifacts can be accomplished using the following command:
```
s2i build --incremental=true test/test-app tomee7-plus-centos7 tomee7-jaxrs-app
---> Restoring build artifacts...
---> Building and installing application from source...
```
This will run the *save-artifacts* script which includes the code to backup the currently running application dependencies. When the application container image is built next time, the saved application dependencies will be re-used to build the application.

## B. Using the Apache TomEE Plus S2I builder image in OpenShift CP

1.  Use the command below to create the S2I builder image and save it in the integrated docker registry.  The command below creates the image in the *openshift* project to allow all projects to consume the image.

```
oc new-build --strategy=docker --name=tomee7-plus-centos7 https://github.com/ganrad/openshift-s2i-tomee7-wp-jdk8.git -n openshift
```

2.  Download the *tomee7-plus-centos7.json* file from this repository and save it on your local machine where you have OpenShift CLI tools (oc binary) installed. Then use the command below to upload the template into your current project/namespace.

```
oc create -f tomee7-plus-centos7.json
```

3.  Click on 'Add to Project' in OpenShift CP Web Console (UI) to create a new application and then select the 'tomee7-plus-centos7' template from the 'Browse' images tab.  You will then be presented with a form where you can specify 
* A name for your web application and 
* The GitHub repository URL containing your Java web application source code.

    Next, click on 'Create' application.  This will invoke the *S2I process* which will build your application, containerize your application (as explained above), push the newly built image into the integrated docker registry and finally deploy a Pod containing your application.

Congrats!  You have now successfully created your own S2I builder image for building and deploying containerized Java web applications on Apache TomEE application server running on OpenShift CP.
