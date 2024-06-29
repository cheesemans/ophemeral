import backend/router
import gleam/string
import gleeunit/should
import test_utils
import wisp/testing

pub fn authenticate_test() {
  use ctx <- test_utils.with_context
  use _, secret, _ <- test_utils.with_created_competition(ctx)

  let data = [#("secret", secret)]
  let response =
    testing.post_form("/auth", [], data)
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

  let data = [#("secret", "non-existing-secret")]
  let response =
    testing.post_form("/auth", [], data)
    |> router.handle_request(ctx)

  response.status
  |> should.equal(401)
}
