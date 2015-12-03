# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"

# Read messages from a mongodb capped collection using a tailable cursor
class LogStash::Inputs::MongoDBCapped < LogStash::Inputs::Base
  config_name "mongodbcapped"

  # If undefined, Logstash will complain, even if codec is unused.
  default :codec, "plain"

  # The mongo server to connect to (as a mongodb connection string)
  config :server, validate: :string, required: false

  # The collections to tail
  #
  # To specify collections in different databases, write them in the form "database/collection"
  config :collections, validate: :array, required: true

  # How long to sleep if the cursor gives us no results, to reduce server load
  config :interval, validate: :number, default: 0.5

  # Whether or not to consider a missing collection a fatal error
  config :raise_on_missing, validate: :boolean, default: true

  def register
    require "json"
    require "uri"
    require "mongo"
    require "mongo/tailable_cursor"

    # I'd hook it up to Cabin, but Cabin doesn't support the proper api (block-style)
    mongo_logger = Logger.new($stdout)
    mongo_logger.level = Logger::WARN
    @mongo = Mongo::Client.new(@server, logger: mongo_logger)

    # bootstrap connections to all the collections
    @collections.map! do |collection_string|
      collection, database = collection_string.split("/",2).reverse
      database ||= @mongo.database.name
      [database, collection]
    end

    raise LogStash::ConfigurationError, "must have at least one collection" if @collections.empty?
  end

  def run(queue)
    @collections.map do |database, collection|
      Thread.new(queue, database, collection) do |queue, database, collection|
        @logger.info("MongoDB tailable thread starting", database: database, collection: collection)
        subscribe(queue, database, collection)
      end
    end.each do |thread|
      thread.join
    end
  end

  def rebuild_connection(database, collection)
    coll = @mongo.use(database)[collection]
    raise "Collection must be capped to connect to it" unless coll.capped?
    view = coll.find({}, sort: [["$natural", 1]], cursor_type: :tailable)
    return Mongo::TailableCursor.new(view)
  rescue Mongo::Error::OperationFailure => e
    return nil unless @raise_on_missing
    raise e
  end

  def subscribe(queue, database, collection)
    cursor = rebuild_connection(database, collection)
    return unless cursor
    cursor.start

    # we can abort the loop if stop? becomes true
    while !stop?
      begin
        message = cursor.next
      rescue Mongo::Error::OperationFailure => e
        # this can happen if a query wasn't successful
        retry
      rescue StopIteration
        @logger.info("MongoDB tailable cursor broken", uri: @server, database: database, collection: collection)
        cursor = rebuild_connection(database, collection)
        return unless cursor
        cursor.start
      else
        if message
          message = convert_bson_hash_to_raw(message)
          event = LogStash::Event.new("message" => message, "database" => database, "collection" => collection)
          decorate(event)
          queue << event
        else
          Stud.stoppable_sleep(@interval) { stop? }
        end
      end
    end
  end

  def convert_bson_hash_to_raw(hash)
    result = {}
    hash.each do |key, value|
      case value
      when BSON::Binary, BSON::Code, BSON::CodeWithScope, BSON::MaxKey, BSON::MinKey, BSON::ObjectId, BSON::Timestamp, Regexp
        result[key] = value.as_json
      when Hash
        result[key] = convert_bson_hash_to_raw(value)
      else
        result[key] = value.to_s
      end
    end
    return result
  end
end
