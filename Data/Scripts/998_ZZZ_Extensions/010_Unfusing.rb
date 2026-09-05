alias zzz_original_pbUnfuse pbUnfuse

def pbUnfuse(pokemon, scene, supersplicers, pcPosition = nil)
  singleton = class << pokemon; self; end

  had_own_foreign = singleton.instance_methods(false).include?(:foreign?)
  old_foreign = pokemon.method(:foreign?) if had_own_foreign

  singleton.send(:define_method, :foreign?) do |trainer|
    false
  end

  begin
    zzz_original_pbUnfuse(pokemon, scene, supersplicers, pcPosition)
  ensure
    if had_own_foreign
      singleton.send(:define_method, :foreign?, old_foreign)
    else
      singleton.send(:remove_method, :foreign?)
    end
  end
end