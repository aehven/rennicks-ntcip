require './ntcipAccess.rb'
module Test
  #getter = NTCIPAccess::NTCIPMessage.new(:port => 2230, :host=>'73.207.107.105', :community => 'Public')
  getter = NTCIPAccess::NTCIPMessage.new(:port => 163)

  result = getter.set_message(messageMemoryType: ENUM_dmsMessageMemoryType::CHANGEABLE, messageNumber: 3, messageMultiString: "[g1]", messageOwner: "Doug2")

  result = getter.get_message(messageMemoryType: ENUM_dmsMessageMemoryType::CHANGEABLE, messageNumber: 3)
  case result
  when :success
    puts "Success"
    puts "multiString " + getter.messageMultiString.to_s
    puts "owner " + getter.messageOwner.to_s
    puts "beacon " + getter.messageBeacon.to_s
    puts "CRC " + getter.messageCRC.to_s
    puts "pixelService " + getter.messagePixelService.to_s
    puts "runTimePriority " + getter.messageRunTimePriority.to_s
    puts "status " + getter.messageStatus.to_s
  when :failure
    puts "Failure"
  end
  activateResult = getter.activate_message()
  puts "after activate " + activateResult[0].to_s + " " + activateResult[1].to_s + " " + activateResult[2].to_s

end
