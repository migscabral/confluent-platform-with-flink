# Download Confluent Platform charts, container images, and Connector packages

Follow the steps below to downloand Confluent Platform charts, container images, and Connector packages.

## Download helm charts

1. Pull the helm charts.

```
cd <your-project-local-dir>
mkdir confluent-charts
cd confluent-charts

helm pull confluentinc/confluent-for-kubernetes --version 0.1718.10
helm pull confluentinc/flink-kubernetes-operator --version 1.150.3
helm pull confluentinc/confluent-manager-for-apache-flink --version 2.4.2
```

2. Verify the downloaded charts.

```
for chart in ./*.tgz; do 
  helm show chart "$chart"
  helm show crds "$chart" >/dev/null || true
  helm dependency list "$chart" || true
done
```

3. Upload the charts to your private helm repo.

## Download container images

1. Pull the container images.

```
images=(
  "confluentinc/confluent-operator:0.1718.10"
  "confluentinc/confluent-init-container:3.3.0"
  "confluentinc/cp-flink-kubernetes-operator:1.15.0-cp3"
  "confluentinc/cp-cmf:2.4.2"
  "confluentinc/cp-server:8.3.1"
  "confluentinc/cp-server-connect:8.3.1"
  "confluentinc/cp-schema-registry:8.3.1"
  "confluentinc/cp-enterprise-control-center-next-gen:2.5.0"
  "confluentinc/cp-flink:2.2.0-cp2-java21"
  "confluentinc/confluent-observer-container:3.3.0"
)
for image in "${images[@]}"; do
  docker pull "$image"
done
```

2. Verfiy the downloaded images.

```
for image in "${images[@]}"; do
  docker inspect "$image"
done

```

3. Upload the images to your private container registry.


## Download the Connector packages

1. Download the Connector packages

```
cd <your-project-local-dir>
mkdir confluent-connector-packages
cd confluent-connector-packages

curl -O https://hub-downloads.confluent.io/api/plugins/confluentinc/kafka-connect-jdbc/versions/10.9.9/confluentinc-kafka-connect-jdbc-10.9.9.zip
curl -O https://hub-downloads.confluent.io/api/plugins/mongodb/kafka-connect-mongodb/versions/3.1.0/mongodb-kafka-connect-mongodb-3.1.0.zip
curl -O https://hub-downloads.confluent.io/api/plugins/confluentinc/kafka-connect-s3/versions/12.1.11/confluentinc-kafka-connect-s3-12.1.11.zip
```

2. Upload to your private artifact repository (e.g. Nexus, Atrifactory, or a regular HTTP server).

3. Download the MySQL JDBC driver at https://dev.mysql.com/downloads/connector/j/
    - Select the latest version
    - Select "Platform Independent" from the Operating System option, then download.

4. Transfer the downloaded JDBC driver to the bastion host. This will be referenced later when applying the CRDs in OCP. 



