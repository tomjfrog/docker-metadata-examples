FROM alpine:3.20
ARG VCS_REF=unknown
LABEL org.opencontainers.image.title="build-info-app" \
      org.opencontainers.image.revision="${VCS_REF}"
RUN echo "hello from build-info-app" > /hello.txt
CMD ["cat", "/hello.txt"]
