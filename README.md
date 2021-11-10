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

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

How to use the app:
1. First set the environment variable `CSV_PATH` where the csv file is actually present.
2. Start parsing using `Geolocation.Parse.init_parse/0`.
3. Fetch ip details using the api `/geo_data?ip_address=<IP_ADDRESS>`.
Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
