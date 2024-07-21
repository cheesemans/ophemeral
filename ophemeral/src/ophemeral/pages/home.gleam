import lustre/attribute.{attribute}
import lustre/element/html.{html, text}
import ophemeral/web.{type Context}
import wisp.{type Request, type Response}

pub fn page(_req: Request, ctx: Context) -> Response {
  let content = [
    html.hgroup([], [
      html.h1([], [text("Ophemeral")]),
      html.p([], [text("Simple administration of Orienteering events")]),
    ]),
    html.a([attribute.href("/competition/create"), attribute.role("button")], [
      text("Create competition"),
    ]),
  ]

  content
  |> web.html_page(ctx)
  |> wisp.html_response(200)
}
