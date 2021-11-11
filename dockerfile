FROM elixir:latest

RUN mkdir /app
COPY . /app
WORKDIR /app
ENV CSV_PATH=/Users/mukul/Downloads/data_dump.csv
ENV USER_NAME=postgres
ENV PASSWORD=postgres
ENV DATABASE=geolocation_dev
ENV HOSTNAME=host.docker.internal
RUN mix local.hex --force
RUN mix deps.get
RUN mix local.rebar --force
EXPOSE 4000
CMD mix phx.server