module SimplecovJscoverage
  module Simplecov

    #  This monkey patch exposes file name to ourside world.
    #
    ::SimpleCov::SourceFile.class_eval do
      attr_accessor :filename
    end
    
    #  This monkey patch allows us to re-map file names according to their application-side values.
    #
    ::SimpleCov::Result.class_eval do
      
      attr_reader :path_map

      # Initialize a new SimpleCov::Result from given Coverage.result (a Hash of filenames each containing an array of
      # coverage data)
      def initialize(original_result, path_map = {})
        @original_result = original_result.freeze
        @path_map = path_map

        # as we store a map of real file => virtual file, to perform real file lookup we have to invert the hash
        inverted_path_map = path_map.invert
        
        @files = SimpleCov::FileList.new(original_result.map do |filename, coverage|
          real_filename = inverted_path_map[filename] || filename
          SimpleCov::SourceFile.new(real_filename, coverage).tap do |source_file|
            source_file.filename = filename
          end
        end.compact.sort_by(&:filename))

        filter!
      end

      #  Replaces filenames with ones from path_map.
      #
      def update_filenames!(path_map)
        @path_map = path_map

        @files.each do |file|
          file.filename = path_map[file.filename] || file.filename
        end
        
        @original_result = @original_result.inject({}) do |memo, (path, coverage)|
          memo.merge(path => coverage, path_map[path] => coverage)
        end
      end

      # Returns a hash representation of this Result that can be used for marshalling it into YAML
      def to_hash
        {command_name => {"path_map" => self.path_map, 
                          "coverage" => original_result.reject {|filename, result| !filenames.include?(filename) }, 
                          "timestamp" => created_at.to_i}}
      end

      # Loads a SimpleCov::Result#to_hash dump
      def self.from_hash(hash)
        command_name, data = hash.first
        result = SimpleCov::Result.new(data["coverage"], data["path_map"])
        result.command_name = command_name
        result.created_at = Time.at(data["timestamp"])
        result
      end
      
    end

    ::SimpleCov::ResultMerger.module_eval do
      class << self

        # Gets the resultset hash and re-creates all included instances
        # of SimpleCov::Result from that.
        # All results that are above the SimpleCov.merge_timeout will be
        # dropped. Returns an array of SimpleCov::Result items.
        def results
          resultset.map do |command_name, data|
            SimpleCov::Result.from_hash(command_name => data)
          end
        end

        #
        # Gets all SimpleCov::Results from cache, merges them and produces a new
        # SimpleCov::Result with merged coverage data and the command_name
        # for the result consisting of a join on all source result's names
        #
        def merged_result
          #  Collect coverage
          coverage = results.inject({}) do |memo, result|
            result.original_result.merge_resultset(memo)
          end

          #  Collect path map
          path_map = results.inject({}) do |memo, result|
            memo.merge(result.path_map)
          end

          #  Initialize with coverage data
          result = SimpleCov::Result.new(coverage, path_map)
          #  Apply path map
          result.update_filenames!(path_map)
          #  Compute command name
          result.command_name = results.map(&:command_name).sort.join(", ")

          result
        end

      end
    end
    
    class << ::SimpleCov
    
      #  Stores all side results as an array of hashes.
      attr_accessor :side_results
      
      #  Stores the path map of real FS path (where the cached file and its source resides) to meta paths (the path from app perspective).
      attr_accessor :path_map
    
      #  Merges the side result result in (here sideresult means the one obtained from a 3rd party source)
      #
      def append_side_result(side_result, path_map)
        @side_results ||= []
        @side_results << side_result
        
        @path_map ||= {}
        @path_map.merge!(path_map)
      end
      
      #  We rewrite the result method to merge side and actual results.
      #
      def result
        @result ||= ::SimpleCov::Result.new(Coverage.result.merge_resultset(merged_side_results)) if running
        @result.update_filenames!(@path_map || {})

        if use_merging
          ::SimpleCov::ResultMerger.store_result(@result)
          return ::SimpleCov::ResultMerger.merged_result
        end

        @result
      ensure
        self.running = false
      end
      
      #  Returns merged side results.
      #
      def merged_side_results
        (@side_results || []).inject({}) do |resultset, result|
          resultset.merge_resultset(result)
        end
      end
    
    end
    
    #  This class contains a bunch of settings to be used by the gem.
    #
    class Reporter
    
      #  Configures reporter instance.
      #
      def initialize
      end
      
      #  Flushes the coverage hash to Simplecov.
      #
      def flush(file_path, meta_path, coverage)
        SimpleCov::append_side_result({file_path => coverage}, {file_path => meta_path})
      end
    
    end
    
  end
end