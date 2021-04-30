# frozen_string_literal: true

# SuperClass for models that are secured by chained footprints.
class Footprintable < ApplicationRecord
  self.abstract_class = true

  def self.columns_out_of_footprint
    []
  end

  def footprint_children
    []
  end

  def sort_on_field
    'id'
  end

  def check_footprint
    footprint_children.map(&:check_footprint).all? && footprint == compute_footprint
  end

  def chain_record
    self.footprint = compute_footprint
    save!
    FootprintDebug.create!(
      footprint: footprint,
      data: FootprintService.footprint_data(self.class, self),
      klass: self.class.name
    )
  end

  def debug_footprint
    FootprintService.debug_footprint(self.class, self)
  end

  protected

  def compute_footprint
    FootprintService.compute_footprint(self.class, self)
  end
end
