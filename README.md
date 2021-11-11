# Geolocation
This application parses csv data consisting of ip and their geo data and also exposes an api to get the location data using ip address.
I have used flow library to process the csv files and insert the data into db.
Initially I thought of using tasks to get the required parallelism but had to move to flow because of the following reasons.
Flow allows us to divide the work into multiple stages wherein the data will be processed parallely according to available cores. Even though tasks allow us to parallelize any unit of work, but then it will lead to additional boiler plates 'cause 
flow provided us with useful abstractions over genstage(like batching etc) that allows us to focus more on the logic and less on boiler plate.

The biggest benefit that I got from flow was that you could work with windows and configure their size and once window size reaches the config limit a trigger event will occur on which can react and do some further processing. This was used to create batches.

Also initial benchmarks showed flow to be faster than `Task.async_stream`.
I also had broadway in mind but that would have been an overkill, since we are not dealing with an event based system
and are focussed more on data processing.
For csv parsing I initially considered the CSV module. However when I benchmarked it with nimble_csv, nimble_csv was the clear
winner with massive performance which further increased when I fed the resulting stream to flow.
Initial benchmarks (CSV vs nimble_csv) Both use flow for stream processing:

Code for csv:
```elixir
File.stream!(path) 
|> CSV.decode(num_workers: System.schedulers_online()) 
|> Flow.from_enumerable() 
|> Stream.run()
```

Code for nimble_csv:
```elixir
path
|> File.stream!()
|> RFC4180.parse_stream()
|> Flow.from_enumerable()
|> Stream.run()
```
The following benchmarks were taken on M1 Mac 8 core and 8 GB RAM
Average time taken for csv library -> 10 seconds.

Average Time taken for nimble_csv library> 1.7 seconds.

A benchmark was also run to decide between task and flow.
Code using task:
```elixir
  async_options = [max_concurrency: 8, ordered: false]

  path
  |> File.stream!()
  |> Stream.chunk_every(10000)
  |> Task.async_stream(fn batch ->
    batch
    |> Enum.map(&RFC4180.parse_string/1)
  end, async_options)
  |> Stream.run()
```
Average time taken using task: 2.8 seconds. 

A chunk size of 10000 was found to be the sweet spot.

Hence it was decided that flow along with nimble_csv will not only result in performant code but more understandable as well. 
After including db insertions the entire flow took around 12-14 seconds.

I have included a dockerfile and docker-compose file to run the app and the db in a containerized fashion. You need to
set the database config variables and the csv path as well. However the app will be pretty slow in a mac OS container
'cause of the file system and other complications. So I would suggest to run it in linux if you are planning to run it in 
a container otherwise run it bare. 
The entire parsing and insertion took about 450 seconds on a containerized app on MAC OS which is around 30 times slower than
non containerized in the same app.

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

How to use the app:
1. First set the environment variable `CSV_PATH` and database config variables - `USER_NAME`, `PASSWORD`, `DATABASE` and `HOSTNAME` where the csv file is actually present.
2. Start parsing using `Geolocation.Parse.init_parse/0`.
3. Fetch ip details using the api `/geo_data?ip_address=<IP_ADDRESS>`.
Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

To run it in container fashion set the above environment variables and run `docker-compose build` followed by `docker-compose up`.


Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
