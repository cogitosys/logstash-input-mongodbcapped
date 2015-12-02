# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"

# Read messages from a mongodb capped collection using a tailable cursor
class LogStash::Inputs::MongoDBCapped < LogStash::Inputs::Base
  config_name "mongodbcapped"

  # If undefined, Logstash will complain, even if codec is unused.
  default :codec, "plain"

  # The mongo server and database to connect to
  config :uri, validate: :string, required: true

  # The collection to tail
  config :collection, validate: :string, required: true

  # how long to sleep if the cursor gives us no results, to reduce server load
  config :interval, validate: :number, default: 0.5

  # filter to apply to the cursor
  config :filter, validate: :string, required: false, default: ""

  public
  def register
    require "json"
    require "uri"
    require "mongo"
    require "mongo/tailable_cursor"

    @parsed_filter = begin
      JSON.parse(@filter)
    rescue
      {}
    end
    last_value = nil
    rebuild_connection
  end

  def rebuild_connection
    # I'd hook it up to Cabin, but Cabin doesn't support the proper api (block-style)
    mongo_logger = Logger.new($stdout)
    mongo_logger.level = Logger::WARN
    @mongo = Mongo::Client.new(@uri, logger: mongo_logger)
    @coll = @mongo[@collection]
    raise "Collection must be capped to connect to it" unless @coll.capped?

    @view = @coll.find(@parsed_filter, sort: [["$natural", 1]], cursor_type: :tailable)
    @cursor = Mongo::TailableCursor.new(@view)
  end

  def run(queue)
    @cursor.start

    # we can abort the loop if stop? becomes true
    while !stop?
      begin
        message = @cursor.next
      rescue StopIteration
        @logger.info("MongoDB tailable cursor broken", uri: @uri, collection: @collection)
        rebuild_connection
      else
        if message
          message = convert_bson_hash_to_raw(message)
          event = LogStash::Event.new("message" => message, database: @mongo.database.name, collection: @collection)
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
        result[key] = value
      end
    end
    return result
  end

  def stop
    @cursor.close
    @mongo.close
  end
end
