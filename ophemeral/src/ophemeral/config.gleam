import dot_env as dot
import dot_env/env
import feather

pub type Config {
  Config(
    environment: Environment,
    database_config: feather.Config,
    secret_key_base: String,
    secret_salt: String,
  )
}

pub type Environment {
  Dev
  Staging
  Prod
}

pub fn read() -> Config {
  let environment = case determine_environment() {
    Dev -> {
      dot.new()
      |> dot.set_path(".env")
      |> dot.set_debug(True)
      |> dot.load

      Dev
    }
    Staging -> Staging
    Prod -> Prod
  }

  let assert Ok(secret_key_base) = env.get_string("SECRET_KEY_BASE")
  let assert Ok(secret_salt) = env.get_string("SECRET_SALT")
  let assert Ok(database_path) = env.get_string("DATABASE_PATH")

  let database_config =
    feather.Config(
      ..feather.default_config(),
      file: database_path,
      foreign_keys: True,
    )

  Config(
    environment: environment,
    database_config: database_config,
    secret_key_base: secret_key_base,
    secret_salt: secret_salt,
  )
}

fn determine_environment() -> Environment {
  case env.get_string("ENVIRONMENT") {
    Ok("prod") -> Prod
    Ok("staging") -> Staging
    _ -> Dev
  }
}
