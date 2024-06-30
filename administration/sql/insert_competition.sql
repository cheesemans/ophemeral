insert into competitions
  (name, organizer)
values
  ($1, $2)
returning *
