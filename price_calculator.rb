require 'json'

class PriceCalculator
  def initialize
    file_content = File.read('./commodity_master.json')
    @commodity_master = JSON.parse(file_content)        
    @item_count = {}
    @bill = Hash.new {|attribute,value| attribute[value] = Hash.new(0)}
    @bill_total = 0.00
    @bill_total_without_offer = 0.00
  end

  def generate_bill
    get_user_input
    fetch_items
    count_items
    calculate_total
    print_bill
  end

  private

  def get_user_input
    puts 'Please enter all the items purchased separated by a comma'
    @input_string = gets    
  end
  
  def fetch_items  
    @purchased_items = @input_string.split(",").map(&:strip)    
  end

  def count_items    
    @item_count = @purchased_items.tally
  end

  def calculate_total    
    @item_count.each do |item, item_quantity|
      valid_commodity = @commodity_master.fetch(item, nil)
      unit_price = valid_commodity.fetch('unit_price',nil)
      offer = valid_commodity.fetch('offer', nil)

      offer_min_quantity = nil
      offer_price = nil
      line_item_total = nil

      if offer
        offer_min_quantity, offer_price = offer.values_at('minimum_quantity', 'price')
      end

      if offer && item_quantity >= offer_min_quantity
        applicable_quantity = offer_min_quantity
        remaining_quantity = item_quantity - offer_min_quantity
                  
        line_item_total = offer_price + (remaining_quantity * unit_price)                
      else              
        line_item_total = unit_price * item_quantity      
      end
      
      @bill[item]['quantity'] = item_quantity
      @bill[item]['total_price'] = line_item_total
      @bill_total += line_item_total
      @bill_total_without_offer += unit_price * item_quantity
    end      
  end
 
  def print_bill
    puts ""
    puts("Items".ljust(25) + "Quantity".ljust(15) + "Price".ljust(15))
    puts "_" * 55

    @bill.each do| item_name, details|
      puts  item_name.ljust(25) + details['quantity'].to_s.ljust(15) + "$" +details['total_price'].to_s.ljust(15)
    end

    puts ""
    puts "Total price: $" + @bill_total.to_s
    puts "You saved $" + ((@bill_total_without_offer - @bill_total).round(2)).to_s
  end
end

# This programs considers 
# Offer applies only once per purchase. For example, if 5 milk packets 
# are bought and the offer is on 2 packets, only those 2 will be at the
# offer price — the rest will be charged at the regular unit price.

calculator = PriceCalculator.new
calculator.generate_bill
