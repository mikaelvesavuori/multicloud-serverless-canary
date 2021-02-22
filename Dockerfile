FROM node:14-alpine

WORKDIR /gcp/src
COPY ./gcp/src .
RUN npm install --only=production
EXPOSE 8080
CMD npm start