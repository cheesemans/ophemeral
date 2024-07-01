import administration/error.{type Error}
import administration/generated/sql
import administration/models/competition.{type Competition}
import beecrypt
import gleam/dynamic.{type Dynamic}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import sqlight
import decode

pub type Secret {
  Secret(hash: String, competition_id: Int)
}

pub fn db_decoder(data: Dynamic) -> Result(Secret, dynamic.DecodeErrors) {
  decode.into({
    use hash <- decode.parameter
    use competition_id <- decode.parameter
    Secret(hash, competition_id)
  })
  |> decode.field(0, decode.string)
  |> decode.field(1, decode.int)
  |> decode.from(data)
}

pub fn create(
  db: sqlight.Connection,
  competition: Competition,
  secret_hash: String,
) -> Result(Secret, error.Error) {
  let arguments = [sqlight.text(secret_hash), sqlight.int(competition.id)]

  let result =
    sql.insert_secret(db, arguments, db_decoder)
    |> result.map(fn(rows) {
      let assert [row] = rows
      row
    })

  case result {
    Ok(secret) -> Ok(secret)
    Error(error) -> Error(error)
  }
}

pub fn validate_secret(
  db: sqlight.Connection,
  secret: String,
) -> Result(Option(Secret), error.Error) {
  case sql.get_secrets(db, [], db_decoder) {
    Ok(secrets) -> {
      let result =
        secrets
        |> list.filter(fn(db_secret) {
          beecrypt.verify(secret, db_secret.hash)
        })
        |> list.first
      case result {
        Ok(secret) -> Ok(Some(secret))
        Error(Nil) -> Ok(None)
      }
    }
    Error(error) -> Error(error)
  }
}
