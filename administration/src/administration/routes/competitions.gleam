import administration/error.{type Error}
import administration/models/competition
import administration/models/secret
import administration/web
import beecrypt
import gleam/http.{Get, Patch, Post}
import gleam/int
import gleam/json
import gleam/option.{None, Some}
import gleam/io
import wisp

const invalid_data_msg = "Invalid request data"

const competition_name_in_use = "The provided competition name is already in use!"

pub fn request(req: wisp.Request, ctx: web.Context) -> wisp.Response {
  case req.method {
    Post -> post(req, ctx)
    Patch -> patch(req, ctx)
    _ -> wisp.method_not_allowed([Post])
  }
}

pub fn request_with_id(
  req: wisp.Request,
  ctx: web.Context,
  id: String,
) -> wisp.Response {
  use id <- web.try_(int.parse(id), wisp.bad_request)

  case req.method {
    Get -> get(ctx, id)
    _ -> wisp.method_not_allowed([Get])
  }
}

fn get(ctx: web.Context, id: Int) -> wisp.Response {
  case competition.get_by_id(ctx.db, id) {
    Ok(Some(competition)) -> {
      competition.json_encoder(competition)
      |> wisp.json_response(200)
    }
    Ok(None) -> wisp.not_found()
    Error(_) -> wisp.internal_server_error()
  }
}

fn patch(req: wisp.Request, ctx: web.Context) -> wisp.Response {
  use req, ctx <- web.require_authentication(req, ctx)
  use json <- wisp.require_json(req)

  use competition <- web.try_(
    competition.json_decoder(json),
    wisp.unprocessable_entity,
  )

  io.debug(competition)

  case competition.update(ctx.db, competition) {
    Ok(competition) -> {
      competition.json_encoder(competition)
      |> wisp.json_response(200)
    }
    Error(e) -> {
      io.debug(e)
      wisp.internal_server_error()
    }
    //Error(_) -> wisp.internal_server_error()
  }
}

fn post(req: wisp.Request, ctx: web.Context) -> wisp.Response {
  use json <- wisp.require_json(req)

  use competition <- web.try_(
    competition.json_decoder(json),
    wisp.unprocessable_entity,
  )

  case competition.create(ctx.db, competition) {
    Ok(competition) -> {
      let secret = wisp.random_string(16)
      let hash = beecrypt.hash(secret)

      let assert Ok(_) = secret.create(ctx.db, competition, hash)

      json.object([
        #("id", json.int(competition.id)),
        #("secret", json.string(secret)),
      ])
      |> json.to_string_builder
      |> wisp.json_response(201)
    }
    Error(error.CompetitionNameAlreadyInUse) -> {
      json.object([
        #("message", json.string(invalid_data_msg)),
        #("reason", json.string(competition_name_in_use)),
      ])
      |> json.to_string_builder
      |> wisp.json_response(400)
    }
    Error(_) -> wisp.internal_server_error()
  }
}
