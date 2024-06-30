FROM ghcr.io/gleam-lang/gleam:v1.2.1-erlang-alpine

# Add project cod
COPY . /build/

# Compile the Gleam application
RUN cd /build \
  && apk add make gcc build-base bsd-compat-headers \
  && gleam export erlang-shipment \
  && mv build/erlang-shipment /app \
  && rm -r /build \
  && apk del make gcc build-base bsd-compat-headers

# Run
WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
