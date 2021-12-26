FROM tomcat:9.0.56-jre11-openjdk-slim-buster

EXPOSE 8080

RUN rm -rf /usr/local/tomcat/webapps/*

RUN mv /usr/local/tomcat/webapps.dist/* /usr/local/tomcat/webapps/

COPY ./target/showcase-java-cloudrun-1.0-SNAPSHOT.war /usr/local/tomcat/webapps/mywar.war

CMD ["catalina.sh", "run"]