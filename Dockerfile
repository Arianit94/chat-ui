# read the doc: https://huggingface.co/docs/hub/spaces-sdks-docker
# you will also find guides on how best to write your Dockerfile

# Building production dependencies
FROM node:19 as builder-production

WORKDIR /app

COPY --chown=1000 package-lock.json package.json ./
RUN npm ci --omit=dev

# Building development dependencies
FROM builder-production as builder

RUN npm ci

COPY --chown=1000 . .

RUN npm run build

# Final stage
FROM node:19-slim

RUN npm install -g pm2

COPY --from=builder-production /app/node_modules /app/node_modules
COPY --chown=1000 package.json /app/package.json
COPY --from=builder /app/build /app/build

CMD pm2 start /app/build/index.js -i $CPU_CORES --no-daemon
