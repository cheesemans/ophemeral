update competitions
set name = $1, organizer = $2
where id = $3
returning *
