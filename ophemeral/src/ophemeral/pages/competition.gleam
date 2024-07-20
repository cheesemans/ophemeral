import gleam/order
import birl
import gleam/string_builder.{type StringBuilder}
import formal/form.{type Form}
import gleam/http.{Get, Post}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import lustre/attribute.{attribute}
import lustre/element.{type Element}
import lustre/element/html.{html, text}
import ophemeral/models/competition.{CompetitionForm}
import ophemeral/models/secret
import ophemeral/web.{type Context, Context}
import wisp.{type Request, type Response}

type OpenForm {
  OpenForm(secret: String)
}

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
      |> wisp.html_response(200)
    }
    None -> wisp.not_found()
  }
}

pub fn open(req: Request, ctx: Context) -> Response {
  case ctx.competition_id {
    Some(_) -> wisp.redirect("/competition/dashboard")
    None ->
      case req.method {
        Get -> 
          form.new() 
          |> render_open_form(ctx) 
          |> wisp.html_response(200)
        Post -> attempt_open_competition(req, ctx)
        _ -> wisp.method_not_allowed([Get, Post])
      }
  }
}

pub fn create(req: Request, ctx: Context) -> Response {
  case req.method {
    Get -> 
      form.new() 
      |> render_competition_form(ctx) 
      |> wisp.html_response(200)
    Post -> attempt_create_competition(req, ctx)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

fn attempt_open_competition(req: Request, ctx: Context) {
  use formdata <- wisp.require_form(req)

  let result =
    form.decoding({
      use secret <- form.parameter
      OpenForm(secret: secret)
    })
    |> form.with_values(formdata.values)
    |> form.field("secret", form.string |> form.and(form.must_not_be_empty) |> and_with_context(secret.validate_form_secret, ctx))
    |> form.finish

  case result {
    Ok(value) -> {
      let assert Ok(Some(secret)) = secret.get_secret(value.secret, ctx)
      wisp.redirect("/competition/dashboard")
      |> wisp.set_cookie(
        req,
        "competition_id",
        int.to_string(secret.competition_id),
        wisp.Signed,
        60 * 60,
      )
      }
    Error(form) ->
      render_open_form(form, ctx)
      |> wisp.html_response(422)
  }
}

fn and_with_context(
  previous: fn(a) -> Result(b, String),
  next: fn(b, Context) -> Result(c, String),
  ctx: Context,
) -> fn(a) -> Result(c, String) {
  fn(data) {
    case previous(data) {
      Ok(value) -> next(value, ctx)
      Error(error) -> Error(error)
    }
  }
}

fn attempt_create_competition(req: Request, ctx: Context) {
  use formdata <- wisp.require_form(req)

  let result =
    form.decoding({
      use name <- form.parameter
      use organizer <- form.parameter
      use datetime <- form.parameter
      CompetitionForm(name: name, organizer: organizer, datetime: datetime)
    })
    |> form.with_values(formdata.values)
    |> form.field("name", form.string |> form.and(form.must_not_be_empty) |> and_with_context(competition.validate_form_name, ctx))
    |> form.field("organizer", form.string |> form.and(form.must_not_be_empty))
    |> form.field("datetime-local", form.string |> form.and(form.must_not_be_empty) |> form.and(validate_form_date))
    |> form.finish

  case result {
    Ok(values) -> {
        let assert Ok(competition) = competition.create(ctx.db, values)

        let secret = wisp.random_string(16)

        let assert Ok(_) = secret.create(ctx, competition, secret)

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
        |> wisp.html_response(200)
        |> wisp.set_cookie(
          req,
          "competition_id",
          int.to_string(competition.id),
          wisp.Signed,
          60 * 60,
        )
      }
    Error(form) -> 
      render_competition_form(form, ctx)
      |> wisp.html_response(422)
  }
}

fn validate_form_date(value: String) -> Result(String, String) {
  case birl.from_naive(value) {
    Ok(time) -> {
      case birl.compare(time, birl.now()) {
        order.Lt -> Error("Pick a time in the future!")
        _ -> Ok(birl.to_naive(time))
      }
    }
    Error(_) -> Error("")
  }
}

fn render_competition_form(form: Form, ctx: Context) -> StringBuilder {
  let content = [
    html.div([attribute.class("grid")], [
      html.div([], []),
      render_form([
        form_field(
          form,
          name: "name",
          kind: "text",
          placeholder: Some("Name"),
          title: "Name",
        ),
        form_field(
          form,
          name: "organizer",
          kind: "text",
          placeholder: Some("Organizer"),
          title: "Organizer",
        ),
        form_field(
          form,
          name: "datetime-local",
          kind: "datetime-local",
          placeholder: None,
          title: "Date",
        ),
        html.input([attribute.value("Create"), attribute.type_("submit")]),
      ]),
      html.div([], []),
    ]),
  ]

  content
  |> web.html_page(ctx)
}

fn render_open_form(form: Form, ctx: Context) -> StringBuilder{
  let content = [
    html.div([attribute.class("grid")], [
      html.div([], []),
      render_form([
        form_field(
          form,
          name: "secret",
          kind: "password",
          placeholder: Some("Secret"),
          title: "Secret key",
        ),
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
      html.div([], []),
    ]),
  ]

  content
  |> web.html_page(ctx)
}

fn render_form(elements: List(Element(a))) -> Element(a) {
  html.form([attribute.method("post")], [html.fieldset([], elements)])
}

fn form_field(
  form: Form,
  name name: String,
  kind kind: String,
  title title: String,
  placeholder placeholder: Option(String),
) -> Element(a) {
  // Make an element containing the error message, if there is one.
  let #(error_element, error_attributes) = case form.field_state(form, name) {
    Ok(_) -> #(element.none(), [attribute.none()])
    Error(message) -> #(
      html.small([attribute.id("invalid-helper")], [element.text(message)]),
      [
        attribute("aria-invalid", "true"),
        attribute("aria-describedby", "invalid-helper"),
      ],
    )
  }

  let placeholder = case placeholder {
    Some(placeholder) -> attribute.placeholder(placeholder)
    None -> attribute.none()
  }

  html.label([], [
    text(title),
    html.input(
      list.flatten([
        [
          attribute.type_(kind),
          attribute.name(name),
          placeholder,
        ],
        error_attributes,
      ]),
    ),
    error_element,
  ])
}
