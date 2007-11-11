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
      #     suggests_id :target => :login_name, :disposable => ['mr', 'mrs', 'ms', 'miss'],
      #                 :suffix => '-0000',
      #                 :suffix_iterations => 20
      #   end
      #
      #   >> User.suggest_id('John Smith')
      #   => "johnsmith"
      #
      #   >> User.suggest_id(['Mr.', 'John', 'Smith'])
      #   => "johnsmith"
      #
      # Make sure you have an index set on the ID column of your table or else speed will suffer.
      #
      # Configuration options:
      # * <tt>target</tt> - specifies the column name used to store the identifier (required)
      # * <tt>disposable</tt> - an array of words that can be dropped to make for shorter IDs (optional)
      # * <tt>suffix</tt> - a suffix to add if no IDs are available (optional)
      # * <tt>suffix_iterations</tt> - number of times to increment the ID (optional, default is 10)
      #
      # ==== About suffixes
      # When a +suffix+ is provided, the plugin will only add it if no other matches can be made.
      #
      # The suffix is incremented as many times as you specify in +suffix_iterations+ using the 
      # String#succ! method.
      def suggests_id(options = {})
        raise ArgumentError unless options[:target]
        
        configuration = { :target => 'url', :disposable => [], :suffix => nil, :suffix_iterations => 10}
        configuration.update(options) if options.is_a?(Hash)

        write_inheritable_attribute :target_column, options[:target]
        write_inheritable_attribute :disposable, options[:disposable]
        write_inheritable_attribute :suffix, options[:suffix]
        write_inheritable_attribute :suffix_iterations, options[:suffix_iterations]
        class_inheritable_reader    :target_column
        class_inheritable_reader    :disposable
        class_inheritable_reader    :suffix
        class_inheritable_reader    :suffix_iterations
      end

      def suggest_id(src) # :nodoc:
        src = src.join(' ') if src.is_a?(Array)
        
        raise ArgumentError, 'A string or an array of strings is required' unless src.is_a?(String)

        return '' if src.nil? or src.empty?

        parsed = src.downcase

        # strip punctuation
        parsed = parsed.gsub(/[\'\"\#\$\,\.\!\?\%\@\(\)]+/, "")

        # create an array of potential IDs
        ids = [cleanup_id(parsed)]

        # remove stop words
        ids << cleanup_id(ids.last.gsub(/(\b(at|de|und|the|a|of|un(a|e|o)?|le(s)?|la|in|of)\b)/i, "-"))

        # remove any disposable words, one by one
        if disposable
          disposable.each do |w|
            ids << cleanup_id(ids.last.gsub(Regexp.compile('\b'+w+'\b+'), ''))
          end
        end
        
        # remove numbers
        ids << cleanup_id(ids.last.gsub(/([0-9]+)/i, "-"))

        # remove dashes
        ids << cleanup_id(ids.last.gsub(/([\-\_]+)/i, ""))

        ids = ids.compact.uniq

        # remove empty IDs
        ids.delete('')

        available_ids = find_available_ids(ids.clone, target_column)

        return available_ids.last unless available_ids.nil?
        
        # Try adding a suffix
        if suffix
          ids_with_suffixes = add_suffixes(ids.last, suffix.clone, suffix_iterations)
          available_ids = find_available_ids(ids_with_suffixes, target_column)

          return available_ids.first unless available_ids.nil? 
        end
                
        suggested_id 
      end

    private
      def find_available_ids(ids, target_column) # :nodoc:
        # search for potential IDs and return any matches
        taken = find(:all, :conditions =>"(`#{target_column.to_s}` IN ('#{ids.join('\',\'')}'))", :select => target_column)

        # delete any IDs that are already taken
        taken.each do |t|
          ids.delete(t[target_column].to_s)
        end
        
        return nil if ids.empty?
        
        ids
      end

      # Add suffixes to an ID
      def add_suffixes(possible_id, suffix, iterations) # :nodoc:
        ids_with_suffixes = []
        iterations.to_i.times do
          ids_with_suffixes << possible_id + suffix.to_s
          suffix.succ!
        end

        ids_with_suffixes
      end


      # Replace non-word chars with dashes and remove 
      # double dashes plus preceding or trailing dashes
      def cleanup_id(url) # :nodoc:
        url.gsub(/(\-{2,}|[\W^-_]+)/, '-').gsub(/(\A\-|\-\Z)/, "").strip
      end

    end # /ClassMethods
  end # /SuggestsID
end # /Dunae

