require 'ntcipAccess'
module Test
  #getter = NTCIPAccess::NTCIPSimple.new(:port => 2230, :host=>'73.207.107.105', :community => 'Public')
  getter = NTCIPAccess::NTCIPSimple.new(:port => 163)

  result = getter.get_list(['dmsSignType','dmsSignHeight','signVolts','essLatitude','essLongitude','defaultFlashOn','defaultFlashOff'])
puts "1-result: "+result.to_s
  case result
  when :noError
    puts "Success"
    puts "Type " + getter.get_value('dmsSignType').to_s
    puts "Height " + getter.get_value('dmsSignHeight').to_s
    puts "Volts " + getter.get_value('signVolts').to_s
    puts "Latitude " + getter.get_value('essLatitude').to_s
    puts "Longitude " + getter.get_value('essLongitude').to_s
    puts "DefaultFlashOn " + getter.get_value('defaultFlashOn').to_s
    puts "DefaultFlashOff " + getter.get_value('defaultFlashOff').to_s
  else
    puts "Failure"
  end

  setter = NTCIPAccess::NTCIPSimple.new(:port => 163)

  result = setter.set_list([['defaultFlashOn', 15],['defaultFlashOff',1]])
puts "2-result: "+result.to_s
  case result
  when :noError
    puts "Success"
  else
    puts "Failure"
  end

  result = setter.get_single('defaultFlashOn')
puts "3-result: "+result.to_s
  case result
  when :noError
    puts "Success"
    puts "DefaultFlashOn " + getter.get_value('defaultFlashOn').to_s
  else
    puts "Failure"
  end
  result = setter.set_single('defaultFlashOn', 10)
puts "4-result: "+result.to_s
  case result
  when :noError
    puts "Success"
  else
    puts "Failure"
  end


end
