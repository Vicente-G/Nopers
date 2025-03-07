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

# Install NVM and Node12
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG NVM_GH=https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh
ENV BASH_ENV=/root/.bash_env
RUN touch "${BASH_ENV}"
RUN echo '. "${BASH_ENV}"' >> ~/.bashrc
RUN wget -qO- $NVM_GH | PROFILE="${BASH_ENV}" bash
RUN echo node > .nvmrc

# Fix and build Geocitizen
RUN git clone --depth 1 --single-branch \
    --branch master \
    https://github.com/nromanen/Ch-058

# Backend setup
WORKDIR /Ch-058
ARG DATABASE_URL
COPY ./docker/backend-config/config-fixes.sh ./
RUN chmod +x config-fixes.sh && ./config-fixes.sh $DATABASE_URL
RUN mvn clean install -DskipTests
RUN mvn liquibase:update -Dliquibase.promptOnNonLocalDatabase=false
RUN cp target/*.war /opt/tomcat/apache-tomcat-9.0.100/webapps/

# Frontend setup
WORKDIR /Ch-058/front-end
RUN nvm install 12
COPY ./docker/frontend-config ./
RUN npm install -D

ENV HOST=0.0.0.0
ENV PORT=8080
EXPOSE 8080
CMD ["/opt/tomcat/apache-tomcat-9.0.100/bin/catalina.sh", "run"]