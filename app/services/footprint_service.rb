# frozen_string_literal: true

require 'integrity/checksum'

# Provides helper methods to compute footprints
class FootprintService
  class << self
    # Compute the footprint
    # @param klass {Class} a class inheriting from Footprintable
    # @param item {Footprintable} an instance of the provided class
    def compute_footprint(klass, item)
      Integrity::Checksum.text(FootprintService.footprint_data(klass, item))
    end

    # Return the original data string used to compute the footprint
    # @param klass {Class} a class inheriting from Footprintable
    # @param item {Footprintable} an instance of the provided class
    # @param array {Boolean} if true, the result is return on the form of an array, otherwise a concatenated string is returned
    def footprint_data(klass, item, array: false)
      raise TypeError unless item.is_a? klass

      sort_on = item.sort_on_field
      previous = klass.where("#{sort_on} < ?", item[sort_on])
                   .order("#{sort_on} DESC")
                   .limit(1)

      columns  = FootprintService.footprint_columns(klass)
      columns = columns.map do |c|
        comparable(item[c])
      rescue ActiveModel::MissingAttributeError
        nil
      end

      res = columns.push(previous.first ? previous.first.footprint : '')
      array ? res.map(&:to_s) : res.join.to_s
    end

    # Return an ordered array of the columns used in the footprint computation
    # @param klass {Class} a class inheriting from Footprintable
    def footprint_columns(klass)
      klass.columns.map(&:name).delete_if { |c| %w[footprint updated_at].concat(klass.columns_out_of_footprint).include? c }
    end

    # Logs a debugging message to help finding why a footprint is invalid
    # @param klass {Class} a class inheriting from Footprintable
    # @param item {Footprintable} an instance of the provided class
    def debug_footprint(klass, item)
      columns = FootprintService.footprint_columns(klass)
      current = FootprintService.footprint_data(klass, item, array: true)
      saved = FootprintDebug.find_by(footprint: item.footprint, klass: klass.name)
      if saved.nil?
        puts "Debug data not found for #{klass} [ id: #{item.id} ]"
      else
        others = FootprintDebug.where('klass = ? AND data LIKE ? AND id != ?', klass, "#{item.id}%", saved.id)
        puts "Debug footprint for #{klass} [ id: #{item.id} ]"
        puts '-----------------------------------------'
        puts "columns: [ #{columns.join(', ')} ]"
        puts "current: #{current}"
        puts "  saved: #{saved.format_data(item.id)}"
        puts '-----------------------------------------'
        puts "other possible matches IDs: #{others.map(&:id)}"
        puts '-----------------------------------------'
        item.footprint_children.map(&:debug_footprint)
      end
    end

    private

    # Return a comparable value for jsonb fields (with keys ordered alphabetically)
    def comparable(value)
      return value unless value.is_a? Hash

      value.sort.to_h
    end
  end
end
