FROM elixir:latest

RUN mkdir /app
COPY . /app
WORKDIR /app
ENV CSV_PATH=/Users/mukul/Downloads/data_dump.csv

RUN mix local.hex --force
# RUN mix deps.get
EXPOSE 4000
CMD mix phx.server