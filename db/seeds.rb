# frozen_string_literal: true

Stock::COMMODITIES.each do |attrs|
  Stock.find_or_create_by!(symbol: attrs[:symbol]) do |stock|
    stock.name = attrs[:name]
    stock.color = attrs[:color]
  end
end

puts "Seeded #{Stock.count} stocks: #{Stock.pluck(:symbol).join(', ')}"
