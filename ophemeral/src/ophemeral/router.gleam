//import gleam/bytes_builder
//import gleam/erlang/process.{type Selector, type Subject}
//import gleam/http/request.{type Request}
//import gleam/http/response.{type Response}
//import gleam/io
//import gleam/json
//import gleam/option.{type Option, None, Some}
//import gleam/result
//import lustre
//import lustre/element.{type Element}
//import lustre/server_component
//import mist.{
//  type Connection, type ResponseData, type WebsocketConnection,
//  type WebsocketMessage,
//}
import ophemeral/pages/competition
import ophemeral/pages/home
import ophemeral/pages/liveresults
import ophemeral/routes/auth
import ophemeral/web
import wisp

pub fn handle_request(req: wisp.Request, ctx: web.Context) -> wisp.Response {
  use req, ctx <- web.middleware(req, ctx)

  case wisp.path_segments(req) {
    ["api", ..rest] -> api_router(rest, req, ctx)
    path_segments -> web_router(path_segments, req, ctx)
  }
}

fn web_router(
  path_segments: List(String),
  req: wisp.Request,
  ctx: web.Context,
) -> wisp.Response {
  use <- web.default_responses(ctx)

  case path_segments {
    ["lustre-server-component.min.mjs"] ->
      serve_static(
        "lustre",
        "lustre-server-component.min.mjs",
        "application/javascript",
      )
    ["copy-secret.js"] ->
      serve_static("ophemeral", "copy-secret.js", "application/javascript")
    ["competition", "dashboard"] -> competition.dashboard(req, ctx)
    ["competition", "create"] -> competition.create(req, ctx)
    ["competition", "open"] -> competition.open(req, ctx)
    ["liveresults"] -> liveresults.page(req, ctx)
    ["expire_cookie"] -> wisp.redirect("/") |> auth.expire_cookie(req)
    _ -> home.page(req, ctx)
  }
}

fn api_router(
  path_segments: List(String),
  req: wisp.Request,
  ctx: web.Context,
) -> wisp.Response {
  case path_segments {
    ["auth"] -> auth.request(req, ctx)
    _ -> wisp.not_found()
  }
}

fn serve_static(
  from: String,
  file: String,
  content_type: String,
) -> wisp.Response {
  let assert Ok(priv) = wisp.priv_directory(from)
  let path = priv <> "/static/" <> file

  wisp.response(200)
  |> wisp.set_header("content-type", content_type)
  |> wisp.set_body(wisp.File(path))
}
