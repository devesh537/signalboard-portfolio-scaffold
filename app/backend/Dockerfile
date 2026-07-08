# Multi-stage build: keeps the final image to just prod deps + source,
# no build toolchain, no dev dependencies. This is the pattern referenced
# in the resume's Docker-optimization bullet points.

FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

FROM node:20-alpine
WORKDIR /app
RUN addgroup -g 10001 app && adduser -D -u 10001 -G app app
COPY --from=deps /app/node_modules ./node_modules
COPY package*.json ./
COPY src ./src
USER 10001
EXPOSE 5000
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:5000/api/health || exit 1
CMD ["node", "src/index.js"]
