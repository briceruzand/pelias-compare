
##############################################################################
# Base with dependencies
##############################################################################
FROM node:16-bookworm-slim AS base

WORKDIR /app
COPY package.json yarn.lock ./
RUN yarn install

##############################################################################
# Builder
##############################################################################
FROM base AS builder

ENV NODE_ENV=production

COPY ./ ./
RUN yarn build:spa

##############################################################################
# Runtime with nginx
##############################################################################
FROM nginx:stable-alpine AS production
RUN cat > /etc/nginx/conf.d/default.conf <<'EOF'
server {
  listen 80;
  server_tokens off;

  root /usr/share/nginx/html/;

  location / {
    gzip_static on;
    try_files $uri @index;
  }

  location @index {
    gzip_static on;

    add_header Cache-Control no-cache;
    add_header X-Content-Type-Options nosniff;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header Referrer-Policy "strict-origin";

    expires 0;
    try_files /index.html =404;
  }
}
EOF
COPY --from=builder /app/spa/ /usr/share/nginx/html/

# Expose port 80
EXPOSE 80
