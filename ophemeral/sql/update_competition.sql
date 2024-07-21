update competitions
set name = $1, organizer = $2, datetime = $3
where id = $4
returning *
