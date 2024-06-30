import sqlight

pub type Connection =
  sqlight.Connection

// TODO: Look into what these does
const connection_config = "
pragma foreign_keys = on;
pragma auto_vacuum = incremental;
"

pub fn with_connection(path: String, next: fn(sqlight.Connection) -> a) -> a {
  use db <- sqlight.with_connection(path)

  // Enable configuration we want for all connections
  let assert Ok(_) = sqlight.exec(connection_config, db)

  next(db)
}

pub fn migrate(db: sqlight.Connection) {
  let command =
    "
    create table if not exists competitions (
      id integer primary key autoincrement not null,

      name text not null unique, 

      organizer text not null 
    );

    create table if not exists secrets (
      secret_hash text not null,

      competition_id integer references competitions(id) ON DELETE CASCADE
    );
  "

  let assert Ok(_) = sqlight.exec(command, db)

  Nil
}
