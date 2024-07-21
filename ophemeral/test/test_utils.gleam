import feather
import gleam/dynamic
import gleam/json
import gleam/option.{None}
import ophemeral/config.{Config, Dev}
import ophemeral/database
import ophemeral/models/competition.{
  type Competition, type CompetitionForm, Competition, CompetitionForm,
}
import ophemeral/models/secret
import ophemeral/router
import ophemeral/web.{type Context, Context}
import wisp/testing

pub type Token {
  Token(token: String)
}

pub fn with_context(testcase: fn(Context) -> t) -> t {
  let config =
    Config(
      environment: Dev,
      database_config: feather.Config(
        ..feather.default_config(),
        file: ":memory:",
        foreign_keys: True,
      ),
      secret_key_base: "secret_key_base",
      secret_salt: "secret_salt",
    )

  use db <- feather.with_connection(config.database_config)

  let assert Ok(_) = database.migrate(db)

  let ctx = Context(config: config, db: db, competition_id: None)

  testcase(ctx)
}

pub fn with_competition(testcase: fn(CompetitionForm) -> t) -> t {
  let competition =
    CompetitionForm(
      name: "Mareld Nattcup E1",
      organizer: "Göteborg-Majorna OK",
      datetime: "1970-01-01T00:00:00.000",
    )

  testcase(competition)
}

pub fn with_created_competition(
  ctx: Context,
  testcase: fn(Competition, String, String) -> t,
) -> t {
  use competition <- with_competition

  let secret = "secret"

  let assert Ok(created_competition) = competition.create(ctx.db, competition)
  let assert Ok(_) = secret.create(ctx, created_competition, secret)

  let data = json.object([#("secret", json.string(secret))])
  let response =
    testing.post_json("api/auth", [], data)
    |> router.handle_request(ctx)

  let decoder = dynamic.decode1(Token, dynamic.field("token", dynamic.string))
  let assert Ok(token) = response |> testing.string_body |> json.decode(decoder)

  testcase(created_competition, secret, token.token)
}
