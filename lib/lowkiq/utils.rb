module Lowkiq
  module Utils
    class Array
      def initialize(array)
        @array = array.to_a
      end

      def in_transposed_groups(number)
        result = number.times.map { [] }

        @array.each_with_index do |item, index|
          group = index % number
          result[group] << item
        end

        result
      end
    end

    class Redis
      def initialize(redis)
        @redis = redis
      end

      def zresetscores(key)
        @redis.zunionstore key, [key], weights: [0.0]
      end
    end

    module Timestamp
      def self.now
        Time.now.to_i
      end
    end
  end
end
