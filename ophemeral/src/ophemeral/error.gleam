import gleam/dynamic
import sqlight

pub type Error {
  DatabaseError(sqlight.Error)
  DecodeErrors(dynamic.DecodeErrors)
  CompetitionNameAlreadyInUse
}
