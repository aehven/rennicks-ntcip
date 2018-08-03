require './ntcipAccess.rb'
module Test
  getter = NTCIPAccess::NTCIPGraphics.new(:port => 2230, :host=>'73.207.107.105', :community => 'Public')
  #getter = NTCIPAccess::NTCIPGraphics.new(:port => 163)
  getter.get_graphic(graphicNumber: 1)
end
