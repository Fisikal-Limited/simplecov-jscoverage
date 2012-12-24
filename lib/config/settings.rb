module SimplecovJscoverage
  module Config
    
    #  This class contains a bunch of settings to be used by the gem.
    #
    class Settings
      
      #  The binary name or a full path to jscoverage file.
      #  Adding custom options is also allowed.
      #
      attr_accessor :jscoverage_command
    
      #  The path to store custom cache files under. This path is to be
      #  inside application's folder as RCov will reject all results otherwise.
      # 
      attr_accessor :cache_path
    
    end
    
  end
end