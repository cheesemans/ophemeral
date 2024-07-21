-- Initial schema migration
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

