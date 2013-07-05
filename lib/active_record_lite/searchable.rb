require_relative './db_connection'

module Searchable
  def where(params)
    params.keys.map do |key|
      "#{key} = (?)"
    end
  end
end