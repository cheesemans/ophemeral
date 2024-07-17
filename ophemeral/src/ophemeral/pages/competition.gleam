import beecrypt
import gleam/http.{Get, Post}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import lustre/attribute.{attribute}
import lustre/element/html.{html, text}
import ophemeral/error
import ophemeral/models/competition
import ophemeral/models/secret
import ophemeral/web.{type Context, Context}
import wisp.{type Request, type Response}

pub fn dashboard(_req: Request, ctx: Context) -> Response {
  use competition_id <- web.require_competition_id(ctx)

  let competition_data =
    competition.get_by_id(ctx.db, competition_id)
    |> result.unwrap(None)

  case competition_data {
    Some(data) -> {
      let content = [
        html.p([], [text("Competition name: " <> data.name)]),
        html.p([], [text("Competition organizer: " <> data.organizer)]),
        html.a([attribute.href("/expire_cookie"), attribute.role("button")], [
          text("Close competition"),
        ]),
      ]

      content
      |> web.html_page(ctx)
      |> web.serve_html
    }
    None -> wisp.not_found()
  }
}

pub fn open(req: Request, ctx: Context) -> Response {
  case ctx.competition_id {
    Some(_) -> wisp.redirect("/competition/dashboard")
    None ->
      case req.method {
        Get -> open_form(ctx, False)
        Post -> open_competition(req, ctx)
        _ -> wisp.method_not_allowed([Get, Post])
      }
  }
}

pub fn create(req: Request, ctx: Context) -> Response {
  case req.method {
    Get -> create_form(ctx, False)
    Post -> create_competition(req, ctx)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

fn open_competition(req: Request, ctx: Context) {
  use form_data <- wisp.require_form(req)

  use secret <- web.try_(
    list.key_find(form_data.values, "secret"),
    wisp.unprocessable_entity,
  )

  case secret.validate_secret(ctx.db, secret) {
    Ok(Some(secret)) -> {
      wisp.redirect("/competition/dashboard")
      |> wisp.set_cookie(
        req,
        "competition_id",
        int.to_string(secret.competition_id),
        wisp.Signed,
        60 * 60,
      )
    }
    Ok(None) -> {
      open_form(ctx, True)
    }
    Error(_) -> wisp.internal_server_error()
  }
}

fn create_competition(req: Request, ctx: Context) {
  use form_data <- wisp.require_form(req)

  io.debug(form_data)
  use name <- web.try_(
    list.key_find(form_data.values, "name"),
    wisp.unprocessable_entity,
  )
  use organizer <- web.try_(
    list.key_find(form_data.values, "organizer"),
    wisp.unprocessable_entity,
  )

  let competition =
    competition.Competition(id: 0, name: name, organizer: organizer)

  case competition.create(ctx.db, competition) {
    Ok(competition) -> {
      let secret = wisp.random_string(16)
      let hash = beecrypt.hash(secret)

      let assert Ok(_) = secret.create(ctx.db, competition, hash)

      let ctx = Context(..ctx, competition_id: Some(competition.id))

      [
        html.div([attribute.class("grid")], [
          html.div([], []),
          html.form([], [
            html.h4([], [text("Competition successfully created")]),
            html.label([attribute.for("copy-secret")], [text("Secret key")]),
            html.fieldset([attribute.role("group")], [
              html.input([
                attribute.id("copy-secret"),
                attribute.value(secret),
                attribute("disabled", ""),
              ]),
              html.input([
                attribute.value("Copy 📋"),
                attribute.id("copy-button"),
                attribute.type_("submit"),
              ]),
            ]),
            html.p([], [text("This is your credential for the competition!")]),
          ]),
          html.div([], []),
          html.script(
            [attribute.src("/copy-secret.js"), attribute.type_("module")],
            "",
          ),
        ]),
      ]
      |> web.html_page(ctx)
      |> web.serve_html
      |> wisp.set_cookie(
        req,
        "competition_id",
        int.to_string(competition.id),
        wisp.Signed,
        60 * 60,
      )
    }
    Error(error.CompetitionNameAlreadyInUse) -> {
      wisp.log_error(
        "Competition with name " <> competition.name <> " already exists!",
      )
      create_form(ctx, True)
    }
    Error(_) -> wisp.internal_server_error()
  }
}

fn create_form(ctx: Context, is_invalid: Bool) {
  let content = [
    html.div([attribute.class("grid")], [
      html.div([], []),
      html.form([attribute.method("post")], [
        html.fieldset([], [
          case is_invalid {
            True -> {
              html.label([], [
                text("Name"),
                html.input([
                  attribute.placeholder("Name"),
                  attribute.name("name"),
                  attribute("aria-invalid", "true"),
                  attribute("aria-describedby", "invalid-helper"),
                ]),
                html.small([attribute.id("invalid-helper")], [
                  text("A competition with this name already exists!"),
                ]),
              ])
            }
            False -> {
              html.label([], [
                text("Name"),
                html.input([
                  attribute.placeholder("Name"),
                  attribute.name("name"),
                ]),
              ])
            }
          },
          html.label([], [
            text("Organizer"),
            html.input([
              attribute.placeholder("Organizer"),
              attribute.name("organizer"),
            ]),
          ]),
          html.label([], [
            text("Date"),
            html.input([
              attribute("aria-label", "Date"),
              attribute.name("date"),
              attribute.type_("date"),
            ]),
          ]),
        ]),
        html.input([attribute.value("Create"), attribute.type_("submit")]),
      ]),
      html.div([], []),
    ]),
  ]

  content
  |> web.html_page(ctx)
  |> web.serve_html
}

fn open_form(ctx: Context, is_invalid: Bool) {
  let content = [
    html.div([attribute.class("grid")], [
      html.div([], []),
      html.form([attribute.method("post")], [
        html.fieldset([], [
          case is_invalid {
            True -> {
              html.label([], [
                text("Secret key"),
                html.input([
                  attribute.placeholder("Secret"),
                  attribute.name("secret"),
                  attribute.type_("password"),
                  attribute("aria-invalid", "true"),
                  attribute("aria-describedby", "invalid-helper"),
                ]),
                html.small([attribute.id("invalid-helpter")], [
                  text("No competition found for the secret key"),
                ]),
              ])
            }
            False -> {
              html.label([], [
                text("Secret key"),
                html.input([
                  attribute.placeholder("Secret"),
                  attribute.name("secret"),
                  attribute.type_("password"),
                ]),
              ])
            }
          },
          html.input([attribute.value("Open"), attribute.type_("submit")]),
          html.p([], [text("Or...")]),
          html.div(
            [
              attribute.role("button"),
              attribute("onclick", "window.location='/competition/create'"),
            ],
            [text("Create new competition")],
          ),
        ]),
      ]),
      html.div([], []),
    ]),
  ]

  content
  |> web.html_page(ctx)
  |> web.serve_html
}
