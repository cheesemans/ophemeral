import gleam/option.{type Option, None, Some}
import gleam/result
import ophemeral/error.{type Error}
import sqlight

pub type Connection =
  sqlight.Connection

// TODO: Look into what these does
const connection_config = "
pragma foreign_keys = on;
pragma auto_vacuum = incremental;
pragma journal_mode = wal;
"

pub fn with_connection(path: String, next: fn(sqlight.Connection) -> a) -> a {
  use db <- sqlight.with_connection(path)

  // Enable configuration we want for all connections
  let assert Ok(_) = sqlight.exec(connection_config, db)

  next(db)
  // Add stuff to do before closing connection
  //let assert Ok(_) = sqlight.exec(connection_config, db)
}

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

pub fn migrate(db: sqlight.Connection) {
  let command =
    "
    drop table if exists secrets;
    drop table if exists competitions;
    create table competitions (
      id integer primary key autoincrement not null,

      name text not null unique, 

      organizer text not null, 

      datetime text not null
    );

    create table secrets (
      hash text not null,

      competition_id integer references competitions(id) ON DELETE CASCADE
    );
  "

  let assert Ok(_) = sqlight.exec(command, db)

  Nil
}
