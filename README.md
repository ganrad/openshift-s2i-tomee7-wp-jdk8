
# Creating a Apache TomEE 7.0.3 Web Profile S2I builder image  

## Getting started  

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
The *Dockerfile* installs all of the necessary tools and libraries that are needed to build and run a Java Web application on Apache TomEE v7.0.3 Web Profile appliction server.  Both source and binary (war files) formats of the application code are supported.  Executing a docker build will produce an S2I builder image for the Apache TomEE v7.0.3 Web Profile application server.

#### S2I scripts

##### assemble
The *assemble* script executes the following steps:
1. Copies the source code from /tmp/src to the home directory (/opt/app-root/src).  This is the application **Source** directory and also the home directory of the container base image (tomee7-wp-jdk8).
2. Checks if Maven pom.xml file exists in **Source** directory. If the file exists, a Maven Build is executed.  If the Maven build succeeds (returns 0) then the built application binary (.war) file is copied to the Apache TomEE webapps directory (/usr/local/tomee/webapps). The **application container image** containing both the built application and the application runtime (Apache TomEE) are committed and saved as a new container image.  Alternatively, if the application build fails, an error message is returned and execution is stopped. In this case, no application container image is created.
3. If a Maven pom.xml file doesn't exist in the **Source** directory then the contents of this directory are assumed to container application binaries (war files).  These files will be copied to the Apache TomEE webapps directory (/usr/local/tomee/webapps).  Finally, the **application container image** containing both the application binaries and application server runtime (Apache TomEE) will be committed and saved as a new container image.

The script also restores any saved artifacts from the previous image build.   

##### run
The *run* script is used to start the application server runtime (Apache TomEE).

##### save-artifacts (optional)
The *save-artifacts* script allows a new build to reuse content (dependencies) from a previous version of the application image.

##### usage (optional) 
The *usage* script prints out instructions on how to use the Apache TomEE S2I builder image in order to produce an **application container image**.

#### Create the S2I builder image
The following command will create a S2I builder image named tomee7-wp-jdk8 based on the Dockerfile.
```
docker build -t tomee7-wp-jdk8 .
```
The builder image can also be created by invoking the *make* command.  A *Makefile* is included.

The command *s2i usage tomee7-wp-jdk8* will print out the help info defined in the *usage* script.

#### Testing the S2I builder image
The builder image can be tested using the following commands:
```
docker build -t tomee7-wp-jdk8-candidate .
IMAGE_NAME=tomee7-wp-jdk8-candidate test/run
```
The builder image can also be tested by using the *make test* command since a *Makefile* is included.

#### Creating the application container image
The application container image combines the builder image with application source code, which is served using application server (Apache TomEE) installed via the *Dockerfile*, compiled using the *assemble* script, and run using the *run* script.
The following command will create the **application container image**:
**Usage: s2i build <location of source code> <S2I builder image name> <application container image name>**
```
s2i build test/test-app tomee7-wp-jdk8 tomee7-wp-jdk8-app
---> Building and installing application from source...
```
Based on the logic defined in the *assemble* script, s2i will create an application container image using the supplied S2I builder image as a base image and theapplication source code from the test/test-app directory. 

#### Running the application container image
Running the application image is as simple as invoking the docker run command:
```
docker run -d -p 8080:8080 tomee7-wp-jdk8-app
```
The application, should now be accessible at  [http://localhost:8080](http://localhost:8080).

#### Using the saved artifacts script
Rebuilding the application using the saved artifacts can be accomplished using the following command:
```
s2i build --incremental=true test/test-app tomee7-wp-jdk8 tomee7-wp-jdk8-app
---> Restoring build artifacts...
---> Building and installing application from source...
```
This will run the *save-artifacts* script which includes the code to backup the currently running application dependencies. When the application container imageis built next time, the saved application dependencies will be re-used to build the application.
