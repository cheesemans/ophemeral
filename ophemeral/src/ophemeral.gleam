import gleam/erlang/os
import gleam/erlang/process
import mist
import ophemeral/database
import ophemeral/router
import ophemeral/routes/auth
import ophemeral/web.{Context}
import wisp

pub fn main() {
  wisp.configure_logger()
  //let secret_key_base = wisp.random_string(64)
  let secret_key_base = wisp.random_string(64)

  let database = database_name()

  database.with_connection(database, database.migrate)

  let handler = fn(req) {
    use db <- database.with_connection(database)
    use competition_id <- auth.get_competition_id_from_cookie(req)
    let context = Context(db: db, competition_id: competition_id)

    router.handle_request(req, context)
  }

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
