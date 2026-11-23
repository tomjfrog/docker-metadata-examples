# App image built FROM the base. Docker copies the base's labels into this image's
# config, so un-overridden labels (e.g. com.example.image.golden) are inherited.
# Labels redeclared here (role, title) override the base's values.
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG CI_RUN_ID=0

LABEL org.opencontainers.image.title="labels-app" \
      com.example.image.role="app" \
      com.example.team="payments" \
      com.example.ci.run="${CI_RUN_ID}"

CMD ["echo", "labels-app"]
