class String

  # Convert English world from singular to plural form.
  def pluralize
    # TODO Improve, steal something from Rails
    @_pluralization_rules ||= {
      /(.*)f[ef]$/ => 'ves',
      /(.*[alor])f$/ => 'ves',
      /(.*)[ei]x$/ => 'ices',
      /(.*)um$/ => 'a',
      /(.*th)$/ => 's',
      /(.*(?:us|[fhos]))$/ => 'es',
      /([^aeiou]*)y$/ => 'ies',
      /(.*)/ => 's'
    }
    @_pluralization_rules.each_pair do |k, v|
      return "#{$1}#{v}" if self =~ k
    end
  end

end # end String