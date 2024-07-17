import gleam/bool
import gleam/http/request
import gleam/option.{type Option, None, Some}
import gwt
import lustre/attribute.{attribute}
import lustre/element.{type Element, text}
import lustre/element/html
import sqlight
import wisp.{type Request, type Response}

pub type Context {
  Context(db: sqlight.Connection, competition_id: Option(Int))
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

pub fn require_competition_id(
  ctx: Context,
  handle_request: fn(Int) -> wisp.Response,
) -> wisp.Response {
  case ctx.competition_id {
    Some(id) -> handle_request(id)
    None -> wisp.response(401)
  }
}

pub fn serve_html(body: Element(a)) -> wisp.Response {
  wisp.response(200)
  |> wisp.set_header("content-type", "text/html")
  |> wisp.set_body(
    body
    |> element.to_string_builder
    |> wisp.Text,
  )
}

pub fn default_responses(
  ctx,
  handle_request: fn() -> wisp.Response,
) -> wisp.Response {
  let response = handle_request()

  use <- bool.guard(
    when: response.body != wisp.Empty || response.status == 303,
    return: response,
  )

  case response.status {
    404 | 405 ->
      [html.h1([], [text("There's nothing here 🤷")])]
      |> html_page(ctx)
      |> serve_html
    401 ->
      [html.h1([], [text("⛔ You're not authorized to here ⛔")])]
      |> html_page(ctx)
      |> serve_html
    400 | 422 ->
      [html.h1([], [text("Bad request 🤕")])]
      |> html_page(ctx)
      |> serve_html
    413 ->
      [html.h1([], [text("Request entity too large ")])]
      |> html_page(ctx)
      |> serve_html
    500 ->
      [html.h1([], [text("💣 Internal server error 💣")])]
      |> html_page(ctx)
      |> serve_html
    _ -> wisp.redirect("/")
  }
}

pub fn html_page(content: List(Element(a)), ctx: Context) -> Element(a) {
  html.html([], [
    html.head([], [
      html.meta([attribute("charset", "utf-8")]),
      html.meta([
        attribute.name("viewport"),
        attribute("content", "width=device-width, initial-scale=1"),
      ]),
      html.title([], "🌲 ophemeral"),
      html.link([
        attribute.rel("stylesheet"),
        attribute.href(
          "https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.jade.min.css",
        ),
      ]),
    ]),
    html.body([], [
      navbar(ctx),
      html.main([attribute.class("container")], content),
      footer(),
    ]),
  ])
}

pub fn navbar(ctx: Context) -> Element(a) {
  html.header([attribute.class("container")], [
    html.nav([], [
      html.ul([], [
        html.li([attribute.href("/")], [
          html.h2([], [
            html.a([attribute.href("/"), attribute.class("contrast")], [
              text("Ophemeral"),
            ]),
          ]),
        ]),
      ]),
      html.ul([], [
        html.li([], [
          html.a([attribute.href("/liveresults")], [text("Liveresults")]),
        ]),
        html.li([], [
          case ctx.competition_id {
            Some(_) -> {
              html.a(
                [
                  attribute.href("/competition/dashboard"),
                  attribute.role("button"),
                ],
                [text("Dashboard")],
              )
            }
            None -> {
              html.a(
                [
                  attribute.href("/competition/open"),
                  attribute.class("secondary"),
                  attribute.role("button"),
                ],
                [text("Open competition")],
              )
            }
          },
        ]),
      ]),
    ]),
  ])
}

pub fn footer() -> Element(a) {
  html.footer([attribute.class("container")], [])
}
