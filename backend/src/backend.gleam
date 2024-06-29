import backend/database
import backend/router
import backend/web.{Context}
import gleam/erlang/process
import mist
import sqlight
import wisp

pub const database = "file:ophemeral.sqlite3"

pub fn main() {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  database.with_connection(database, database.migrate)

  use db <- sqlight.with_connection(database)
  let context = Context(db: db)

  let handler = router.handle_request(_, context)

  let assert Ok(_) =
    handler
    |> wisp.mist_handler(secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  process.sleep_forever()
}
