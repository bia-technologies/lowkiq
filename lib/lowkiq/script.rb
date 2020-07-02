module Lowkiq
  module Script
    module_function

    ALL = {
      hmove: <<-LUA,
        local source = KEYS[1]
        local destination = KEYS[2]
        local key = ARGV[1]
        local value = redis.call('hget', source, key)
        if value then
          redis.call('hdel', source, key)
          redis.call('hset', destination, key, value)
        end
      LUA
      zremhset: <<-LUA
        local source = KEYS[1]
        local destination = KEYS[2]
        local member = ARGV[1]
        local score = redis.call('zscore', source, member)
        if score then
          redis.call('zrem', source, member)
          redis.call('hset', destination, member, score)
        end
      LUA
    }.transform_values { |v| { sha: Digest::SHA1.hexdigest(v), source: v } }.freeze

    def load!(redis)
      ALL.each do |_, item|
        redis.script(:load, item[:source])
      end
    end

    def hmove(redis, source, destination, key)
      redis.evalsha ALL[:hmove][:sha], keys: [source, destination], argv: [key]
    end

    def zremhset(redis, source, destination, member)
      redis.evalsha ALL[:zremhset][:sha], keys: [source, destination], argv: [member]
    end
  end
end
