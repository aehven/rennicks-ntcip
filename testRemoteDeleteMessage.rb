require './ntcipAccess.rb'
module Test
  getter = NTCIPAccess::NTCIPMessage.new(:port => 2230, :host=>'73.207.107.105', :community => 'Public')
  #getter = NTCIPAccess::NTCIPMessage.new(:port => 163)

  result = getter.delete_message(messageMemoryType: ENUM_dmsMessageMemoryType::CHANGEABLE, messageNumber: 2)
  puts "delete result " + result.to_s
end
