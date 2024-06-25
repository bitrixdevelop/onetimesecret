# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `uri-redis` gem.
# Please instead update this file by running `bin/tapioca gem uri-redis`.


# Adds a URI method to Redis
#
# source://uri-redis//lib/uri/redis.rb#111
class Redis
  include ::Redis::Commands::Bitmaps
  include ::Redis::Commands::Cluster
  include ::Redis::Commands::Connection
  include ::Redis::Commands::Geo
  include ::Redis::Commands::Hashes
  include ::Redis::Commands::HyperLogLog
  include ::Redis::Commands::Keys
  include ::Redis::Commands::Lists
  include ::Redis::Commands::Pubsub
  include ::Redis::Commands::Scripting
  include ::Redis::Commands::Server
  include ::Redis::Commands::Sets
  include ::Redis::Commands::SortedSets
  include ::Redis::Commands::Streams
  include ::Redis::Commands::Strings
  include ::Redis::Commands::Transactions

  # source://redis/4.8.1/lib/redis.rb#83
  def initialize(options = T.unsafe(nil)); end

  # source://redis/4.8.1/lib/redis.rb#160
  def _client; end

  # source://redis/4.8.1/lib/redis.rb#110
  def close; end

  # source://redis/4.8.1/lib/redis.rb#140
  def commit; end

  # source://redis/4.8.1/lib/redis.rb#105
  def connected?; end

  # source://redis/4.8.1/lib/redis.rb#250
  def connection; end

  # source://redis/4.8.1/lib/redis.rb#110
  def disconnect!; end

  # source://redis/4.8.1/lib/redis.rb#246
  def dup; end

  # source://redis/4.8.1/lib/redis.rb#238
  def id; end

  # source://redis/4.8.1/lib/redis.rb#242
  def inspect; end

  # source://redis/4.8.1/lib/redis.rb#214
  def multi(&block); end

  # source://redis/4.8.1/lib/redis.rb#164
  def pipelined(&block); end

  # source://redis/4.8.1/lib/redis.rb#125
  def queue(*command); end

  # source://uri-redis//lib/uri/redis.rb#116
  def uri; end

  # source://redis/4.8.1/lib/redis.rb#115
  def with; end

  # source://redis/4.8.1/lib/redis.rb#93
  def with_reconnect(val = T.unsafe(nil), &blk); end

  # source://redis/4.8.1/lib/redis.rb#100
  def without_reconnect(&blk); end

  private

  # source://redis/4.8.1/lib/redis.rb#280
  def _subscription(method, timeout, channels, block); end

  # source://redis/4.8.1/lib/redis.rb#274
  def send_blocking_command(command, timeout, &block); end

  # source://redis/4.8.1/lib/redis.rb#268
  def send_command(command, &block); end

  # source://redis/4.8.1/lib/redis.rb#264
  def synchronize; end

  class << self
    # source://redis/4.8.1/lib/redis.rb#40
    def current; end

    # source://redis/4.8.1/lib/redis.rb#45
    def current=(redis); end

    # source://redis/4.8.1/lib/redis.rb#30
    def deprecate!(message); end

    # source://redis/4.8.1/lib/redis.rb#15
    def exists_returns_integer; end

    # source://redis/4.8.1/lib/redis.rb#18
    def exists_returns_integer=(value); end

    # source://redis/4.8.1/lib/redis.rb#16
    def raise_deprecations; end

    # source://redis/4.8.1/lib/redis.rb#16
    def raise_deprecations=(_arg0); end

    # source://redis/4.8.1/lib/redis.rb#16
    def sadd_returns_boolean; end

    # source://redis/4.8.1/lib/redis.rb#16
    def sadd_returns_boolean=(_arg0); end

    # source://redis/4.8.1/lib/redis.rb#16
    def silence_deprecations; end

    # source://redis/4.8.1/lib/redis.rb#16
    def silence_deprecations=(_arg0); end

    # source://uri-redis//lib/uri/redis.rb#112
    def uri(conf = T.unsafe(nil)); end
  end
end

# Redis URI
#
# This is a subclass of URI::Generic and supports the following URI formats:
#
#   redis://host:port/dbindex
#
# @example
#   uri = URI::Redis.build(host: "localhost", port: 6379, db: 2, key: "v1:arbitrary:key")
#   uri.to_s #=> "redis://localhost:6379/2/v1:arbitrary:key"
#
#   uri = URI::Redis.build(host: "localhost", port: 6379, db: 2)
#   uri.to_s #=> "redis://localhost:6379/2"
#
# source://uri-redis//lib/uri/redis.rb#19
class URI::Redis < ::URI::Generic
  # Returns a hash suitable for sending to Redis.new.
  # The hash is generated from the host, port, db and
  # password from the URI as well as any query vars.
  #
  # e.g.
  #
  #      uri = URI.parse "redis://127.0.0.1/6/?timeout=5"
  #      uri.conf
  #        # => {:db=>6, :timeout=>"5", :host=>"127.0.0.1", :port=>6379}
  #
  # source://uri-redis//lib/uri/redis.rb#65
  def conf; end

  # source://uri-redis//lib/uri/redis.rb#43
  def db; end

  # source://uri-redis//lib/uri/redis.rb#48
  def db=(val); end

  # source://uri-redis//lib/uri/redis.rb#32
  def key; end

  # source://uri-redis//lib/uri/redis.rb#39
  def key=(val); end

  # source://uri-redis//lib/uri/redis.rb#28
  def request_uri; end

  # source://uri-redis//lib/uri/redis.rb#75
  def serverid; end

  private

  # Based on: https://github.com/chneukirchen/rack/blob/master/lib/rack/utils.rb
  # which was originally based on Mongrel
  #
  # source://uri-redis//lib/uri/redis.rb#83
  def parse_query(query, delim = T.unsafe(nil)); end

  class << self
    # source://uri-redis//lib/uri/redis.rb#23
    def build(args); end
  end
end

# source://uri-redis//lib/uri/redis.rb#21
URI::Redis::DEFAULT_DB = T.let(T.unsafe(nil), Integer)

# source://uri-redis//lib/uri/redis.rb#20
URI::Redis::DEFAULT_PORT = T.let(T.unsafe(nil), Integer)