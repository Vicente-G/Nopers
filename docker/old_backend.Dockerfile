# Build
FROM maven:3-openjdk-8-slim AS build
RUN apt-get update && apt-get install -y git
RUN git clone --depth 1 --single-branch \
    --branch master \
    https://github.com/nromanen/Ch-058
WORKDIR /Ch-058
ARG DATABASE_URL
COPY ./docker/backend-config/config-fixes.sh ./
RUN chmod +x config-fixes.sh && ./config-fixes.sh $DATABASE_URL
RUN mvn clean install -DskipTests
# Couldn't run liquibase update yet

# Run
FROM tomcat:9-jre8-alpine AS run
COPY --from=build /Ch-058/target/*.war /usr/local/tomcat/webapps/
COPY --from=build /Ch-058/target/classes/liquibase /usr/share/liquibase
EXPOSE 8080
CMD ["catalina.sh", "run"]
