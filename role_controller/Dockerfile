# Build Stage
FROM elixir:1.18-slim AS build

# Install build dependencies
RUN apt-get update && apt-get install -y build-essential git && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Hex and Rebar
RUN mix local.hex --force && mix local.rebar --force

# Set build environment
ENV MIX_ENV=prod

# Copy mix files and fetch deps
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod

# Copy application code
COPY lib lib
COPY config config

# Compile and build the Elixir release
RUN mix compile
RUN mix release

# Application Stage
FROM debian:bookworm-slim AS app

# Install system dependencies for OCI CLI and application runtime
RUN apt-get update && apt-get install -y \
    ca-certificates curl jq python3 python3-venv unzip \
    && rm -rf /var/lib/apt/lists/*

# Install OCI CLI
RUN bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)" -- --accept-all-defaults

ENV PATH="/root/bin:${PATH}"
ENV MIX_ENV=prod

WORKDIR /app

# Copy the compiled release from the build stage
COPY --from=build /app/_build/prod/rel/role_controller ./

# Copy and setup entrypoint
COPY entrypoint.sh ./
RUN chmod +x entrypoint.sh

CMD ["./entrypoint.sh"]
