module RemoteDayCare
  MENU_LABEL = _INTL("Day Care").dup
  @ready_handlers = []

  class << self
    def on_egg_ready(&handler)
      @ready_handlers << handler
    end

    def egg_ready!
      @ready_handlers.dup.each(&:call)
    end

    def egg_waiting?
      $PokemonGlobal && pbEggGenerated?
    end

    def sync_menu_label!
      MENU_LABEL.replace(egg_waiting? ? _INTL("Day Care *") : _INTL("Day Care"))
    end

    def deposited_pokemon
      return [] if !$PokemonGlobal || !$PokemonGlobal.daycare
      $PokemonGlobal.daycare.first(2).map { |slot| slot && slot[0] }.compact
    end

    def gender_text(pokemon)
      return _INTL("♂") if pokemon.male?
      return _INTL("♀") if pokemon.female?
      _INTL("genderless")
    end

    def show_daycare_status
      pokemon = deposited_pokemon
      if pokemon.empty?
        pbMessage(_INTL("There are no Pokémon in the Day Care."))
        return
      end

      lines = pokemon.map do |pkmn|
        _INTL("{1} ({2})", pkmn.name, gender_text(pkmn))
      end
      pbMessage(_INTL("Pokémon in the Day Care:\n{1}", lines.join("\n")))
    end

    def collect
      return [:none, nil] unless egg_waiting?
      return [:full, nil] if pbBoxesFull?

      destination = $Trainer.party_full? ? :pc : :party
      egg = pbDayCareGenerateEgg
      return [:none, nil] unless egg

      $PokemonGlobal.daycareEgg = 0
      $PokemonGlobal.daycareEggSteps = 0

      [destination, egg]
    end

    def collect_and_report
      destination, egg = collect

      case destination
      when :party
        pbMessage(_INTL("The Day Care sent you the Egg!"))
      when :pc
        pbMessage(_INTL("The Day Care emailed the Egg to your PC!"))
      when :full
        pbMessage(_INTL("Your party and PC Boxes are full. The Egg is still waiting."))
      when :none
        pbMessage(_INTL("There isn't an Egg waiting."))
      end

      sync_menu_label!
      [destination, egg]
    end

    def prompt_for_ready_egg
      choice = pbMessage(
        _INTL("The Day Care has an Egg ready. Deal with it now?"),
        [_INTL("Yes"), _INTL("Later")],
        1
      )
      collect_and_report if choice == 0
      sync_menu_label!
    end

    def open(scene)
      sync_menu_label!

      if egg_waiting?
        collect_and_report
      else
        show_daycare_status
      end

      scene.pbRefresh if scene.respond_to?(:pbRefresh)
    end
  end

  module EggStatePatch
    def daycareEgg=(value)
      old_value = daycareEgg
      result = super(value)
      RemoteDayCare.sync_menu_label!
      RemoteDayCare.egg_ready! if old_value != 1 && value == 1
      result
    end
  end

  module GeneratorPatch
    private

    def pbDayCareGenerateEgg
      return super unless $Trainer.party_full?
      raise _INTL("Can't store the egg.") if pbBoxesFull?

      party = $Trainer.party
      original_party = party.dup
      egg = nil

      begin
        party.pop
        egg = super
        unless egg && party.last.equal?(egg)
          raise "RemoteDayCare: pbDayCareGenerateEgg changed unexpectedly"
        end
      ensure
        party.replace(original_party)
      end

      $PokemonStorage.pbStoreCaught(egg)
      egg
    end
  end
end

PokemonGlobalMetadata.prepend(RemoteDayCare::EggStatePatch)
Object.prepend(RemoteDayCare::GeneratorPatch)

RemoteDayCare.on_egg_ready do
  RemoteDayCare.prompt_for_ready_egg
end

Events.onMapSceneChange += proc { |_sender, _e|
  RemoteDayCare.sync_menu_label!
}

StartMenuExtensions.add(RemoteDayCare::MENU_LABEL) do |scene|
  RemoteDayCare.open(scene)
end
