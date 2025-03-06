FROM ubuntu:16.04

# Install prerequisites
RUN apt-get update && apt-get install -y git wget

# Install NVM and Node12
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG NVM_GH=https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh
ENV BASH_ENV=/root/.bash_env
RUN touch "${BASH_ENV}"
RUN echo '. "${BASH_ENV}"' >> ~/.bashrc
RUN wget -qO- $NVM_GH | PROFILE="${BASH_ENV}" bash
RUN echo node > .nvmrc
RUN nvm install 12

# Fix and build Geocitizen
RUN git clone --depth 1 --single-branch \
    --branch master \
    https://github.com/nromanen/Ch-058
WORKDIR /Ch-058/front-end
COPY ./docker/frontend-config ./
RUN npm install -D

ENV HOST=0.0.0.0
ENV PORT=8081
EXPOSE 8081
CMD ["bash", "-c", "npm run start"]
