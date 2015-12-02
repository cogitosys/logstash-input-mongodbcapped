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
    @mongo = Mongo::Client.new(@uri)
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
        event = @cursor.next
      rescue StopIteration
        rebuild_connection
      else
        if event
          decorate(event)
          queue << event
        else
          Stud.stoppable_sleep(@interval) { stop? }
        end
      end
    end
  end

  def stop
    @cursor.close
    @mongo.close
  end
end
