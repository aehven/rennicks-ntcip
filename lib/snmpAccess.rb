require 'snmp'
require 'ntcipOIDList'
include SNMP

module SNMPAccess
  ACCESS_PRIVLIGES_NAME = {
    0 => :rw,
    1 => :ro
  }
  ACCESS_STATUS_NAME = {
    0 => :notTransferred,
    1 => :success,
    2 => :pduError,
    2 => :snmpError,
    3 => :timeOut
  }
  ACCESS_TYPE_NAME = {
    0 => :get,
    1 => :set
  }
  class AccessError < StandardError
  end
  class UnknownOIDError < StandardError
  end
  class TableError < StandardError
  end

  #####
  # List of AccessData objects
  ######
  class AccessList
    @@port = 161
    @@host = 'localhost'
    @@modules = ["NTCIP-1203-MIB","NTCIP-1201-MIB","NTCIP1204-2005-MIB"]
    @@modulesdir = File.expand_path(File.dirname(__FILE__) +"/mibs")
    @@community = 'administrator'
    @@version = :SNMPv1
    @@maxVarbind = 5
    @@oidList
    def initialize  oidList
      @dataArray = []
      @oidList = oidList
    end
    def add(oidName: "NULL", value: nil, index1: -1, index2: -1)
      classOrig = @oidList.locate_oid(oidName)
      if(nil == classOrig)
        raise UnknownOIDError, oidName+" not on list of known OIDs "
      end
      if(nil != value)
        if(:ro == classOrig.access)
          raise AccessError, oidName+" is read only "
        end
      end
      classDup = classOrig.dup
      classDup.set_value  value
      classDup.set_index1  index1
      classDup.set_index2  index2
      @dataArray << classDup
    end
    def [](key, index1=-1, index2=-1)
      if key.kind_of?(Integer)
        return @dataArray[key]
      else
        for i in 0...@dataArray.length
          return @dataArray[i] if (key == @dataArray[i].name) && (index1 == @dataArray[i].get_index1) && (index2 == @dataArray[i].get_index2)
        end
      end
      return nil
    end
    def get
      begin
        #puts @@host
        #puts @@port
        #puts @@community
        #puts @@modules
        #puts @@version
        nMaxRequests = @dataArray.size/@@maxVarbind
        if (nMaxRequests * @@maxVarbind) < @dataArray.size
          nMaxRequests += 1
        end
        nDataArrayIndex = 0
      SNMP::Manager.open(:Version => :SNMPv1, :port => @@port, :Host => @@host, :community => @@community) do |snmp|
        
        #####
        # load our mib modules
        ######
        snmp.load_modules(@@modules, @@modulesdir)

        for nRequests in 0...nMaxRequests
            oidArray = []
            for i in 0...@@maxVarbind
              if (i+nDataArrayIndex) < @dataArray.size
                c = @dataArray[i+nDataArrayIndex]
                oidArray << c.oidValue
              end
          end
          responsePDU = snmp.get(oidArray)
          #####
          # check error_index
          # to see which varbind caused the error
          #####
          if(:noError == responsePDU.error_status)
            responsePDU.each_varbind { |vb| 
              if nil != vb 
                value=vb.value
                c = @dataArray[nDataArrayIndex]
                nDataArrayIndex = nDataArrayIndex + 1
                c.set_value(value)
                c.set_pduError(:noError)
                c.set_accessError(:success)
                c.set_lastUpdateTime
                #puts value
              end
          }
          else
            @dataArray.each { |c| 
              c.set_pduError(responsePDU.error_status)
              c.set_accessError(:pduError)
            }
          end
        end
        #####
        # return the response
        ######
        responsePDU.error_status;
      end
      rescue SNMP::RequestTimeout
        #puts "timeout"
        @dataArray.each { |c|
        c.set_accessError(:timeOut)
        }
        :timeOut
      rescue => exc
        puts exc.message
        @dataArray.each { |c|
        c.set_accessError(:pduError)
        }
        :pduError
      end
    end
    def set
      oidArray = []
      vbArray = []

      begin
      SNMP::Manager.open(:Version => @@version, :port => @@port, :Host => @@host, :community => @@community ) do |snmp|
        
        #####
        # load our mib modules
        ######
        snmp.load_modules(@@modules, @@modulesdir)

        @dataArray.each { |c|
          oidArray << c.oidValue
          vbArray << c.varbind(snmp:snmp)
        }
        dataArrayEnumerator = @dataArray.each
        responsePDU = snmp.set(vbArray)
        #####
        # check error_index
        # to see which varbind caused the error
        #####
        if(:noError == responsePDU.error_status)
          responsePDU.each_varbind { |vb| 
          c = dataArrayEnumerator.next
          c.set_pduError(:noError)
          c.set_accessError(:success)
          c.set_lastUpdateTime
        }
        else
          @dataArray.each { |c| 
            c.set_pduError(response.error_status)
            c.set_accessError(:pduError)
          }
        end
       responsePDU.error_status;
      end
      rescue SNMP::RequestTimeout
        #puts "timeout"
        @dataArray.each { |c|
        c.set_accessError(:timeOut)
        }
        :timeOut
      rescue => e
        #puts e.message
        @dataArray.each { |c|
        c.set_accessError(:snmpError)
        c.set_pduError(:pduError)
        }
        :snmpError
      end
    end
  end
  
  #####
  # SNMP OID access data element
  # (one for each SNMP OID)
  ######
  class OIDAccess
      @@port = 161
      @@host = 'localhost'
      @@modules = ["NTCIP-1203-MIB","NTCIP-1201-MIB","NTCIP1204-2005-MIB"]
      @@community = 'administrator'

    #def initialize oidName, size, access, tableName="", tableColumn=-1, nTableIndexes=0
    def initialize(oidName:, size:, access:, tableName: '', tableColumn: 0, nTableIndexes: 0, value: nil, index1: -1, index2: -1)
      @oidName = oidName
      @size = size
      @access = access
      @value = value
      @index1 = index1
      @index2 = index2
      @tableName = tableName
      @tableColumn = tableColumn
      @nTableIndexes = nTableIndexes
      @accessError = :notTransfered
      @pduError = :noError
      @lastUpdateTime = nil
    end

    private
    def verify_indicies index1, index2
      if(((0 < @nTableIndexes) && (-1 == index1)) || (1 < @nTableIndexes) && (-1 == index2))
        raise TableError, @oidName+" requires "+ @nTableIndexes.to_s+" Indicies"
      end
    end

    public
    def calc_oid index1, index2
      thisOID = @oidName
      verify_indicies index1, index2
      oidExtension = ".0"
      if("" != @tableName)
        oidExtension=".1."+@tableColumn.to_s+"."+index1.to_s
        if(-1 != index2)
          oidExtension=".1."+@tableColumn.to_s+"."+index1.to_s+"."+index2.to_s
        end
        thisOID = @tableName
      end
      thisOID+oidExtension
    end

    def get_accessError
      @accessError
    end
    def set_accessError error
      @accessError = error
    end
    def get_pduError
      @pduError
    end
    def set_pduError error
      @pduError = error
    end
    def get_lastUpdateTime
      @lastUpdateTime
    end
    def set_lastUpdateTime
      @lastUpdateTime = Time.now.utc
    end
    def access
      @access
    end
    def set_value value
      @value = value
    end
    def get_value
      @value
    end
    def value
      @value
    end
    def set_index1 index1
      @index1 = index1
    end
    def get_index1
      @index1
    end
    def set_index2 index2
      @index2 = index2
    end
    def get_index2
      @index2
    end
    def name
      @oidName
    end
    def oidValue index1=-1, index2=-1
      if(-1 == index1)
        index1 = @index1
        index2 = @index2
      end
      calc_oid index1, index2
    end
    def varbind(snmp:, value:nil, index1:-1, index2:-1)
      if(nil == value)
        ####
        # no external value so use the class variable
        ####
        value = @value
      end
      if(-1 == index1)
        ####
        # no external indexes so use the class variables
        ####
        index1 = @index1
        index2 = @index2
      end
      VarBind.new(snmp::mib.oid(oid(index1, index2)), value)
    end
    #####
    # get just this OID
    #####
    def get index1=-1, index2=-1
      verify_indicies(index1, index2)
      theOID = calc_oid(index1, index2)
      begin
        SNMP::Manager.open(:Version => @@version, :port => @@port, :Host => @@host, :community => @@community) do |snmp|
        
          #####
          # load our mib modules
          ######
          snmp.load_modules(@@modules, @@modulesdir)

          response = snmp.get(theOID)
          if(:noError == response.error_status)
          response.each_varbind { |vb| value=vb.value }
          value
          end
        end

      rescue SNMP::RequestTimeout
        #puts "timeout"
        #@accessError = :timeOut
      rescue => exc
        #puts exc.message
        #@accessError = :timeOut
      end

    end
    
    #####
    # set just this OID
    #####
    def set value, index1=-1, index2=-1
      if :ro == @access
        return nil
      end
      verify_indicies(index1, index2)
      theOID = calc_oid(index1, index2)
      begin
        SNMP::Manager.open(:Version => @@version, :port => @@port, :Host => @@host, :community => @@community ) do |snmp|
        
          #####
          # load our mib modules
          ######
          snmp.load_modules(@@modules, @@modulesdir)

          snmp.set(varbind(snmp:snmp, value: value, index1:index1, index2:index2))
        end
      rescue SNMP::RequestTimeout
        #puts "timeout"
        #@accessError = :timeOut
      rescue => exc
        #puts exc.message
        #@accessError = :timeOut
      end
  
    end
    def to_s
      a = ""
      @value.each_byte { |b| a << b.chr }
      sprintf("%s", a)
    end
    def to_hex
      a = ""
      @value.each_byte { |b| a << b.to_s(16) }
      sprintf("%s", a)
    end
  end
  class OIDAccessInt < OIDAccess
    def set value, index1=-1, index2=-1
      super SNMP::Integer.new(value), index1, index2
    end
    def varbind(snmp:, value:nil, index1:-1, index2:-1)
      if(nil == value)
        ####
        # no external value so use the class variable
        ####
        value = @value
      end
      if(-1 == index1)
        ####
        # no external indexes so use the class variables
        ####
        index1 = @index1
        index2 = @index2
      end
      VarBind.new(snmp::mib.oid(oidValue(index1, index2)), SNMP::Integer.new(value))
    end
  end
  class OIDAccessInt32 < OIDAccessInt
  end
  class OIDAccessUInt < OIDAccessInt
  end
  class OIDAccessUInt32 < OIDAccessInt
  end
  class OIDAccessCounter < OIDAccessInt
  end
  class OIDAccessEnum < OIDAccessInt
  end
  class OIDAccessString < OIDAccess
    def set value, index1=-1, index2=-1
      super SNMP::OctetString.new(value), index1, index2
    end
    def get_value
      if(nil != @value)
        SNMP::OctetString.new(@value)
      else
        @value
      end
    end
    def varbind(snmp:, value:nil, index1:-1, index2:-1)
      if(nil == value)
        ####
        # no external value so use the class variable
        ####
        value = @value
      end
      if(-1 == index1)
        ####
        # no external indexes so use the class variables
        ####
        index1 = @index1
        index2 = @index2
      end
      #####
      # if data is held in an array
      # convert to string
      ######
      v2 = value
      if value.kind_of?(Array)
        v2 = value.pack('c*')
      end
      VarBind.new(snmp::mib.oid(oidValue(index1, index2)), SNMP::OctetString.new(v2))
    end
  end
  class OIDAccessIPAddress < OIDAccessString
  end
  class OIDAccessDisplayString < OIDAccessString
  end
  class OIDAccessOwnerString < OIDAccessString
  end
  class OIDAccessMessageIDCode < OIDAccessString
  end
  class OIDAccessMessageActivationCode < OIDAccessString
  end
  class OIDAccessOerString < OIDAccessString
  end
  class OIDAccessObjectID < OIDAccess
    def set value, index1=-1, index2=-1
      super SNMP::ObjectID.new.new(value), index1, index2
    end
    def varbind(snmp:, value:nil, index1:-1, index2:-1)
      if(nil == value)
        ####
        # no external value so use the class variable
        ####
        value = @value
      end
      if(-1 == index1)
        ####
        # no external indexes so use the class variables
        ####
        index1 = @index1
        index2 = @index2
      end
      VarBind.new(snmp::mib.oid(oidValue(index1, index2)), SNMP::ObjectID.new(value))
    end
  end
end
