import gleam/http/request
import gwt
import sqlight
import wisp.{type Request, type Response}

pub type Context {
  Context(db: sqlight.Connection)
}

pub fn middleware(
  req: Request,
  ctx: Context,
  handle_request: fn(wisp.Request, Context) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)

  handle_request(req, ctx)
}

pub fn try_(
  result: Result(a, b),
  alternative: fn() -> Response,
  next: fn(a) -> Response,
) -> Response {
  case result {
    Ok(value) -> next(value)
    Error(_) -> alternative()
  }
}

pub fn require_authentication(
  req: Request,
  ctx: Context,
  handle_request: fn(wisp.Request, Context) -> wisp.Response,
) -> wisp.Response {
  let authorization = request.get_header(req, "authorization")

  case authorization {
    Ok("Bearer " <> token) -> {
      case gwt.from_signed_string(token, wisp.get_secret_key_base(req)) {
        Ok(_) -> handle_request(req, ctx)
        Error(_) -> wisp.response(401)
      }
    }
    Ok(_) -> wisp.response(401)
    Error(Nil) -> wisp.response(401)
  }
}
