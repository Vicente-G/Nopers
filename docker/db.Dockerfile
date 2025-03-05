FROM postgres:10.23-alpine

ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres
ENV POSTGRES_HOST_AUTH_METHOD=md5

EXPOSE 5432
CMD ["postgres", "-c", "listen_addresses=*"]
