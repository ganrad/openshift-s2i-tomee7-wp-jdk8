# s2i-java : ID:11-13-2017
#
# ID:12-05-2017:
# Updated the following :
# 1. Updated the Apache TomEE runtime from TomEE 7.0.3 WP to TomEE Plus 7.0.4 profile
# 2. Introduced parameter variable (BUILD_TYPE) to allow users to specify build type - Maven or Gradle
# 3. In addition to Maven build runtime, this image now also contains Gradle build runtime
# 4. Changed name from 'tomee7-wp-centos7' to 'tomee7-plus-centos7'
#
# tomee7-plus-centos7
#
FROM openshift/base-centos7
MAINTAINER Ganesh Radhakrishnan ganrad01@gmail.com
# HOME in base image is /opt/app-root/src

# Builder version
ENV BUILDER_VERSION 1.0

LABEL io.k8s.description="Platform for building Java Web apps (WAR) with Maven or Gradle and deploying on Apache Tomee 7 application server." \
      io.k8s.display-name="Tomitribe Tomee 7.0.4 Plus on OpenJDK 8" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="Java,JEE,Tomcat,builder"

# Install required util packages.
RUN yum -y update; \
    yum install tar -y; \
    yum install unzip -y; \
    yum install ca-certificates -y; \
    yum install sudo -y; \
    yum clean all -y

# Install OpenJDK 1.8, create required directories.
RUN yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel && \
    yum clean all -y && \
    mkdir -p /usr/local/tomee && chmod -R a+rwX /usr/local/tomee && \
    mkdir -p /opt/app-root/src && chmod -R a+rwX /opt/app-root/src

# Install Maven 3.5.2
ENV MAVEN_VERSION 3.5.2
RUN (curl -fSL http://ftp.wayne.edu/apache/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | \
    tar -zx -C /usr/local) && \
    mv /usr/local/apache-maven-$MAVEN_VERSION /usr/local/maven && \
    ln -sf /usr/local/maven/bin/mvn /usr/local/bin/mvn && \
    mkdir -p $HOME/.m2 && chmod -R a+rwX $HOME/.m2

# Install Gradle 4.4
ENV GRADLE_VERSION 4.4
RUN curl -fSL https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip -o /tmp/gradle-$GRADLE_VERSION-bin.zip && \
    unzip /tmp/gradle-$GRADLE_VERSION-bin.zip -d /usr/local/ && \
    rm /tmp/gradle-$GRADLE_VERSION-bin.zip && \
    mv /usr/local/gradle-$GRADLE_VERSION /usr/local/gradle && \
    ln -sf /usr/local/gradle/bin/gradle /usr/local/bin/gradle && \
    mkdir -p $HOME/.gradle && chmod -R a+rwX $HOME/.gradle

# Set the location of the mvn and gradle binaries on search path
ENV PATH=/usr/local/bin/mvn:/usr/local/bin/gradle:$PATH

# Set the default build type to 'Maven'
ENV BUILD_TYPE=Maven

# Install Apache TomEE 7.0.4 Plus
ENV TOMEE_VERSION 7.0.4
RUN (curl -fSL https://repo.maven.apache.org/maven2/org/apache/tomee/apache-tomee/$TOMEE_VERSION/apache-tomee-$TOMEE_VERSION-plus.tar.gz | tar -zx -C /usr/local/tomee) \
        && mv /usr/local/tomee/apache-tomee-plus-$TOMEE_VERSION/* /usr/local/tomee \
	&& rm -Rf /usr/local/tomee/apache-tomee-plus-$TOMEE_VERSION \
	&& rm /usr/local/tomee/bin/*.bat

# Set Catalina home
ENV CATALINA_HOME /usr/local/tomee

# Copy the S2I scripts to /usr/libexec/s2i, since openshift/base-centos7 image
# sets io.openshift.s2i.scripts-url label that way, or update that label
COPY ./s2i/bin/ /usr/libexec/s2i

# Drop the root user and make the content of /opt/app-root owned by user 1001
RUN chown -R 1001:1001 /opt/app-root /usr/local/tomee

# This default user is created in the openshift/base-centos7 image
USER 1001

# Set the default port for applications built using this image
EXPOSE 8080

# Set the default CMD for the image
CMD ["/usr/libexec/s2i/usage"]
