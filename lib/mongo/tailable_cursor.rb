module Mongo
  # Mongo's Ruby driver has broken support for tailable cursors
  #
  # so we built our own that doesn't pull their shit
  class TailableCursor < Cursor
    def initialize(view)
      @view = view
      @view.read_with_retry do
        @server = @view.read.select_server(@view.cluster)
      end
      @current_document_batch = []
    end

    def start
      initial_results = @view.send(:send_initial_query, @server)
      @current_document_batch = self.send(:process, initial_results)
    end

    # Strongly recommended not to use the blocking version
    def each
      self.start
      while true
        doc = self.next
        next unless doc
        yield doc
      end
    end

    def next
      if @current_document_batch.empty?
        fetch_more
      end
      return @current_document_batch.shift
    end

    def close
      self.send(:kill_cursors)
    end

    protected
    def fetch_more
      if self.send(:more?)
        @current_document_batch = self.send(:get_more)
      else
        raise StopIteration
      end
    end
  end
end
