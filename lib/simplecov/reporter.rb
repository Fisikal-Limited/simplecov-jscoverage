module SimplecovJscoverage
  module Simplecov

    #  This monkey patch exposes file name to ourside world.
    #
    ::SimpleCov::SourceFile.class_eval do
      attr_accessor :filename
    end
    
    #  This monkey patch allows us to re-map file names according to their application-side values.
    #
    class SimpleCovResult < SimpleCov::Result
      
      #  Replaces filenames with ones from path_map.
      #
      def update_filenames!(path_map)
        @files.each do |file|
          file.filename = path_map[file.filename] || file.filename
        end
        
        @original_result = @original_result.inject({}) do |memo, (path, coverage)|
          memo.merge(path => coverage, path_map[path] => coverage)
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
        @result ||= SimpleCovResult.new(Coverage.result.merge_resultset(merged_side_results)) if running
        @result.update_filenames!(@path_map || {})
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