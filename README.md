# Connecting a Cloud Run service to Cloud SQL for PostgreSQL via Private IP

A sample Java servlet with Tomcat for Cloud Run connecting to Cloud SQL instance. Based on the
official GCP [sample](https://github.com/GoogleCloudPlatform/java-docs-samples/tree/main/cloud-sql/postgres/servlet).


## Prerequisites

 - GCP project
 - JDK 11+
 - Maven 3.6+
 - Docker


## Before you begin

1. Make sure that you have the following APIs enabled in your GCP project:

    - Compute Engine API
    - Cloud SQL Admin API
    - Cloud Run API
    - Container Registry API
    - Cloud Build API

2. Create a [Serverless VPC Connector](https://cloud.google.com/vpc/docs/configure-serverless-vpc-access#create-connector)
   for connect to the instance's Private IP.

3. Create a 2nd Gen Cloud SQL instance for PostgreSQL with Private IP by following these
   [instructions](https://cloud.google.com/sql/docs/postgres/quickstart-cloud-run#expandable-2).

4. Create a [database](https://cloud.google.com/sql/docs/postgres/quickstart-cloud-run#create-instance) and
   a [user](https://cloud.google.com/sql/docs/postgres/quickstart-cloud-run#create_a_user) for your servlet.

5. Create a service account with the 'Cloud Run Developer', 'Cloud SQL Client', 'Storage Admin' and
   'Service Account User' roles. Download a JSON key to use to authenticate your connection. Alternatively, configure the
   service account used by Cloud Run.


## Local Build

Run the following command inside the project folder to generate a WAR for this servlet:

    mvn clean package -DskipTests


## Local Run - Limitations

The following instructions for local runs will work for a Cloud SQL instance that has **a public IP** address. 
If your Cloud SQL instance has only a private IP enabled, consider the following options:

- Temporarily enable public IP to test the servlet.
- Move your local development environment to the same VPC network (e.g. to a GCE VM).
- Look into [connecting from an external source](https://cloud.google.com/sql/docs/postgres/configure-private-ip#vpn).

## Local Run - Tomcat

1. Running the servlet locally with Tomcat plugin:

       mvn tomcat7:run -DskipTests

3. Navigate towards http://127.0.0.1:8080 to verify your servlet is running correctly.


## Local Run - Docker

1. Uncomment the following lines in the Dockerfile to be able to access your Cloud SQL instance from the container. 
   Update the path to your Service Account credentials `PATH_TO_CREDENTIALS/key.json`. 

       ## GCP credentials to authenticate to Cloud SQL (to run Docker container locally)
       #COPY  PATH_TO_CREDENTIALS/key.json /usr/local/tomcat/webapps/key.json
       #ENV GOOGLE_APPLICATION_CREDENTIALS="/usr/local/tomcat/webapps/key.json"

2. To build and tag the Docker image, run the following command inside the project folder:

       docker build -t [DOCKER_IMAGE_TAG] .

3. Running the Docker container:

   ```sh
   docker run -d -p 9090:8080 \
   -e INSTANCE_CONNECTION_NAME="[CLOUDSQL_CONNECTION_NAME]" \
   -e DB_USER="[CLOUDSQL_USERNAME]" \
   -e DB_PASS="[CLOUDSQL_PASSWORD]" \
   -e DB_NAME="[CLOUDSQL_DATABASE]" \
   [DOCKER_IMAGE_TAG]
   ```

4. Navigate towards http://127.0.0.1:9090 to verify your servlet is running correctly.


## Deploy to Cloud Run

1. Run the following command inside the project folder to generate a WAR for this servlet:

       mvn clean package -DskipTests

2. Build and tag the Docker image:

       docker build -t [GCR_HOSTNAME]/[GCP_PROJECT_ID]/[IMAGE_NAME]:[IMAGE_TAG] .

   *E.g. `docker build -t eu.gcr.io/my-project/gcr-image:0.1 .`*

4. To push the image to GCR, run:

       docker push [GCR_HOSTNAME]/[GCP_PROJECT_ID]/[IMAGE_NAME]:[IMAGE_TAG]

5. Deploy to Cloud Run:
    ```sh
    gcloud run deploy [CLOUDRUN_SERVICE_NAME] --image [GCR_HOSTNAME]/[GCP_PROJECT_ID]/[IMAGE_NAME]:[IMAGE_TAG] \
      --add-cloudsql-instances [CLOUDSQL_CONNECTION_NAME] \
      --set-env-vars INSTANCE_CONNECTION_NAME="[CLOUDSQL_CONNECTION_NAME]" \
      --set-env-vars CLOUD_SQL_CONNECTION_NAME="[CLOUDSQL_CONNECTION_NAME]" \
      --set-env-vars DB_NAME="[CLOUDSQL_DATABASE]" \
      --set-env-vars DB_USER="[CLOUDSQL_USERNAME]" \
      --set-env-vars DB_PASS="[CLOUDSQL_PASSWORD]" \
      --set-env-vars DB_HOST="[CLOUDSQL_PRIVATE_IP]" \
      --set-env-vars DB_PORT="5432" \
      --vpc-connector="[VPC_CONNECTOR_NAME]" \
      --region [REGION_OF_VCP_CONNECTOR] \
      --allow-unauthenticated
    ```
   Set correct values for environment variables to match your Cloud SQL instance configuration.

Take note of the URL output at the end of the deployment process.

**Note:** Saving credentials in environment variables is convenient, but not secure - consider a more
secure solution such as [Cloud KMS](https://cloud.google.com/kms/) to help keep secrets safe.


---


It is recommended to use the [Secret Manager integration](https://cloud.google.com/run/docs/configuring/secrets)
for Cloud Run instead of using environment variables for the SQL configuration. The service injects the SQL
credentials from Secret Manager at runtime via an environment variable.

Create secrets via the command line:
  ```sh
  echo -n "my-project:us-central1:my-cloud-sql-instance" | \
      gcloud secrets versions add CLOUDSQL_CONNECTION_NAME_SECRET --data-file=-
  ```

Deploy the service to Cloud Run specifying the env var name and secret name:
  ```sh
  gcloud beta run deploy [CLOUDRUN_SERVICE_NAME] --image [GCR_HOSTNAME]/[GCP_PROJECT_ID]/[IMAGE_NAME]:[IMAGE_TAG] \
      --add-cloudsql-instances [CLOUDSQL_CONNECTION_NAME] \
      --update-secrets INSTANCE_CONNECTION_NAME=[CLOUDSQL_CONNECTION_NAME_SECRET]:latest,\
        CLOUD_SQL_CONNECTION_NAME=[CLOUDSQL_CONNECTION_NAME_SECRET]:latest \
        DB_USER=[CLOUDSQL_USERNAME_SECRET]:latest, \
        DB_PASS=[CLOUDSQL_PASSWORD_SECRET]:latest, \
        DB_NAME=[CLOUDSQL_DATABASE_SECRET]:latest \
        DB_HOST=[CLOUDSQL_PRIVATE_IP_SECRET]:latest \
        DB_PORT=[DB_PORT_SECRET]:latest \
      --vpc-connector="[VPC_CONNECTOR_NAME]" \
      --region [REGION_OF_VCP_CONNECTOR] \
      --allow-unauthenticated
  ```


## Relevant Documentation

- [Quickstart for Cloud SQL and Cloud Run](https://cloud.google.com/sql/docs/postgres/quickstart-cloud-run)
- [Connecting from Cloud Run to Cloud SQL](https://cloud.google.com/sql/docs/postgres/connect-run)
- [Configuring Serverless VPC Access](https://cloud.google.com/vpc/docs/configure-serverless-vpc-access)
- [Cloud SQL - Private IP](https://cloud.google.com/sql/docs/postgres/private-ip)
- [General best practices for Cloud SQL](https://cloud.google.com/sql/docs/postgres/best-practices)
- [Managing database connections](https://cloud.google.com/sql/docs/postgres/manage-connections)
- [Cloud SQL - Overview to connecting](https://cloud.google.com/sql/docs/postgres/connect-overview)