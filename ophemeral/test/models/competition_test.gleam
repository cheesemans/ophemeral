import gleam/result
import birl/duration
import gleam/option.{None, Some}
import gleeunit/should
import ophemeral/models/competition.{type Competition, Competition, CompetitionForm}
import test_utils
import birl

fn expected_competition() -> Competition {
  Competition(
    id: 1,
    name: "Mareld Nattcup E1",
    organizer: "Göteborg-Majorna OK",
    datetime: birl.from_unix(0),
  )
}

pub fn insert_new_competition_test() {
  use ctx <- test_utils.with_context
  use competition <- test_utils.with_competition

  let assert Ok(result) = competition.create(ctx.db, competition)

  result
  |> should.equal(expected_competition())
}

pub fn get_competition_by_id_test() {
  use ctx <- test_utils.with_context
  use competition <- test_utils.with_competition

  let assert Ok(_) = competition.create(ctx.db, competition)

  let assert Ok(Some(result)) = competition.get_by_id(ctx.db, 1)

  result
  |> should.equal(expected_competition())
}

pub fn get_competition_by_id_not_found_test() {
  use ctx <- test_utils.with_context

  let assert Ok(None) = competition.get_by_id(ctx.db, 1)
}

pub fn update_competition_test() {
  use ctx <- test_utils.with_context
  use competition <- test_utils.with_competition

  let assert Ok(_) = competition.create(ctx.db, competition)

  let updated_competition =
    Competition(id: 1, name: "Mareld Nattcup E2", organizer: "Sävedalens AIK", datetime: birl.from_unix(12345))

  let assert Ok(result) = competition.update(ctx.db, updated_competition)

  result
  |> should.equal(updated_competition)
}

pub fn validate_form_name_test() {
  use ctx <- test_utils.with_context
  use competition <- test_utils.with_competition
  let assert Ok(_) = competition.create(ctx.db, competition)

  let assert Ok(_) = competition.validate_form_name("Competition name not in use", ctx)
}

pub fn validate_form_name_exact_name_in_use_test() {
  use ctx <- test_utils.with_context
  use competition <- test_utils.with_competition
  let assert Ok(_) = competition.create(ctx.db, competition)

  let assert Error("Competition name is already in use!") = competition.validate_form_name(competition.name, ctx)
}

pub fn validate_form_name_case_conflict_test() {
  use ctx <- test_utils.with_context
  use competition <- test_utils.with_competition
  let assert Ok(_) = competition.create(ctx.db, competition)

  let assert Error("Competition name is already in use!") = competition.validate_form_name("mareld nattcup e1", ctx)
}

pub fn delete_competitions_test() {
  use ctx <- test_utils.with_context

  let new_competition = 
    CompetitionForm(
      name: "Mareld Nattcup E1",
      organizer: "Göteborg-Majorna OK",
      datetime: "1970-01-01T00:00:00.000",
    )
  let old_competition = 
    CompetitionForm(
      name: "Mareld Nattcup E2",
      organizer: "Göteborg-Majorna OK",
      datetime: "1970-01-01T00:00:00.000",
    )
  let assert Ok(new) = competition.create(ctx.db, new_competition)
  let assert Ok(old) = competition.create(ctx.db, old_competition)

  let updated_new_competition = Competition(..new, datetime: birl.now() |> birl.to_naive |> birl.from_naive |> result.unwrap(birl.now()))
  let updated_old_competition = Competition(..old, datetime: birl.subtract(birl.now(), duration.months(4)))

  let assert Ok(_) = competition.update(ctx.db, updated_new_competition)
  let assert Ok(_) = competition.update(ctx.db, updated_old_competition)

  competition.delete_old(ctx)

  let competitions = competition.get_all(ctx)

  competitions
  |> should.equal([updated_new_competition])
}
