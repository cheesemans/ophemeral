insert into secrets
  (hash, competition_id)
values
  ($1, $2)
returning *
