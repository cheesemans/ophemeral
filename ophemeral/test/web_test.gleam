import gleam/http/request
import gleam/json
import gleeunit/should
import ophemeral/router
import test_utils
import wisp/testing

fn competition_json() -> json.Json {
  json.object([
    #("id", json.int(1)),
    #("name", json.string("Mareld Nattcup E2")),
    #("organizer", json.string("Göteborg-Majorna OK")),
  ])
}

// TODO: Enable these once there exists endpoints to test towards!

//pub fn authentication_test() {
//  use ctx <- test_utils.with_context
//  use _, _, token <- test_utils.with_created_competition(ctx)
//
//  let response =
//    testing.patch_json("api/competition", [], competition_json())
//    |> request.set_header("authorization", "Bearer " <> token)
//    |> router.handle_request(ctx)
//
//  response.status
//  |> should.equal(200)
//}
//
//pub fn authentication_no_header_test() {
//  use ctx <- test_utils.with_context
//
//  let response =
//    testing.patch_json("api/competition", [], competition_json())
//    |> router.handle_request(ctx)
//
//  response.status
//  |> should.equal(401)
//}
//
//pub fn authentication_unauthorized_token_test() {
//  use ctx <- test_utils.with_context
//
//  let response =
//    testing.patch_json("api/competition", [], competition_json())
//    |> request.set_header("authorization", "Bearer non-valid-token")
//    |> router.handle_request(ctx)
//
//  response.status
//  |> should.equal(401)
//}
