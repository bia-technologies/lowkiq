module Lowkiq
  module Queue
    module Marshal
      class << self
        def dump_data(data)
          ::Marshal.dump data
        end

        def load_data(str)
          ::Marshal.load str
        end
      end
    end
  end
end
