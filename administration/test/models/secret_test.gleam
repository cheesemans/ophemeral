import administration/models/competition
import administration/models/secret.{Secret}
import beecrypt
import gleam/option.{None, Some}
import test_utils

pub fn insert_competition_secret_test() {
  use ctx <- test_utils.with_context
  use competition <- test_utils.with_competition

  let assert Ok(competition) = competition.create(ctx.db, competition)

  let assert Ok(Secret(hash: "secret_hash", competition_id: 1)) =
    secret.create(ctx.db, competition, "secret_hash")
}

pub fn validate_competition_secret_test() {
  use ctx <- test_utils.with_context
  use competition <- test_utils.with_competition

  let secret = "secret"
  let secret_hash = beecrypt.hash(secret)

  let assert Ok(competition) = competition.create(ctx.db, competition)

  let assert Ok(_) = secret.create(ctx.db, competition, secret_hash)

  let assert Ok(Some(Secret(hash: _, competition_id: 1))) =
    secret.validate_secret(ctx.db, secret)
}

pub fn validate_secret_not_found_test() {
  use ctx <- test_utils.with_context

  let assert Ok(None) = secret.validate_secret(ctx.db, "secret")
}
