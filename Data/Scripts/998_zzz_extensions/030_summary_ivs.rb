# Intercept this scene's text commands while the original stats page renders.
module SummaryIVDisplay
  # [stat ID, original value X, row Y] in the 6.7.2 summary layout.
  STAT_ROWS = [
    [:HP,              462,  70],
    [:ATTACK,          456, 114],
    [:DEFENSE,         456, 146],
    [:SPECIAL_ATTACK,  456, 178],
    [:SPECIAL_DEFENSE, 456, 210],
    [:SPEED,           456, 242]
  ].freeze

  def drawPageThree
    previous = @pg_drawing_summary_ivs
    @pg_drawing_summary_ivs = true
    super
  ensure
    @pg_drawing_summary_ivs = previous
  end

  private

  # The global drawing helper is an inherited private method. Overriding it
  # here intercepts calls from this scene without changing other screens.
  def pbDrawTextPositions(bitmap, textpos)
    return super unless @pg_drawing_summary_ivs
    return super unless bitmap.equal?(@sprites["overlay"].bitmap)

    value_indices = STAT_ROWS.map do |_stat, x, y|
      textpos.index { |text| text[1] == x && text[2] == y && text[3] == 1 }
    end
    # Only decorate the complete stats table, not another batch of text.
    return super if value_indices.any?(&:nil?)

    textpos = textpos.map(&:dup)
    value_indices.each { |index| textpos[index][1] = 430 }
    textpos << [_INTL("IV"), 480, 47, 1,
                Color.new(248, 248, 248), Color.new(104, 104, 104)]
    STAT_ROWS.each do |stat, _x, y|
      iv = @pokemon.iv[stat]
      colors = case iv
               when 31
                 [Color.new(40, 160, 40), Color.new(120, 240, 120)]
               when 25..30
                 [Color.new(180, 140, 20), Color.new(248, 220, 100)]
               else
                 [Color.new(84, 64, 44), Color.new(176, 176, 176)]
               end
      textpos << [sprintf("%d", iv), 480, y, 1, *colors]
    end
    super(bitmap, textpos)
  end
end

PokemonSummary_Scene.prepend(SummaryIVDisplay)
