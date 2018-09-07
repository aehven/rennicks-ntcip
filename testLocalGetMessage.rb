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
         case getter.messageStatus
            when ENUM_dmsMessageStatus::NOTUSED
               puts "notused"
            when ENUM_dmsMessageStatus::MODIFYING
               puts "modifying"
            when ENUM_dmsMessageStatus::VALIDATING
               puts "validating"
            when ENUM_dmsMessageStatus::VALID
               puts "valid"
            when ENUM_dmsMessageStatus::ERROR
               puts "error"
            when ENUM_dmsMessageStatus::MODIFYREQ
               puts "modifyreq"
            when ENUM_dmsMessageStatus::VALIDATEREQ
               puts "validatereq"
            when ENUM_dmsMessageStatus::NOTUSEDREQ
               puts "notusedreq"
            else
               puts "unknown"
            end
      else
         puts "Get Failure "+result.to_s
      end
   end
end
