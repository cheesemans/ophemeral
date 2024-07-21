CREATE TABLE storch_migrations (id integer, applied integer);

CREATE TABLE competitions (
  id integer primary key autoincrement not null,
  name text not null unique, 
  organizer text not null, 
  datetime text not null
);

CREATE TABLE sqlite_sequence(name,seq);

CREATE TABLE secrets (
  hash text not null,
  competition_id integer references competitions(id) ON DELETE CASCADE
);

