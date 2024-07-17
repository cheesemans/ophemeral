insert into secrets
  (secret_hash, competition_id)
values
  ($1, $2)
returning *
