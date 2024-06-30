import administration/error
import administration/models/competition.{Competition}
import gleam/option.{None, Some}
import gleeunit/should
import test_utils

const expected = Competition(
  id: 1,
  name: "Mareld Nattcup E1",
  organizer: "Göteborg-Majorna OK",
)

pub fn insert_new_competition_test() {
  use ctx <- test_utils.with_context
  use competition <- test_utils.with_competition

  let assert Ok(result) = competition.create(ctx.db, competition)

  result
  |> should.equal(expected)
}

pub fn insert_existing_competition_test() {
  use ctx <- test_utils.with_context
  use competition <- test_utils.with_competition

  let assert Ok(_) = competition.create(ctx.db, competition)

  let assert Error(error.CompetitionNameAlreadyInUse) =
    competition.create(ctx.db, competition)
}

pub fn get_competition_by_id_test() {
  use ctx <- test_utils.with_context
  use competition <- test_utils.with_competition

  let assert Ok(_) = competition.create(ctx.db, competition)

  let assert Ok(Some(result)) = competition.get_by_id(ctx.db, 1)

  result
  |> should.equal(expected)
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
    Competition(id: 1, name: "Mareld Nattcup E2", organizer: "Sävedalens AIK")

  let assert Ok(result) = competition.update(ctx.db, updated_competition)

  result
  |> should.equal(updated_competition)
}

pub fn update_competition_name_to_existing_name_test() {
  use ctx <- test_utils.with_context
  use competition <- test_utils.with_competition

  let updated_competition =
    Competition(id: 1, name: "Mareld Nattcup E2", organizer: "Sävedalens AIK")

  let assert Ok(_) = competition.create(ctx.db, competition)
  let assert Ok(_) = competition.create(ctx.db, updated_competition)

  let assert Error(error.CompetitionNameAlreadyInUse) =
    competition.update(ctx.db, updated_competition)
}
