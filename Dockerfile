# Custom base image with Debian Bookworm (for GLIBC 2.33+ support)
# Uses Erlang Solutions repository for Erlang and pre-built Elixir
ARG ELIXIR_VERSION=1.14.2
ARG OTP_VERSION=25.1.1
ARG DEBIAN_VERSION=bookworm-slim

# Build custom base image with Elixir and Erlang on Debian Bookworm
FROM debian:${DEBIAN_VERSION} as base

ARG ELIXIR_VERSION
ARG OTP_VERSION

# Install Erlang from Debian repositories (Bookworm has Erlang 25.x)
# Also install locales and configure UTF-8 to prevent encoding warnings
RUN apt-get update -y && apt-get install -y \
    erlang \
    erlang-dev \
    erlang-xmerl \
    curl \
    unzip \
    locales \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set UTF-8 locale environment variables
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Install Elixir from source (Debian Bookworm doesn't have Elixir packages)
RUN apt-get update -y && apt-get install -y \
    make \
    && cd /tmp \
    && curl -fSL "https://github.com/elixir-lang/elixir/archive/v${ELIXIR_VERSION}.tar.gz" -o elixir.tar.gz \
    && tar -xzf elixir.tar.gz \
    && cd elixir-${ELIXIR_VERSION} \
    && make install PREFIX=/usr/local \
    && cd / \
    && rm -rf /tmp/elixir-${ELIXIR_VERSION} /tmp/elixir.tar.gz \
    && apt-get purge -y make \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Verify installations
RUN erl -version && elixir --version

FROM base as builder

# install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV="prod"

# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY priv priv

COPY lib lib

COPY assets assets

# compile assets
RUN mix assets.deploy

# Compile the release
RUN mix compile

# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/

COPY rel rel
RUN mix release

# start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM base

# Install only runtime dependencies (base image already has Elixir/Erlang)
RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR "/app"
RUN chown nobody /app

# set runner ENV
ENV MIX_ENV="prod"

# Only copy the final release from the build stage
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/trivia_buzzer ./

# Copy init script
COPY docker-init.sh /docker-init.sh
RUN chmod +x /docker-init.sh

# Simple entrypoint: fix permissions, then switch to nobody and run command
# Note: Container runs as root by default, entrypoint switches to nobody
ENTRYPOINT ["/bin/sh", "/docker-init.sh"]

CMD ["/app/bin/server"]
# Appended by flyctl
ENV ECTO_IPV6 true
ENV ERL_AFLAGS "-proto_dist inet6_tcp"
