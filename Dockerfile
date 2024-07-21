FROM ghcr.io/gleam-lang/gleam:v1.3.2-erlang-alpine

# Add project code
COPY external/argus /build/external/argus
COPY ophemeral /build/ophemeral

# Compile the Gleam application
RUN cd /build/ophemeral \
  && apk add make gcc build-base bsd-compat-headers \
  && gleam export erlang-shipment \
  && mv build/erlang-shipment /app \
  && rm -r /build \
  && apk del make gcc build-base bsd-compat-headers

# Run
WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
