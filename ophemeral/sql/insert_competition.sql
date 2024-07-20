insert into competitions
  (name, organizer, datetime)
values
  ($1, $2, $3)
returning *
