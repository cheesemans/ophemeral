import administration/database
import administration/router
import administration/web.{Context}
import gleam/erlang/os
import gleam/erlang/process
import mist
import wisp

pub fn main() {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  let database = database_name()

  use db <- database.with_connection(database)
  database.migrate(db)

  let context = Context(db: db)

  let handler = router.handle_request(_, context)

  let assert Ok(_) =
    handler
    |> wisp.mist_handler(secret_key_base)
    |> mist.new
    |> mist.port(8080)
    |> mist.start_http

  process.sleep_forever()
}

fn database_name() {
  case os.get_env("DATABASE_PATH") {
    Ok(path) -> path
    Error(Nil) -> "./data/database.sqlite"
  }
}
