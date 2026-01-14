FROM maven:3.9.9-eclipse-temurin-21 AS backend-builder

COPY . /build
WORKDIR /build
RUN mvn clean package -Dmaven.test.skip=true
WORKDIR /build/target
RUN mv wvp-pro-*.jar wvp.jar


FROM node:16-bullseye-slim AS frontend-builder

COPY . /build
WORKDIR /build/web
RUN npm config set registry https://registry.npmmirror.com \
  && npm install \
  && npm run build:prod


FROM nginx:stable

ARG TZ=Asia/Shanghai
ENV TZ=${TZ}

RUN apt-get update \
  && apt-get install -y --no-install-recommends openjdk-21-jre-headless ca-certificates tzdata \
  && rm -rf /var/lib/apt/lists/* \
  && rm -f /etc/nginx/conf.d/default.conf

RUN mkdir -p /opt/wvp /opt/dist /opt/ylcx/wvp
WORKDIR /opt/wvp

# backend
COPY --from=backend-builder /build/target/wvp.jar /opt/wvp/wvp.jar
COPY ./docker/wvp/wvp/ /opt/ylcx/wvp/

# frontend (vue.config.js outputDir -> src/main/resources/static)
COPY --from=frontend-builder /build/src/main/resources/static/ /opt/dist/

# nginx template (rendered by nginx official entrypoint)
COPY ./docker/nginx/templates/nginx.conf.template /etc/nginx/templates/nginx.conf.template

# start java app before nginx
COPY ./docker/wvp/docker-entrypoint.d/10-wvp.sh /docker-entrypoint.d/10-wvp.sh
RUN chmod +x /docker-entrypoint.d/10-wvp.sh

EXPOSE 18978/tcp
EXPOSE 8116/tcp
EXPOSE 8116/udp
EXPOSE 8080/tcp
