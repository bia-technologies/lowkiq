module Lowkiq
  module ExtendTracker
    def extended(mod)
      @extended_modules ||= []
      @extended_modules << mod
      @extended_modules.sort_by! &:name
    end

    def extended_modules
      @extended_modules
    end
  end
end
