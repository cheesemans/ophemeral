import administration/models/competition
import administration/router
import gleam/http/request
import gleam/int
import gleam/json
import gleam/string
import gleeunit/should
import test_utils
import wisp/testing

fn competition_json() -> json.Json {
  json.object([
    #("id", json.int(0)),
    #("name", json.string("Mareld Nattcup E1")),
    #("organizer", json.string("Göteborg-Majorna OK")),
  ])
}

pub fn create_competition_test() {
  use ctx <- test_utils.with_context

  let response =
    testing.post_json("/competition", [], competition_json())
    |> router.handle_request(ctx)

  response.status
  |> should.equal(201)

  response
  |> testing.string_body
  |> string.contains("\"secret\":")
  |> should.be_true()
}

pub fn create_existing_competition_test() {
  use ctx <- test_utils.with_context
  use competition <- test_utils.with_competition

  let _ = competition.create(ctx.db, competition)

  let response =
    testing.post_json("/competition", [], competition_json())
    |> router.handle_request(ctx)

  response.status
  |> should.equal(400)

  response
  |> testing.string_body
  |> should.equal(
    "{\"message\":\"Invalid request data\",\"reason\":\"The provided competition name is already in use!\"}",
  )
}

pub fn get_competition_test() {
  use ctx <- test_utils.with_context
  use competition, _, token <- test_utils.with_created_competition(ctx)

  let id = int.to_string(competition.id)

  let response =
    testing.get("/competition/" <> id, [])
    |> request.set_header("authorization", "Bearer " <> token)
    |> router.handle_request(ctx)

  response.status
  |> should.equal(200)

  response
  |> testing.string_body
  |> should.equal(
    "{\"id\":"
    <> id
    <> ",\"name\":\""
    <> competition.name
    <> "\""
    <> ",\"organizer\":\""
    <> competition.organizer
    <> "\"}",
  )
}
