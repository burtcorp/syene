require 'immutable_struct'


module Syene
  class Airport < ImmutableStruct.new(
    :_id,
    :name,
    :ascii_name,
    :location,
    :size,
    :airport_code
  )
  end
end