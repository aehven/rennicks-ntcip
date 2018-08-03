require './ntcipAccess.rb'
module Test
  getter = NTCIPAccess::NTCIPSimple.new(:port => 2230, :host=>'73.207.107.105', :community => 'Public')
  #getter = NTCIPAccess::NTCIPSimple.new(:port => 163)

  result = getter.get_list(['dmsSignType','dmsSignHeight','signVolts','essLatitude','essLongitude'])
  case result
  when :success
    puts "Success"
    puts "Type " + getter.get_value('dmsSignType').to_s
    puts "Height " + getter.get_value('dmsSignHeight').to_s
    puts "Volts " + getter.get_value('signVolts').to_s
    puts "Latitude " + getter.get_value('essLatitude').to_s
    puts "Longitude " + getter.get_value('essLongitude').to_s
  when :failure
    puts "Failure"
  end
end
