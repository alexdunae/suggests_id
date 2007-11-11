require 'active_record'

module Dunae #:nodoc:
  module SuggestsID #:nodoc:
    def self.included(mod)
      super
      mod.extend(ClassMethods)
    end

    module ClassMethods
      # Suggests an identifier/url chunk based on provided fields
      #
      #   class User < ActiveRecord::Base
      #     suggests_id :target => :login_name, :disposable => ['mr', 'mrs', 'ms', 'miss']
      #   end
      #
      #   >> User.suggest_id('John Smith')
      #   => "johnsmith"
      #
      #   >> User.suggest_id(['Mr.', 'John', 'Smith'])
      #   => "johnsmith"
      #
      # Configuration options:
      # * <tt>target</tt> - specifies the column name used to store the identifier (required)
      # * <tt>disposable</tt> - an array of words that can be dropped to make for shorter IDs
      def suggests_id(options = {})
        raise ArgumentError unless options[:target]
        
        configuration = { :target => 'url', :disposable => []}
        configuration.update(options) if options.is_a?(Hash)

        write_inheritable_attribute :target_column, options[:target]
        write_inheritable_attribute :disposable, options[:disposable]
        class_inheritable_reader    :target_column
        class_inheritable_reader    :disposable
      end


      def suggest_id(src)
        src = src.join(' ') if src.is_a?(Array)
        
        raise ArgumentError, 'A string or an array of strings is required' unless src.is_a?(String)

        return '' if src.nil? or src.empty?

        parsed = src.downcase

        # strip punctuation
        parsed = parsed.gsub(/[\'\"\#\$\,\.\!\?\%\@\(\)]+/, "")

        # create an array of potential IDs
        titles = [cleanup_id(parsed)]

        # remove stop words
        titles << cleanup_id(titles.last.gsub(/(\b(at|de|und|the|a|of|un(a|e|o)?|le(s)?|la|in|of)\b)/i, "-"))

        # remove any disposable words, one by one
        disposable.each do |w|
          titles << cleanup_id(titles.last.gsub(Regexp.compile('\b'+w+'\b+'), ''))
        end
        
        # remove numbers
        titles << cleanup_id(titles.last.gsub(/([0-9]+)/i, "-"))

        # remove dashes
        titles << cleanup_id(titles.last.gsub(/([\-\_]+)/i, ""))

        titles = titles.compact.uniq

        # remove empty title if present
        titles.delete("")

        # for debugging only
        titles.each do |t|
          logger.debug " - potential title: #{t}"
        end

        # search for potential IDs and return any matches
        taken = find(:all, :conditions =>"(`#{target_column.to_s}` IN ('#{titles.join('\',\'')}'))", :select => target_column)

        # delete any IDs that are already taken
        taken.each do |t|
          titles.delete(t[target_column].to_s)
        end

        # return the last (and probably shortest) of the potential titles  
        titles.uniq.last
      end

    private
      # Replace non-word chars with dashes and remove 
      # double dashes plus preceding or trailing dashes
      def cleanup_id(url)
        url.gsub(/(\-{2,}|[\W^-_]+)/, '-').gsub(/(\A\-|\-\Z)/, "").strip
      end

    end # /ClassMethods
  end # /SuggestsID
end # /Dunae

