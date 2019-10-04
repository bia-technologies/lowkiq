module Lowkiq
  module OptionParser
    module_function

    def call(args)
      options = {
      }
      ::OptionParser.new do |parser|
        parser.on("-r", "--require PATH") do |path|
          options[:require] = path
        end

        parser.on("-h", "--help", "Prints this help") do
          puts parser
          exit
        end
      end.parse!(args)

      fail "--require is required option" if options[:require].nil? || options[:require].empty?

      options
    end
  end
end
