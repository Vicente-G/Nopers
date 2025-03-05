FROM ubuntu:16.04

# Install prerequisites
RUN apt-get update && apt-get install -y git wget openjdk-8-jdk

# Setup Maven 3
RUN wget https://dlcdn.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz
RUN tar -xvzf apache-maven-3.9.9-bin.tar.gz && rm apache-maven-3.9.9-bin.tar.gz
RUN mv apache-maven-3.9.9 /opt/maven
RUN update-alternatives --install /usr/bin/mvn mvn /opt/maven/bin/mvn 1
RUN update-alternatives --config mvn

# Setup Tomcat 9
RUN mkdir -p /opt/tomcat && groupadd tomcat
RUN useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat
RUN wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.100/bin/apache-tomcat-9.0.100.tar.gz
RUN tar -xvf apache-tomcat-9.0.100.tar.gz && rm apache-tomcat-9.0.100.tar.gz
RUN mv apache-tomcat-9.0.100 /opt/tomcat
RUN chown -RH tomcat: /opt/tomcat
RUN sh -c 'chmod +x /opt/tomcat/apache-tomcat-9.0.100/bin/*.sh'

# Fix and build Geocitizen
RUN git clone --depth 1 --single-branch \
    --branch master \
    https://github.com/nromanen/Ch-058
WORKDIR /Ch-058
ARG DATABASE_URL
COPY ./docker/backend-config/config-fixes.sh ./
RUN chmod +x config-fixes.sh && ./config-fixes.sh $DATABASE_URL
RUN mvn clean install -DskipTests
RUN mvn liquibase:update -Dliquibase.promptOnNonLocalDatabase=false
RUN cp target/*.war /opt/tomcat/apache-tomcat-9.0.100/webapps/

EXPOSE 8080
CMD ["/opt/tomcat/apache-tomcat-9.0.100/bin/catalina.sh", "run"]