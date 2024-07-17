import gleam/list
import lustre/attribute.{attribute}
import lustre/element/html.{html, text}
import ophemeral/models/competition
import ophemeral/web.{type Context}
import wisp.{type Request, type Response}

pub fn page(_req: Request, ctx: Context) -> Response {
  let competitions = competition.get_all(ctx.db)

  let content = [
    html.table([], [
      html.thead([], [
        html.tr([], [
          html.th([attribute("scope", "col")], [text("Name")]),
          html.th([attribute("scope", "col")], [text("Organizer")]),
        ]),
      ]),
      html.tbody(
        [],
        list.map(competitions, fn(competition) {
          html.tr([], [
            html.th([attribute("scope", "row")], [text(competition.name)]),
            html.td([], [text(competition.organizer)]),
          ])
        }),
      ),
    ]),
  ]

  content
  |> web.html_page(ctx)
  |> web.serve_html
}
