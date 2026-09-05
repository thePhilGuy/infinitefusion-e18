module Settings
  # Keep the local DownloadedSettings.rb. Set false to allow upstream updates.
  FREEZE_REMOTE_SETTINGS = true

  # The odds of a newly generated Pokémon being shiny (out of 65536).
  SHINY_POKEMON_CHANCE = 3277 #(MECHANICS_GENERATION >= 6) ? 16 : 8
  STARTUP_MESSAGES = "ZZZ_SETTINGS LOADED."
  # FISHING_AUTO_HOOK = true  
end

module FrozenRemoteSettings
  private

  def updateHttpSettingsFile
    return if Settings::FREEZE_REMOTE_SETTINGS
    super
  end
end

Object.prepend(FrozenRemoteSettings)
