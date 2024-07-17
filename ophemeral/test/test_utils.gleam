import beecrypt
import gleam/dynamic
import gleam/io
import gleam/json
import gleam/option.{None}
import ophemeral/database
import ophemeral/models/competition.{type Competition, Competition}
import ophemeral/models/secret
import ophemeral/router
import ophemeral/web.{type Context, Context}
import wisp/testing

pub type Token {
  Token(token: String)
}

pub fn with_context(testcase: fn(Context) -> t) -> t {
  use db <- database.with_connection(":memory:")
  database.migrate(db)
  let ctx = Context(db: db, competition_id: None)

  testcase(ctx)
}

pub fn with_competition(testcase: fn(Competition) -> t) -> t {
  let competition =
    Competition(
      id: 0,
      name: "Mareld Nattcup E1",
      organizer: "Göteborg-Majorna OK",
    )

  testcase(competition)
}

pub fn with_created_competition(
  ctx: Context,
  testcase: fn(Competition, String, String) -> t,
) -> t {
  use competition <- with_competition

  let secret = "secret"
  let secret_hash = beecrypt.hash(secret)

  let assert Ok(created_competition) = competition.create(ctx.db, competition)
  let assert Ok(_) = secret.create(ctx.db, created_competition, secret_hash)

  let data = json.object([#("secret", json.string(secret))])
  let response =
    testing.post_json("api/auth", [], data)
    |> router.handle_request(ctx)

  let decoder = dynamic.decode1(Token, dynamic.field("token", dynamic.string))
  let assert Ok(token) = response |> testing.string_body |> json.decode(decoder)

  testcase(created_competition, secret, token.token)
}
