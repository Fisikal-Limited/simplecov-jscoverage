require 'fileutils'
require 'tilt'

module SimplecovJscoverage
  module Assets
    
    #  This class contains the code to instrument files in case they
    #  reside inside in an application folder.
    #
    class Instrumentor < ::Tilt::Template
      
      class CoverageInstrumentError < Exception; end
      
      def prepare
      end

      #  Attempts to instrument the javascript file using an external tool.
      #
      def evaluate(context, locals, &block)
        return data unless SimplecovJscoverage.should_instrument?(@file)
        
        # digest the file path
        digest = Digest::SHA2.hexdigest(@file).to_s

        # ensure the folder exists to store the temporary files under
        FileUtils.mkdir_p(SimplecovJscoverage.config.cache_path)
        
        # combine source and instrumented paths
        source_file_path = File.realdirpath( File.join(SimplecovJscoverage.config.cache_path, digest + ".js") )
        instrumented_file_path = File.realdirpath( File.join(SimplecovJscoverage.config.cache_path, digest + ".instrumented.js") )

        # write out the current buffer
        File.open(source_file_path, "wb") do |f|
          f << data
        end

        # invoke instrumentor command
        cmd = "#{ SimplecovJscoverage.config.jscoverage_command } #{ source_file_path.shellescape } #{ instrumented_file_path.shellescape }"
        `#{cmd}`
        
        # check instrumentor status
        if $?.to_i != 0
          raise CoverageInstrumentError.new 
        end
        
        # if we got here - it seems everything is fine and we can serve an instrumented asset. Let's just memoize the temporary-file-to-real-file mapping
        # so that we can restore it to feed simplecov
        File.open(instrumented_file_path).read + "
          ;
          _$jscoverage['file_paths'] = _$jscoverage['file_paths'] || {};
          _$jscoverage['file_paths'][#{ source_file_path.inspect }] = #{ @file.inspect };
        "
      end
    
    end
    
  end
end