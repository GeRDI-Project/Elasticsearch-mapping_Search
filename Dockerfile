FROM node:9.11.2

RUN npm install -g js-yaml

ADD job.sh job.sh
ADD metadata-index-settings.yml metadata-index-settings.yml

ENTRYPOINT sh job.sh
