# Build
FROM node:12.12.0-alpine AS build
RUN apk add --no-cache git
RUN git clone --depth 1 --single-branch \
    --branch master \
    https://github.com/nromanen/Ch-058
WORKDIR /Ch-058
COPY ./docker/frontend-config ./front-end/

# Run
FROM node:12.12.0-alpine AS run
COPY --from=build /Ch-058/front-end .
RUN npm install -D
ENV HOST=0.0.0.0
ENV PORT=8081
EXPOSE 8081
CMD ["npm", "run", "start"]
