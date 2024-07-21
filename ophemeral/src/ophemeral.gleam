import feather
import feather/migrate
import gleam/erlang/process
import gleam/option.{None}
import mist
import ophemeral/config.{type Config}
import ophemeral/database
import ophemeral/models/competition
import ophemeral/router
import ophemeral/routes/auth
import ophemeral/web.{Context}
import shakespeare/actors/scheduled
import wisp

pub fn main() {
  let config = config.read()
  wisp.configure_logger()

  let assert Ok(_) =
    feather.with_connection(config.database_config, database.migrate)

  let handler = fn(req) {
    use db <- feather.with_connection(config.database_config)
    use competition_id <- auth.get_competition_id_from_cookie(req)
    let context =
      Context(config: config, db: db, competition_id: competition_id)

    router.handle_request(req, context)
  }

  let assert Ok(_) =
    handler
    |> wisp.mist_handler(config.secret_key_base)
    |> mist.new
    |> mist.port(8080)
    |> mist.start_http

  start_cleanup_database_job(config)

  process.sleep_forever()
}

fn start_cleanup_database_job(config: Config) {
  let _ =
    scheduled.start(
      fn() {
        use db <- feather.with_connection(config.database_config)
        let context = Context(config: config, db: db, competition_id: None)

        competition.delete_old(context)
        Nil
      },
      scheduled.Daily(0, 0, 0),
    )

  Nil
}
