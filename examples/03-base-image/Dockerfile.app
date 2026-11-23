# App image: FROM the Artifactory-hosted base. Adds python + deliberately old
# libraries so there are application-owned findings alongside inherited base findings.
ARG BASE_IMAGE
FROM ${BASE_IMAGE}
LABEL com.example.image.role="app"

RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir requests==2.19.1 urllib3==1.24.1

CMD ["echo", "bid-app"]
