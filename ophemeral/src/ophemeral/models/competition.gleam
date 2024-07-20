import gleam/order
import ophemeral/database
import gleam/string
import gleam/list
import decode
import gleam/dynamic.{type Dynamic}
import gleam/json
import gleam/option.{type Option, None}
import gleam/string_builder.{type StringBuilder}
import ophemeral/config.{type Config}
import ophemeral/error.{type Error}
import ophemeral/generated/sql
import ophemeral/web.{type Context, Context}
import sqlight
import birl.{type Time}
import birl/duration

pub type Competition {
  Competition(id: Int, name: String, organizer: String, datetime: Time)
}

pub type CompetitionForm {
  CompetitionForm(name: String, organizer: String, datetime: String) 
}

pub fn db_decoder(data: Dynamic) -> Result(Competition, dynamic.DecodeErrors) {
  decode.into({
    use id <- decode.parameter
    use name <- decode.parameter
    use organizer <- decode.parameter
    use datetime <- decode.parameter
    Competition(id, name, organizer, datetime)
  })
  |> decode.field(0, decode.int)
  |> decode.field(1, decode.string)
  |> decode.field(2, decode.string)
  |> decode.field(3, decode.string |> decode.map(decode_datetime))
  |> decode.from(data)
}

fn decode_datetime(datetime: String) -> Time {
  case birl.from_naive(datetime) {
    Ok(time) -> time
    _ -> panic as "Date from database should always be decodable"
  }
}

pub fn json_decoder(data: Dynamic) -> Result(Competition, dynamic.DecodeErrors) {
  decode.into({
    use id <- decode.parameter
    use name <- decode.parameter
    use organizer <- decode.parameter
    use datetime <- decode.parameter
    Competition(id, name, organizer, datetime)
  })
  |> decode.field("id", decode.int)
  |> decode.field("name", decode.string)
  |> decode.field("organizer", decode.string)
  |> decode.field("datetime", decode.string |> decode.map(decode_datetime))
  |> decode.from(data)
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
  competition: CompetitionForm,
) -> Result(Competition, error.Error) {
  let arguments = [
    sqlight.text(competition.name),
    sqlight.text(competition.organizer),
    sqlight.text(competition.datetime),
  ]

  let result =
    sql.insert_competition(db, arguments, db_decoder)
    |> database.one

  case result {
    Ok(competition) -> Ok(competition)
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
    sqlight.text(birl.to_naive(competition.datetime)),
    sqlight.int(competition.id),
  ]

  let result =
    sql.update_competition(db, arguments, db_decoder)
    |> database.one

  case result {
    Ok(competition) -> Ok(competition)
    Error(error) -> Error(error)
  }
}

pub fn get_by_id(
  db: sqlight.Connection,
  id: Int,
) -> Result(Option(Competition), error.Error) {
  let arguments = [sqlight.int(id)]

  sql.get_competition_by_id(db, arguments, db_decoder)
  |> database.zero_or_one
}

pub fn get_all(ctx: Context) -> List(Competition) {
  let result = sql.get_all_competitions(ctx.db, [], db_decoder)

  case result {
    Ok(competitions) -> competitions
    Error(_) -> []
  }
}

pub fn validate_form_name(name: String, ctx: Context) -> Result(String, String) {
  let result = get_all(ctx)
  |> list.find(fn(competition) { string.lowercase(competition.name) == string.lowercase(name) })

  case result {
    Ok(_) -> Error("Competition name is already in use!")
    Error(_) -> Ok(name)
  }
}

pub fn delete_old(ctx: Context) -> Nil {
  let old_competitions = get_all(ctx)
  |> list.filter(is_old_competition)

  old_competitions
  |> list.each(fn (competition) {delete_competition(competition, ctx) })
}

fn delete_competition(competition: Competition, ctx: Context) -> Result(List(Competition), Error) {
  let arguments = [sqlight.int(competition.id)]

  sql.delete_competition_by_id(ctx.db, arguments, db_decoder)
}

fn is_old_competition(competition: Competition) -> Bool {
  //let keep_duration = duration.months(3)
  let keep_duration = duration.days(1)
  let cutoff_datetime = birl.subtract(birl.now(), keep_duration)
  birl.compare(competition.datetime, cutoff_datetime) == order.Lt
}
