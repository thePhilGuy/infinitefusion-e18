module StartMenuExtensions
  Command = Struct.new(:name, :handler)

  @commands = []

  def self.add(name, &handler)
    @commands << Command.new(name, handler)
  end

  def self.commands
    @commands
  end

  module ScenePatch
    def pbShowCommands(commands)
      loop do
        extras = StartMenuExtensions.commands
        original_count = commands.length

        extended = commands.dup
        extended.concat(extras.map { |cmd| cmd.name })

        choice = super(extended)

        # Includes -1/Back, because -1 < original_count.
        # Let the original pause menu handle all original choices.
        return choice if choice < original_count

        extras[choice - original_count].handler.call(self)
      end
    end
  end
end

StartMenuExtensions.add(_INTL("PC")) do |scene|
  pbPlayDecisionSE
  pbFadeOutIn {
    storage_scene = PokemonStorageScene.new
    storage = PokemonStorageScreen.new(storage_scene, $PokemonStorage)
    storage.pbStartScreen(0)
    scene.pbRefresh
  }
end

PokemonPauseMenu_Scene.prepend(StartMenuExtensions::ScenePatch)