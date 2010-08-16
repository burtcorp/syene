require 'immutable_struct'


module Syene
  class City < ImmutableStruct.new(
    :_id,
    :name,
    :ascii_name,
    :location,
    :population,
    :country_code,
    :country_name,
    :region
  )
  end
end