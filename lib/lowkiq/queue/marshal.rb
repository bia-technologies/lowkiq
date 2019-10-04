module Lowkiq
  module Queue
    module Marshal
      class << self
        def dump_payload(data)
          ::Marshal.dump data
        end

        def load_payload(str)
          ::Marshal.load str
        end

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
