
require './ntcipAccess.rb'
module Test
  #getter = NTCIPAccess::NTCIPGraphics.new(:port => 2230, :host=>'73.207.107.105', :community => 'Public')
  getter = NTCIPAccess::NTCIPGraphics.new(:port => 163)

  result = getter.delete_graphic(graphicIndex: 2)
  puts "delete result " + result.to_s
end
