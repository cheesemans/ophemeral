import argus
import gleam/option.{None, Some}
import gleeunit/should
import ophemeral/models/competition
import ophemeral/models/secret.{Secret}
import test_utils

pub fn insert_competition_secret_test() {
  use ctx <- test_utils.with_context
  use competition <- test_utils.with_competition

  let assert Ok(competition) = competition.create(ctx.db, competition)

  let secret = "WibbleWobble"

  let assert Ok(hashes) =
    argus.hasher_argon2i()
    |> argus.hash(secret, ctx.config.secret_salt)

  let expected_hash = hashes.encoded_hash

  let assert Ok(Secret(hash: hash, competition_id: 1)) =
    secret.create(ctx, competition, secret)

  expected_hash
  |> should.equal(hash)
}

pub fn validate_competition_secret_test() {
  use ctx <- test_utils.with_context
  use competition <- test_utils.with_competition

  let secret = "secret"

  let assert Ok(competition) = competition.create(ctx.db, competition)

  let assert Ok(_) = secret.create(ctx, competition, secret)

  let assert Ok(Some(Secret(hash: _, competition_id: 1))) =
    secret.get_secret(secret, ctx)
}

pub fn validate_secret_not_found_test() {
  use ctx <- test_utils.with_context

  let assert Ok(None) = secret.get_secret("secret", ctx)
}

pub fn validate_form_secret_test() {
  use ctx <- test_utils.with_context
  use competition <- test_utils.with_competition

  let expected_secret = "secret"

  let assert Ok(competition) = competition.create(ctx.db, competition)

  let assert Ok(_) = secret.create(ctx, competition, expected_secret)

  let assert Ok(secret) = secret.validate_form_secret("secret", ctx)

  secret
  |> should.equal(expected_secret)
}
