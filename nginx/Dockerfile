FROM nginx:alpine

# Install envsubst (part of gettext) and wget for healthcheck
RUN apk upgrade --no-cache && apk add --no-cache gettext wget

# Copy nginx config template and entrypoint
COPY default.conf.template /etc/nginx/templates/default.conf.template
COPY docker-entrypoint.sh /docker-entrypoint-custom.sh
RUN chmod +x /docker-entrypoint-custom.sh

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint-custom.sh"]
CMD ["nginx", "-g", "daemon off;"]
