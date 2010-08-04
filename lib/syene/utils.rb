module Syene
  module Utils
    def symbolize_keys(h)
      return h unless h.is_a?(Hash)
      h.keys.inject({}) do |acc, k|
        acc[k.to_sym] = symbolize_keys(h[k])
        acc
      end
    end
  end
end