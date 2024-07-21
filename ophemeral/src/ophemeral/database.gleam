import feather
import feather/migrate
import gleam/erlang
import gleam/option.{type Option, None, Some}
import gleam/result
import ophemeral/config.{type Config}
import ophemeral/error.{type Error}
import sqlight

pub type Connection =
  sqlight.Connection

pub fn one(query_result: Result(List(a), Error)) -> Result(a, Error) {
  query_result
  |> result.map(fn(rows) {
    let assert [row] = rows
    row
  })
}

pub fn zero_or_one(
  query_result: Result(List(a), Error),
) -> Result(Option(a), Error) {
  query_result
  |> result.map(fn(rows) {
    case rows {
      [] -> None
      [row] -> Some(row)
      _ -> panic as "Expected 0 or 1 rows"
    }
  })
}

pub fn migrate(connection: Connection) -> Result(Nil, migrate.MigrationError) {
  let assert Ok(priv_dir) = erlang.priv_directory("ophemeral")
  use migrations <- result.try(migrate.get_migrations(priv_dir <> "/migrations"))
  migrate.migrate(migrations, connection)
}
