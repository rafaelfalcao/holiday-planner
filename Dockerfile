# Step 1: Build
FROM node:20-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Step 2: Run
FROM node:20-alpine

WORKDIR /app
COPY --from=builder /app/.svelte-kit ./.svelte-kit
COPY --from=builder /app/build ./build

COPY package*.json ./
RUN npm install --omit=dev

EXPOSE 3000
CMD [ "node", "build/index.js" ]

