# Pull the base image
FROM tomcat:9.0.56-jre11-openjdk-slim-buster

# Remove Tomcat's default app
RUN rm -rf /usr/local/tomcat/webapps/ROOT

# Define the default app
COPY ./target/showcase-java-cloudrun-1.0-SNAPSHOT.war /usr/local/tomcat/webapps/ROOT.war

# Expose port for listening
EXPOSE 8080

# Run Tomcat
CMD ["/usr/local/tomcat/bin/catalina.sh", "run"]