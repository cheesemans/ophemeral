import administration/error.{type Error}
import administration/generated/sql
import gleam/dynamic.{type Dynamic}
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string_builder.{type StringBuilder}
import sqlight

pub type Competition {
  Competition(id: Int, name: String, organizer: String)
}

pub fn db_decoder() -> dynamic.Decoder(Competition) {
  dynamic.decode3(
    Competition,
    dynamic.element(0, dynamic.int),
    dynamic.element(1, dynamic.string),
    dynamic.element(2, dynamic.string),
  )
}

pub fn json_decoder(json: Dynamic) -> Result(Competition, dynamic.DecodeErrors) {
  let decoder =
    dynamic.decode3(
      Competition,
      dynamic.field("id", dynamic.int),
      dynamic.field("name", dynamic.string),
      dynamic.field("organizer", dynamic.string),
    )
  decoder(json)
}

pub fn json_encoder(competition: Competition) -> StringBuilder {
  json.object([
    #("id", json.int(competition.id)),
    #("name", json.string(competition.name)),
    #("organizer", json.string(competition.organizer)),
  ])
  |> json.to_string_builder
}

pub fn create(
  db: sqlight.Connection,
  competition: Competition,
) -> Result(Competition, error.Error) {
  let arguments = [
    sqlight.text(competition.name),
    sqlight.text(competition.organizer),
  ]

  let result =
    sql.insert_competition(db, arguments, db_decoder())
    |> result.map(fn(rows) {
      let assert [row] = rows
      row
    })

  case result {
    Ok(competition) -> Ok(competition)
    Error(error.DatabaseError(sqlight.SqlightError(
      sqlight.ConstraintUnique,
      "UNIQUE constraint failed: competitions.name",
      _,
    ))) -> Error(error.CompetitionNameAlreadyInUse)
    Error(error) -> Error(error)
  }
}

pub fn update(
  db: sqlight.Connection,
  competition: Competition,
) -> Result(Competition, error.Error) {
  let arguments = [
    sqlight.text(competition.name),
    sqlight.text(competition.organizer),
    sqlight.int(competition.id),
  ]

  let result =
    sql.update_competition(db, arguments, db_decoder())
    |> result.map(fn(rows) {
      let assert [row] = rows
      row
    })

  case result {
    Ok(competition) -> Ok(competition)
    Error(error.DatabaseError(sqlight.SqlightError(
      sqlight.ConstraintUnique,
      "UNIQUE constraint failed: competitions.name",
      _,
    ))) -> Error(error.CompetitionNameAlreadyInUse)
    Error(error) -> Error(error)
  }
}

pub fn get_by_id(
  db: sqlight.Connection,
  id: Int,
) -> Result(Option(Competition), error.Error) {
  let arguments = [sqlight.int(id)]

  let result = sql.get_competition_by_id(db, arguments, db_decoder())

  case result {
    Ok([competition]) -> Ok(Some(competition))
    Ok(_) -> Ok(None)
    Error(error) -> Error(error)
  }
}