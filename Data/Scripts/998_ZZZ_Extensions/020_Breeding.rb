def pbDayCareCompatibleGender(pkmn1, pkmn2)
  return true if pkmn1.female? && pkmn2.male?
  return true if pkmn1.male? && pkmn2.female?
  ditto1 = pbIsDitto?(pkmn1)
  ditto2 = pbIsDitto?(pkmn2)

  # # Original: no ditto x ditto
  # return true if ditto1 && !ditto2
  # return true if ditto2 && !ditto1

  # Patch: yes ditto x ditto
  return ditto1 || ditto2
  return false
end

module BreedableFusions
  def initialize(id)
    super
    @egg_groups = calculate_egg_groups if @body_pokemon && @head_pokemon
  end

  def calculate_egg_groups
    body = @body_pokemon.egg_groups.reject { |g| g == :Undiscovered }
    head = @head_pokemon.egg_groups.reject { |g| g == :Undiscovered }

    groups = combine_arrays(body, head)

    return [:Undiscovered] if groups.empty?
    return groups
  end
end

GameData::FusedSpecies.prepend(BreedableFusions)