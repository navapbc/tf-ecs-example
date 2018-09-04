FROM node:8

# Create app directory
WORKDIR /usr/src/app

# Install app dependencies
COPY package*.json ./

RUN npm install

# Bundle app source
COPY . .

EXPOSE 3000

# run the app with parameter-store-exec
RUN apk update && apk add ca-certificates wget &&  update-ca-certificates &&\
  wget https://github.com/cultureamp/parameter-store-exec/releases/download/v1.0.0/parameter-store-exec-v1.0.0-linux-amd64.tar.gz &&\
  tar -xzpf parameter-store-exec-v1.0.0-linux-amd64.tar.gz && cp parameter-store-exec /
ENTRYPOINT [ "/parameter-store-exec" ]

CMD [ "npm", "start" ]
