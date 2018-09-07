require 'ntcipAccess'
module Test
  #getter = NTCIPAccess::NTCIPGraphics.new(:port => 2230, :host=>'73.207.107.105', :community => 'Public')
  getter = NTCIPAccess::NTCIPGraphics.new(:port => 163)
  status = getter.get_graphic(graphicIndex: 1)
  puts status.to_s
  if :noError == status
   puts getter.graphicBitmap.to_s
  end
end
