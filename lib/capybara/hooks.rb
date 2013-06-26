require 'capybara'

module SimplecovJscoverage
  module Capybara
    
    #  This class contains a bunch of settings to be used by the gem.
    #
    class Hooks
      
      #  Initializes the hooks and installs them onto appropriate places.
      #
      def initialize
        install_capybara_hooks
      end
      
      #  Reports the current coverage stats to the reporter.
      #
      def incremental_report!(page = current_page)
        # we iterate over all files
        coverage_report = grab_coverage(page)
        file_map = coverage_report.delete('file_paths')
        
        coverage_report.each do |file, coverage|
          # and report their coverage through current reporter
          SimplecovJscoverage.reporter.flush(file, file_map[file], coverage)
        end
      end
      
    protected
    
      #  Installs hooks to Capybara session class.
      #
      def install_capybara_hooks
        ::Capybara::Session.class_eval do
          
          #  Hooks into resetting the session.
          #
          def reset_with_jscov_hooks!(*args)
            SimplecovJscoverage.hooks.detect { |hook| hook.is_a?(SimplecovJscoverage::Capybara::Hooks) }.try(:incremental_report!, self)
            reset_without_jscov_hooks!(*args)
          end
          
          alias_method_chain :reset!, :jscov_hooks
          
          #  Hooks into switching the page.
          #
          def visit_with_jscov_hooks(*args)
            SimplecovJscoverage.hooks.detect { |hook| hook.is_a?(SimplecovJscoverage::Capybara::Hooks) }.try(:incremental_report!, self)
            visit_without_jscov_hooks(*args)
          end
          
          alias_method_chain :visit, :jscov_hooks
        
        end
      end
    
      #  Attempts to grab the coverage from current browser instance.
      #
      def grab_coverage(page)
        result = page.evaluate_script("window._$jscoverage") rescue nil
        
        if result != nil
          # we have to shift all lines up by 1. Why? because jscoverage messes up with line numbers a bit
          result.inject({}) do |memo, (file, report)|
            file == 'file_paths' ? memo : memo.merge(file => (report || [])[1..-1])
          end
        else
          {}
        end
      end
    
      #  Returns the browser instance to grab data from.
      #
      def current_page
        Capybara.current_session
      end
    
    end
    
  end
end