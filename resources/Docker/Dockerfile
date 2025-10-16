FROM ubuntu:22.04

# Disable interactive prompts during install
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

RUN apt-get update && \
    apt-get install -y --no-install-recommends nginx awscli jq curl tzdata && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 80
CMD ["/start.sh"]
