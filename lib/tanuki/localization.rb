module Tanuki
  class Localization
    @instances = {}

    FALLBACK = {
      :lv => [:en],
      :ru => [:lv, :en],
      :en => [:zz]
    }

    def initialize(language)
      @languages = FALLBACK[language].unshift(language)
    end

    def available(lngs)
      @languages.each do |language|
        return language if lngs.include? language
      end
      nil
    end

    def self.current
      @instances[Thread.current] ||= self.new(:lv)
    end
  end
end