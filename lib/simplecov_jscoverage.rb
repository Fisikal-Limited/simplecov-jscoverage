module SimplecovJscoverage
  
  module Assets
    autoload :Instrumentor, 'assets/instrumentor'
  end
  
  module Capybara
    autoload :Hooks, 'capybara/hooks'
  end
  
  module Config
    autoload :Settings, 'config/settings'
  end
  
  module Simplecov
    autoload :Reporter, 'simplecov/reporter'
  end
  
  class << self
    
    #  Configuration instance
    attr_accessor :config
  
    #  Reporter instance
    attr_accessor :reporter
    
    #  Contains an array of hooks to automagically report to Simplecov upon certain actions
    attr_accessor :hooks
    
    #  Contains an array of procs which should check the path from instrumentability.
    #  The path will be instrumented only when all procs return true for it.
    attr_accessor :instrumentable_filters
    
    #  Starts the instrumentation and reporter.
    #
    def start(&block)
      self.instrumentable_filters = []
      self.config = SimplecovJscoverage::Config::Settings.new
      
      # preset default options
      self.config.jscoverage_command = "jscoverage --single-compact"
      self.config.cache_path = File.expand_path(File.join(Rails.application.root, "tmp", "cache", "simplecov"))
      
      self.reporter = SimplecovJscoverage::Simplecov::Reporter.new
      
      self.hooks = [ SimplecovJscoverage::Capybara::Hooks.new ]
      
      instance_eval(&block) if block_given?
    end
    
    #  Returns true if the file should be instrumented.
    #
    def should_instrument?(path)
      self.instrumentable_filters.all? { |filter| filter[path] }
    end
    
    #  Adds the filter which is a block returning false to skip a file.
    #
    def add_filter(&block)
      self.instrumentable_filters << block
    end
    
    #  Injects instruments to postprocess JS files.
    #
    def inject_instruments!
      Rails.application.assets.register_postprocessor 'application/javascript', SimplecovJscoverage::Assets::Instrumentor
    end
    
  end
  
end