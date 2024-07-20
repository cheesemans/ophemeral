import ophemeral/database
import argus
import decode
import gleam/dynamic.{type Dynamic}
import gleam/option.{type Option, None, Some}
import ophemeral/error.{type Error}
import ophemeral/generated/sql
import ophemeral/models/competition.{type Competition}
import ophemeral/web.{type Context}
import sqlight

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

fn hash_secret(secret_key: String, ctx: Context) -> String {
  let assert Ok(hashes) = 
    argus.hasher_argon2i()
   |> argus.hash(secret_key, ctx.config.secret_salt)

  hashes.encoded_hash
}

pub fn create(
  ctx: Context,
  competition: Competition,
  secret: String,
) -> Result(Secret, error.Error) {
  let hash = hash_secret(secret, ctx)

  let arguments = [sqlight.text(hash), sqlight.int(competition.id)]

  let result =
    sql.insert_secret(ctx.db, arguments, db_decoder)
    |> database.one

  case result {
    Ok(secret) -> Ok(secret)
    Error(error) -> Error(error)
  }
}

pub fn get_secret(
  secret: String,
  ctx: Context,
) -> Result(Option(Secret), error.Error) {
  let hash = hash_secret(secret, ctx)

  let arguments = [sqlight.text(hash)]

  let result =
    sql.get_secret_by_hash(ctx.db, arguments, db_decoder)
    |> database.zero_or_one

  case result {
    Ok(Some(secret)) -> Ok(Some(secret))
    Ok(None) -> Ok(None)
    Error(error) -> Error(error)
  }
}

pub fn validate_form_secret(
  secret: String,
  ctx: Context,
) -> Result(String, String) {
  case get_secret(secret, ctx) {
    Ok(Some(_)) -> Ok(secret)
    Ok(None) -> Error("The secret key is not associated with any competition")
    Error(_) -> Error("Something went terribly wrong, please try again")
  }
}
