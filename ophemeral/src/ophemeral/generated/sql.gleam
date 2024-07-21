// THIS FILE IS GENERATED. DO NOT EDIT.
// Regenerate with `gleam run -m sqlgen`

import gleam/dynamic
import gleam/result
import ophemeral/error.{type Error}
import sqlight

pub type QueryResult(t) =
  Result(List(t), Error)

pub fn delete_competition_by_id(
  db: sqlight.Connection,
  arguments: List(sqlight.Value),
  decoder: dynamic.Decoder(a),
) -> QueryResult(a) {
  let query =
    "delete from competitions
where id = $1
"
  sqlight.query(query, db, arguments, decoder)
  |> result.map_error(error.DatabaseError)
}

pub fn get_all_competitions(
  db: sqlight.Connection,
  arguments: List(sqlight.Value),
  decoder: dynamic.Decoder(a),
) -> QueryResult(a) {
  let query =
    "select *
from competitions
"
  sqlight.query(query, db, arguments, decoder)
  |> result.map_error(error.DatabaseError)
}

pub fn get_competition_by_id(
  db: sqlight.Connection,
  arguments: List(sqlight.Value),
  decoder: dynamic.Decoder(a),
) -> QueryResult(a) {
  let query =
    "select *
from competitions
where id = $1
"
  sqlight.query(query, db, arguments, decoder)
  |> result.map_error(error.DatabaseError)
}

pub fn get_secret_by_hash(
  db: sqlight.Connection,
  arguments: List(sqlight.Value),
  decoder: dynamic.Decoder(a),
) -> QueryResult(a) {
  let query =
    "select *
from secrets
where hash = $1
"
  sqlight.query(query, db, arguments, decoder)
  |> result.map_error(error.DatabaseError)
}

pub fn insert_competition(
  db: sqlight.Connection,
  arguments: List(sqlight.Value),
  decoder: dynamic.Decoder(a),
) -> QueryResult(a) {
  let query =
    "insert into competitions
  (name, organizer, datetime)
values
  ($1, $2, $3)
returning *
"
  sqlight.query(query, db, arguments, decoder)
  |> result.map_error(error.DatabaseError)
}

pub fn insert_secret(
  db: sqlight.Connection,
  arguments: List(sqlight.Value),
  decoder: dynamic.Decoder(a),
) -> QueryResult(a) {
  let query =
    "insert into secrets
  (hash, competition_id)
values
  ($1, $2)
returning *
"
  sqlight.query(query, db, arguments, decoder)
  |> result.map_error(error.DatabaseError)
}

pub fn update_competition(
  db: sqlight.Connection,
  arguments: List(sqlight.Value),
  decoder: dynamic.Decoder(a),
) -> QueryResult(a) {
  let query =
    "update competitions
set name = $1, organizer = $2, datetime = $3
where id = $4
returning *
"
  sqlight.query(query, db, arguments, decoder)
  |> result.map_error(error.DatabaseError)
}
