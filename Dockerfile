FROM debian:buster-slim

RUN apt-get update && \
    apt-get install --no-install-recommends -y curl xz-utils amazon-ecr-credential-helper && \
    rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl -SL https://download.docker.com/linux/static/stable/x86_64/docker-20.10.6.tgz | tar -xz --strip-components=1 -C /usr/bin/ && \
    curl -fsSL "https://github.com/GoogleCloudPlatform/docker-credential-gcr/releases/download/v2.0.2/docker-credential-gcr_linux_amd64-2.0.2.tar.gz" | tar xz --to-stdout ./docker-credential-gcr > /usr/local/bin/docker-credential-gcr && chmod +x /usr/local/bin/docker-credential-gcr

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
