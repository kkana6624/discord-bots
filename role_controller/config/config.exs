import Config

config :nostrum,
  token: System.get_env("DISCORD_TOKEN") || "dummy",
  gateway_intents: [:guilds, :guild_members]

config :role_controller,
  guild_id: System.get_env("GUILD_ID") || "0",
  role_a_id: System.get_env("ROLE_A_ID") || "0",
  role_b_id: System.get_env("ROLE_B_ID") || "0",
  target_role_c_id: System.get_env("TARGET_ROLE_C_ID") || "0"
