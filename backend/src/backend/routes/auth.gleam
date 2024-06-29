import backend/error.{type Error}
import backend/models/secret
import backend/web
import birl
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gwt
import wisp

pub fn request(req: wisp.Request, ctx: web.Context) -> wisp.Response {
  use form <- wisp.require_form(req)

  use secret <- web.try_(
    list.key_find(form.values, "secret"),
    wisp.unprocessable_entity,
  )

  case secret.validate_secret(ctx.db, secret) {
    Ok(Some(_)) -> {
      let token_expire_time = birl.to_unix(birl.now()) + 600

      let token =
        gwt.new()
        |> gwt.set_expiration(token_expire_time)
        |> gwt.to_signed_string(gwt.HS256, wisp.get_secret_key_base(req))

      let object = json.object([#("token", json.string(token))])

      json.to_string_builder(object)
      |> wisp.json_response(200)
    }
    Ok(None) -> wisp.response(401)
    Error(_) -> wisp.internal_server_error()
  }
}
