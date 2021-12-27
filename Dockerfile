# Pull the base image
FROM tomcat:9.0.53-jdk11-temurin

# Remove Tomcat's default app
RUN rm -rf /usr/local/tomcat/webapps/ROOT

# Define the default app
COPY ./target/showcase-java-cloudrun-1.0-SNAPSHOT.war /usr/local/tomcat/webapps/ROOT.war

## GCP credentials to authenticate to Cloud SQL (to run Docker container locally)
#COPY  PATH_TO_CREDENTIALS/key.json /usr/local/tomcat/webapps/key.json
#ENV GOOGLE_APPLICATION_CREDENTIALS="/usr/local/tomcat/webapps/key.json"

# Expose port for listening
EXPOSE 8080

# Run Tomcat
CMD ["/usr/local/tomcat/bin/catalina.sh", "run"]