import birl
import decode
import gleam/dynamic
import gleam/int
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/result
import gwt
import ophemeral/error.{type Error}
import ophemeral/models/secret
import ophemeral/web
import wisp.{type Request, type Response}

type Secret {
  Secret(secret: String)
}

fn decode_json(data) -> Result(Secret, dynamic.DecodeErrors) {
  decode.into({
    use secret <- decode.parameter
    Secret(secret)
  })
  |> decode.field("secret", decode.string)
  |> decode.from(data)
}

pub fn request(req: wisp.Request, ctx: web.Context) -> wisp.Response {
  use data <- wisp.require_json(req)

  use secret <- web.try_(decode_json(data), wisp.unprocessable_entity)

  case secret.get_secret(secret.secret, ctx) {
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

pub fn get_competition_id_from_cookie(
  req: Request,
  next: fn(Option(Int)) -> Response,
) -> Response {
  let id =
    wisp.get_cookie(req, "competition_id", wisp.Signed)
    |> result.unwrap("")
    |> int.parse

  case id {
    Ok(id) -> next(Some(id))
    Error(_) -> next(None)
  }
}

pub fn expire_cookie(response: Response, req: Request) -> Response {
  use id <- get_competition_id_from_cookie(req)

  case id {
    Some(id) -> {
      response
      |> wisp.set_cookie(
        req,
        "competition_id",
        int.to_string(id),
        wisp.Signed,
        0,
      )
    }
    None -> response
  }
}
