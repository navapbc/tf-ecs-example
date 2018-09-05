
FROM node:8.9.4-alpine as packages

# Update packages on alpine
RUN apk upgrade --update-cache

# copy requirements
WORKDIR /var/app
COPY package*.json /var/app/

# Install npm dependencies supressing the output
RUN npm install --quiet

FROM node:8.9.4-alpine as development
COPY . /var/app
COPY --from=packages /var/app /var/app

WORKDIR /var/app

# run the app with parameter-store-exec
RUN apk update && apk add ca-certificates wget &&  update-ca-certificates &&\
  wget https://github.com/cultureamp/parameter-store-exec/releases/download/v1.0.0/parameter-store-exec-v1.0.0-linux-amd64.tar.gz &&\
  tar -xzpf parameter-store-exec-v1.0.0-linux-amd64.tar.gz && cp parameter-store-exec /
ENTRYPOINT [ "/parameter-store-exec" ]

CMD npm run start
