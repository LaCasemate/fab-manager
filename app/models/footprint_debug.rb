# frozen_string_literal: true

# When a footprint is generated, the associated data is kept to allow further verifications
class FootprintDebug < ApplicationRecord
  # We try to rebuild the data, column by column, from the db object
  # If any datum oes not match, we print it as ERROR
  def format_data(item_id)
    item = klass.constantize.find(item_id)
    columns = FootprintService.footprint_columns(klass.constantize)

    result = []
    index = 0
    columns.each do |column|
      col_data = item[column]
      end_idx = index + col_data.to_s.length - 1

      if data[index..end_idx] == col_data.to_s
        # if the item data for the current column matches, save it into the results and move forward teh cursor
        result.push(col_data.to_s)
        index = end_idx + 1
      else
        # if the item data for the current column does not matches, mark it as an error, display the next chars, but do not move the cursor
        datum = data[index..end_idx]
        datum = data[index..index + 5] if datum&.empty?
        result.push "ERROR (#{datum}...)"
      end
    end
    # the remaining data is the previous record checksum
    result.push(data[index..-1])

    result
  end
end
