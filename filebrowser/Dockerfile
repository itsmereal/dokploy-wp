FROM alpine:3.19 AS builder

# Download filebrowser binary directly from GitHub releases
RUN apk add --no-cache curl tar && \
    ARCH=$(uname -m) && \
    case "$ARCH" in \
        x86_64) ARCH="amd64" ;; \
        aarch64) ARCH="arm64" ;; \
        armv7l) ARCH="armv7" ;; \
    esac && \
    curl -fsSL "https://github.com/filebrowser/filebrowser/releases/latest/download/linux-${ARCH}-filebrowser.tar.gz" -o /tmp/filebrowser.tar.gz && \
    tar -xzf /tmp/filebrowser.tar.gz -C /usr/local/bin filebrowser && \
    chmod +x /usr/local/bin/filebrowser

FROM alpine:3.19

# Install bash for init script
RUN apk add --no-cache bash ca-certificates

# Copy filebrowser from builder
COPY --from=builder /usr/local/bin/filebrowser /usr/local/bin/filebrowser

# Copy init script
COPY init.sh /init.sh
RUN chmod +x /init.sh

EXPOSE 80

ENTRYPOINT ["/init.sh"]
