require 'ntcipAccess'
module Test
  #getter = NTCIPAccess::NTCIPMessage.new(:port => 2230, :host=>'73.207.107.105', :community => 'Public')
  status = :noError
  begin
  getter = NTCIPAccess::NTCIPMessage.new(:port => 163)

  rescue SNMP::RequestTimeout
   puts "timeout"
   status = :timeOut
  rescue => exc
   puts exc.message
   status = :snmpError
  end

  if(:noError == status)
      result = getter.set_message(messageMemoryType: ENUM_dmsMessageMemoryType::CHANGEABLE, messageNumber: 3, messageMultiString: "[g1]", messageOwner: "Doug2")
puts result.to_s
      case result
      when :noError
         puts "Set Success"
      else
         puts "Set Failure "+result.to_s
      end

      result = getter.get_message(messageMemoryType: ENUM_dmsMessageMemoryType::CHANGEABLE, messageNumber: 3)
      case result
      when :noError
         puts "Success"
         puts "multiString " + getter.messageMultiString.to_s
         puts "owner " + getter.messageOwner.to_s
         puts "beacon " + getter.messageBeacon.to_s
         puts "CRC " + getter.messageCRC.to_s
         puts "pixelService " + getter.messagePixelService.to_s
         puts "runTimePriority " + getter.messageRunTimePriority.to_s
         puts "status " + getter.messageStatus.to_s
      else
         puts "Get Failure "+result.to_s
      end
      activateResult = getter.activate_message()
      #activateResult = getter.activate_message(messageNumber: 4)
      puts "after activate " + activateResult[0].to_s + " " + activateResult[1].to_s + " " + activateResult[2].to_s
   end
end
