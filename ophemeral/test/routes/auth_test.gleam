import gleam/string
import gleam/json
import gleeunit/should
import ophemeral/router
import test_utils
import wisp/testing

pub fn authenticate_test() {
  use ctx <- test_utils.with_context
  use _, secret, _ <- test_utils.with_created_competition(ctx)

  let data = json.object([#("secret", json.string(secret))])
  let response =
    testing.post_json("api/auth", [], data)
    |> router.handle_request(ctx)

  response.status
  |> should.equal(200)

  response
  |> testing.string_body
  |> string.contains("\"token\":")
  |> should.be_true()
}

pub fn authenticate_unauthorized_test() {
  use ctx <- test_utils.with_context

  let data = json.object([#("secret", json.string("non-existing-secret"))])
  let response =
    testing.post_json("api/auth", [], data)
    |> router.handle_request(ctx)

  response.status
  |> should.equal(401)
}
