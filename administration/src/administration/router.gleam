import administration/routes/auth
import administration/routes/competitions
import administration/web
import wisp

pub fn handle_request(req: wisp.Request, ctx: web.Context) -> wisp.Response {
  use req, ctx <- web.middleware(req, ctx)

  case wisp.path_segments(req) {
    ["auth"] -> auth.request(req, ctx)
    ["competition"] -> competitions.request(req, ctx)
    ["competition", id] -> competitions.request_with_id(req, ctx, id)
    _ -> wisp.not_found()
  }
}
