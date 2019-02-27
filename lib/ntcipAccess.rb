require 'ntcipOIDList'
require 'ntcipEnums'
require 'bmp'

module NTCIPAccess
    RESULT_MESSAGE = {
      0 => :noError,
      1 => :invalidMessageNumber,
      3 => :invalidMessageCRC,
      4 => :invalidGraphicIndex,
      5 => :cantWrite
    }
  class SNMPError < StandardError
  end
  class MessageActivationCode
    def initialize( octetString: nil, messageMemoryType: ENUM_dmsMessageMemoryType::CHANGEABLE, messageNumber: 1, messageCRC: 0, duration: nil, activatePriority: nil, sourceAddress: nil)
      if nil == octetString
        @messageMemoryType = messageMemoryType
        @messageNumber = messageNumber
        @messageCRC = messageCRC
        @duration = duration
        if nil == @duration
          @duration = 65535
        end
        @activatePriority = activatePriority
        if nil == @activatePriority
          @activatePriority = 1
        end
        @sourceAddress = sourceAddress
        if nil == @sourceAddress
          @sourceAddress = (127<<24) + 1
        end
       else
         #####
         # initialize from OctetString
         #####
         setArray = octetString.bytes.to_a
         @duration = (setArray[0]*256)+setArray[1]
         @activationPriority = setArray[2]
         @messageMemoryType = setArray[3]
         @messageNumber = (setArray[4]*256)+setArray[5]
         @messageCRC = (setArray[6]*256) + setArray[7]
         @sourceAddress = (setArray[8]*16777216)+( setArray[9]*65536)+(setArray[10]*256)+setArray[11]
      end
    end
    def messageMemoryType
      @messageMemoryType
    end
    def messageNumber
      @messageNumber
    end
    def messageCRC
      @messageCRC
    end
    def activatePriority
      @activatePriority
    end
    def duration
      @duration
    end
    def sourceAddress
      @sourceAddress
    end
    def get_value
      value = []
      value << ((@duration >> 8) & 0xff)
      value << (@duration & 0xff)
      value << (@activatePriority & 0xff)
      value << (@messageMemoryType & 0xff)
      value << ((@messageNumber >> 8) & 0xff)
      value << (@messageNumber & 0xff)
      value << ((@messageCRC >> 8) & 0xff)
      value << (@messageCRC & 0xff)
      value << ((@sourceAddress >> 24) & 0xff)
      value << ((@sourceAddress >> 16) & 0xff)
      value << ((@sourceAddress >> 8) & 0xff)
      value << (@sourceAddress & 0xff)
      value.pack('C*')
   end
   def ==(otherMessageActivationCode)
      retVal = true
      if @messageMemoryType != otherMessageActivationCode.messageMemoryType
        retVal = false
      elsif @messageNumber != otherMessageActivationCode.messageNumber
        retVal = false
      elsif @messageCRC != otherMessageActivationCode.messageCRC
        retVal = false
      elsif @sourceAddress != otherMessageActivationCode.sourceAddress
        retVal = false
      end
      retVal
   end
  end
  class NTCIPAccess
    def initialize(port: 161, community: 'administrator', host: 'localhost', graphicStyle: 'AMSIG')
      SNMPAccess::AccessList.class_variable_set(:@@port, port)
      SNMPAccess::AccessList.class_variable_set(:@@community, community)
      SNMPAccess::AccessList.class_variable_set(:@@host, host)
      SNMPAccess::AccessList.class_variable_set(:@@maxVarbind, 6)
      @graphicStyle = graphicStyle
      end
    def get oidList
      oidList.get
    end
    def set oidList
      oidList.set
    end
  end
  class NTCIPGraphics < NTCIPAccess
    def initialize(port: 161, community: 'administrator', host: 'localhost', graphicStyle: 'AMSIG')

      super


      @oidList = NTCIPOIDList::TheList.new
      getter = SNMPAccess::AccessList.new @oidList
      getter.add(oidName: "vmsSignWidthPixels")
      getter.add(oidName: "vmsSignHeightPixels")
      getter.add(oidName: "dmsGraphicMaxEntries")
      getter.add(oidName: "dmsGraphicNumEntries")
      getter.add(oidName: "dmsGraphicMaxSize")
      getter.add(oidName: "availableGraphicMemory")
      getter.add(oidName: "dmsGraphicBlockSize")
      status = get(getter)
      if :noError ==  status
        @signWidth = getter["vmsSignWidthPixels"].value.to_i
        @signHeight = getter["vmsSignHeightPixels"].value.to_i
        @graphicMaxEntries = getter["dmsGraphicMaxEntries"].value.to_i
        @graphicNumEntries = getter["dmsGraphicNumEntries"].value.to_i
        @graphicMaxSize = getter["dmsGraphicMaxSize"].value.to_i
        @graphicAvailableMemory = getter["availableGraphicMemory"].value.to_i
        @graphicBlockSize = getter["dmsGraphicBlockSize"].value.to_i
        #puts "signWidth:" + " " + @signWidth.to_s
        #puts "signHeight:" + " " + @signHeight.to_s
        #puts "graphicMaxEntries: " + @graphicMaxEntries.to_s
        #puts "graphicNumEntries: " + @graphicNumEntries.to_s
        #puts "graphicMaxSize: " + @graphicMaxSize.to_s
        #puts "graphicAvailableMemory: " +@graphicAvailableMemory.to_s
        #puts "graphicBlockSize: " + @graphicBlockSize.to_s
      end
      status
    end
    def graphicName
       @graphicName
    end
    def graphicIndex
       @graphicIndex
    end
    def graphicNumber
       @graphicNumber
    end
    def graphicWidth
       @graphicWidth
    end
    def graphicHeight
       @graphicHeight
    end
    def graphicID
       @graphicID
    end
    def graphicTransparentEnabled
       @graphicTransparentEnabled
    end
    def graphicTransparentColor
       @graphicTransparentColor
    end
    def graphicStatus
       @graphicStatus
    end
    def graphicBitmap
       @graphicBitmap
    end
    def graphicType
       @graphicType
    end
    def bmp_to_a (bmpFileName)
      theBMP = Bitmap.new(bmpFileName)
      nWidth = theBMP.width
      nHeight = theBMP.height
      #####
      # C* is unsigned
      # c* would be signed
      ######
      bma = theBMP.bm.unpack('C*')
      bmMap = []
      for nH in 0...nHeight
        bmMap[nH] = []
      end
      nW = 0
      nH = 0
      i = 0
      while i + 2 < bma.length
        j = bma[i]+bma[i+1] + bma[i+2]
        bmMap[nH][nW] =  j
        nW += 1
        if nW >= nWidth
          nW = 0
          nH += 1
        end
        i += 3
      end
      nBitIndex = 7
      currentByte = 0
      ntcipBM = []
      for nH in (nHeight-1).downto(0)
        for nW in 0...nWidth
          if bmMap[nH][nW] != 0
            currentByte |= 1<<nBitIndex
          end
          nBitIndex -= 1
          if 0 > nBitIndex
            ntcipBM << currentByte
            nBitIndex = 7
            currentByte = 0
          end
        end
      end
      ntcipBM
    end
    def get_graphic(graphicIndex: nil, bitsPerPixelOverride: 1)
      @graphicIndex = graphicIndex
      #puts "graphicIndex " + graphicIndex.to_s
      status = :invalidGraphicIndex
      #####
      # DEH 11/17/18
      # if we failed to connect to the sign
      # we won't have @graphicMaxEntries
      # we need to error out here, or before here
      ######
      if (graphicIndex > 0) && (graphicIndex <= @graphicMaxEntries)
           getter = SNMPAccess::AccessList.new @oidList
           getter.add(oidName: "dmsGraphicNumber", index1: graphicIndex)
           getter.add(oidName: "dmsGraphicName", index1: graphicIndex)
           getter.add(oidName: "dmsGraphicHeight", index1: graphicIndex)
           getter.add(oidName: "dmsGraphicWidth", index1: graphicIndex)
           getter.add(oidName: "dmsGraphicType", index1: graphicIndex)
           getter.add(oidName: "dmsGraphicID", index1: graphicIndex)
           getter.add(oidName: "dmsGraphicTransparentEnabled", index1: graphicIndex)
           getter.add(oidName: "dmsGraphicTransparentColor", index1: graphicIndex)
           getter.add(oidName: "dmsGraphicStatus", index1: graphicIndex)
           status =  get(getter)
           if :noError ==  status
              @graphicNumber = getter["dmsGraphicNumber", graphicIndex].value.to_i
              @graphicName = getter["dmsGraphicName", graphicIndex].value.to_s
              @graphicHeight = getter["dmsGraphicHeight", graphicIndex].value.to_i
              @graphicWidth = getter["dmsGraphicWidth", graphicIndex].value.to_i
              @graphicType = getter["dmsGraphicType", graphicIndex].value.to_i
              @graphicID = getter["dmsGraphicID", graphicIndex].value.to_i
              @graphicTransparentEnabled = getter["dmsGraphicTransparentEnabled", graphicIndex].value.to_i
              @graphicTransparentColor = getter["dmsGraphicTransparentColor", graphicIndex].value.to_s.bytes
              @graphicStatus = getter["dmsGraphicStatus", graphicIndex].value.to_i
              #puts "graphicNumber " + @graphicNumber.to_s
              #puts "graphicName " + @graphicName.to_s
              #puts "graphicHeight " + @graphicHeight.to_s
              #puts "GraphicWidth " + @graphicWidth.to_s
              #puts "graphicType " + @graphicType.to_s
              #puts "graphicID " + @graphicID.to_s
              #puts "graphicITransparentEnabled " + @graphicTransparentEnabled.to_s
              #puts "graphicITransparentColor " + @graphicTransparentColor.to_s
              #puts "graphicStatus " + @graphicStatus.to_s
              #####
              # now get the bitmap
              ######

              #####
              # calculate bitmap size
              ######
              bmSizeBits = @graphicHeight*@graphicWidth
              case @graphicType
              when ENUM_dmsColorScheme::MONOCHROME1BIT
                #####
                # American signal uses 2 bits per pixel
                # for their color signs
                # so adjust the size here
                ######
                bmSizeBytes = (bmSizeBits*bitsPerPixelOverride)/8
                if (bmSizeBytes*8) < bmSizeBits
                  bmSizeBytes = bmSizeBytes + 1
                end
                bmSize = bmSizeBytes
              when ENUM_dmsColorScheme::MONOCHROME8BIT
                bmSize = bmSizeBits
              when ENUM_dmsColorScheme::COLORCLASSIC
                bmSize = bmSizeBits
              when ENUM_dmsColorScheme::COLOR24BIT
                bmSize = bmSizeBits*3
              else
                bmSize = 0
              end
              #####
              # calculate the number of blocks
              ######
               if 'AMSIG' == @graphicStyle
                  bmBlocks = 1
               else
                  bmBlocks = bmSize/@graphicBlockSize
                  if(bmBlocks*@graphicBlockSize) < bmSize
                    bmBlocks = bmBlocks + 1
                  end
               end

              #####
              # get each block
              ######
              @graphicBitmap = []
              for i in 1..bmBlocks
                getter = SNMPAccess::AccessList.new @oidList
                getter.add(oidName: "dmsGraphicBlockBitmap", index1: graphicIndex, index2: i)
                block = []
                status =  get(getter)
                if :noError ==  status
                  block = getter["dmsGraphicBlockBitmap", graphicIndex, i].value
                  @graphicBitmap << block
                else
                  return status
                end
              end
           end
      end
      status

    end
    def set_graphic(bmpFile: nil, imageArray: nil, graphicIndex:, graphicNumber: nil, graphicName: "", graphicHeight: @signHeight, graphicWidth: @signWidth, graphicType: ENUM_dmsColorScheme::MONOCHROME1BIT, transparentEnabled: 0, transparentColor: [1, 0, 0])
      #puts "set_graphic graphicName " + graphicName + " graphicHeight " + graphicHeight.to_s + " width " + graphicWidth.to_s
      @graphicIndex = graphicIndex
      if nil == graphicNumber
        @graphicNumber = graphicIndex
      else
        @graphicNumber = graphicNumber
      end
      @graphicName = graphicName
      @graphicHeight = graphicHeight
      @graphicWidth = graphicWidth
      @graphicType = graphicType
      @graphicTransparentEnabled = transparentEnabled
      @graphicTransparentColor = transparentColor
      #####
      # if bmp not nil
      # then convert it to imageArray
      #####
      if nil != bmpFile
        imageArray = bmp_to_a(bmpFile)
      end
      #puts imageArray.to_s

      ######
      # set status to modifying
      ######
      status = :invalidGraphicIndex
      #####
      # DEH 11/17/18
      # if we failed to connect to the sign
      # we won't have @graphicMaxEntries
      # we need to error out here, or before here
      ######
      if (graphicIndex > 0) && (graphicIndex <= @graphicMaxEntries)
        #####
        # set the status to modifying
        #####
        setter = SNMPAccess::AccessList.new @oidList
        setter.add(oidName: "dmsGraphicStatus", value: ENUM_dmsGraphicStatus::MODIFYREQ, index1: graphicIndex)
        status =  set(setter)
        if :noError ==  status
          #####
          # set the
          # graphic number
          # graphic name
          # graphic height
          # graphic width
          # graphic type
          # graphic transparentEnabled
          # graphic transparentColor
          #####
          setter = SNMPAccess::AccessList.new @oidList
          setter.add(oidName: "dmsGraphicNumber", value: @graphicNumber, index1: graphicIndex)
          setter.add(oidName: "dmsGraphicName", value: @graphicName, index1: graphicIndex)
          setter.add(oidName: "dmsGraphicHeight", value: @graphicHeight, index1: graphicIndex)
          setter.add(oidName: "dmsGraphicWidth", value: @graphicWidth, index1: graphicIndex)
          setter.add(oidName: "dmsGraphicType", value: @graphicType, index1: graphicIndex)
          setter.add(oidName: "dmsGraphicTransparentEnabled", value: @graphicTransparentEnabled, index1: graphicIndex)
          setter.add(oidName: "dmsGraphicTransparentColor", value: @graphicTransparentColor, index1: graphicIndex)
          status =  set(setter)
          if :noError == status
            #####
            # now, set the bitmap
            ######
  
            #####
            # break it up into block sized chunks
            ######
            if 'AMSIG' == @graphicStyle
              setter = SNMPAccess::AccessList.new @oidList
              setter.add(oidName: "dmsGraphicBlockBitmap", value: imageArray, index1: graphicIndex, index2: 1)
              status = set(setter)
              if :noError !=  status
                puts "Error setting block"
              end
            else
               nBlocks = imageArray.size/@graphicBlockSize
               if imageArray.size > (nBlocks*@graphicBlockSize)
               nBlocks += 1
               end
               ####
               # 0-nBlocks exclusive
               ######
               for i in 0...nBlocks
               nStart = i*@graphicBlockSize
               nEnd = nStart + ((i+1)*@graphicBlockSize)-1
               if nEnd > imageArray.size
                  nEnd = imageArray.size
               end
               thisBlock = imageArray[nStart, nEnd]
               tb2 = []
               for j in 0...@graphicBlockSize
                  tb2[j] = 0
               end
               for j in 0...thisBlock.size
                  tb2[j] = thisBlock[j]
               end
              setter = SNMPAccess::AccessList.new @oidList
              #setter.add(oidName: "dmsGraphicBlockBitmap", value: thisBlock, index1: graphicIndex, index2: i+1)
              setter.add(oidName: "dmsGraphicBlockBitmap", value: tb2, index1: graphicIndex, index2: i+1)
              status = set(setter)
              if :noError !=  status
                puts "Error setting block"
                break;
              end
             end
            end

            if :noError == status
               #####
               # set ready for use
               #####
               setter = SNMPAccess::AccessList.new @oidList
               setter.add(oidName: "dmsGraphicStatus", value: ENUM_dmsGraphicStatus::READYFORUSEREQ, index1: graphicIndex)
               if :noError !=  set(setter)
                 puts "Error setting Ready For Use"
               end
            end

            if :noError == status
               #####
               # check status
               # throw an error if not ready for use
               ######
               getter = SNMPAccess::AccessList.new @oidList
               getter.add(oidName: "dmsGraphicStatus", index1: graphicIndex)
               status =  get(getter)
               if :noError == status
                  if ENUM_dmsGraphicStatus::READYFORUSE != graphicStatus = getter["dmsGraphicStatus", graphicIndex].value.to_i
                     status = :snmpError
                  else
                     status = :noError
                  end
               end
            end
          end
        end
      end
      status
    end
    def delete_graphic( graphicIndex:)

      if nil == graphicIndex
        graphicIndex = @graphicIndex
      end
      ######
      # check status?
      # can't delete if inUse
      ######
      setter = SNMPAccess::AccessList.new @oidList
      setter.add(oidName: "dmsGraphicStatus", value: ENUM_dmsGraphicStatus::NOTUSEDREQ, index1: graphicIndex)
      status =  set(setter)
    end
  end
  class NTCIPMessage < NTCIPAccess
    def initialize(port: 161, community: 'administrator', host: 'localhost')

      super

      @oidList = NTCIPOIDList::TheList.new
      getter = SNMPAccess::AccessList.new @oidList
      getter.add(oidName: "dmsNumPermanentMsg")
      getter.add(oidName: "dmsNumChangeableMsg")
      getter.add(oidName: "dmsMaxChangeableMsg")
      getter.add(oidName: "dmsFreeChangeableMemory")
      getter.add(oidName: "dmsNumVolatileMsg")
      getter.add(oidName: "dmsMaxVolatileMsg")
      getter.add(oidName: "dmsFreeVolatileMemory")
      status =  get(getter)
      if :noError ==  status
        @numPermanentMsg = getter["dmsNumPermanentMsg"].value.to_i
        @numChangeableMsg = getter["dmsNumChangeableMsg"].value.to_i
        @maxChangeableMsg = getter["dmsMaxChangeableMsg"].value.to_i
        @freeChangableMemory = getter["dmsFreeChangeableMemory"].value.to_i
        @numVolatileMsg = getter["dmsNumVolatileMsg"].value.to_i
        @maxVolatileMsg = getter["dmsMaxVolatileMsg"].value.to_i
        @freeVolatileMemory = getter["dmsFreeVolatileMemory"].value.to_i
        #puts "numPermanentMsg:" + " " + @numPermanentMsg.to_s
        #puts "numChangableMsg:" + " " + @numChangeableMsg.to_s
        #puts "maxChangableMsg: " + @maxChangeableMsg.to_s
        #puts "freeChangeableMemory: " + @freeChangableMemory.to_s
        #puts "numVolatileMsg: " + @numVolatileMsg.to_s
        #puts "maxVolatileMsg: " +@maxVolatileMsg.to_s
        #puts "freeVolatileMemory: " + @freeVolatileMemory.to_s
      else
         raise SNMPError, "Can't get info "+ status.to_s
      end
    end
    def messageMemoryType
       @messageMemoryType
    end
    def messageNumber
       @messageNumber
    end
    def messageMultiString
       @messageMultiString
    end
    def messageOwner
       @messageOwner
    end
    def messageCRC
       @messageCRC
    end
    def messageBeacon
       @messageBeacon
    end
    def messagePixelService
       @messagePixelService
    end
    def messageRunTimePriority
       @messageRunTimePriority
    end
    def messageStatus
       @messageStatus
    end
    def get_message(messageMemoryType:, messageNumber:)
      @messageMemoryType = messageMemoryType
      @messageNumber = messageNumber
      case @messageMemoryType
      when ENUM_dmsMessageMemoryType::PERMANENT
        if @messageNumber > @numPermanentMsg
          return :invalidMessageNumber
        end
      when ENUM_dmsMessageMemoryType::CHANGEABLE
        if @messageNumber > @maxChangeableMsg
          return :invalidMessageNumber
        end
      when ENUM_dmsMessageMemoryType::VOLATILE
        if @messageNumber > @maxVolatileMsg
          return :invalidMessageNumber
        end
      when ENUM_dmsMessageMemoryType::CURRENTBUFFER
        if @messageNumber > 1
          return :invalidMessageNumber
        end
      when ENUM_dmsMessageMemoryType::SCHEDULE
        if @messageNumber > 1
          return :invalidMessageNumber
        end
      when ENUM_dmsMessageMemoryType::BLANK
        if @messageNumber > 255
          return :invalidMessageNumber
        end
      end
      getter = SNMPAccess::AccessList.new @oidList
      getter.add(oidName: "dmsMessageMultiString", index1: @messageMemoryType, index2: @messageNumber)
      getter.add(oidName: "dmsMessageOwner", index1: @messageMemoryType, index2: @messageNumber)
      getter.add(oidName: "dmsMessageCRC", index1: @messageMemoryType, index2: @messageNumber)
      getter.add(oidName: "dmsMessageBeacon", index1: @messageMemoryType, index2: @messageNumber)
      getter.add(oidName: "dmsMessagePixelService", index1: @messageMemoryType, index2: @messageNumber)
      getter.add(oidName: "dmsMessageRunTimePriority", index1: @messageMemoryType, index2: @messageNumber)
      getter.add(oidName: "dmsMessageStatus", index1: @messageMemoryType, index2: @messageNumber)
      status = get(getter)
      if :noError ==  status
         @messageMultiString = getter["dmsMessageMultiString", @messageMemoryType, @messageNumber].value.to_s
         @messageOwner = getter["dmsMessageOwner", @messageMemoryType, @messageNumber].value.to_s
         @messageCRC = getter["dmsMessageCRC", @messageMemoryType, @messageNumber].value.to_i
         @messageBeacon = getter["dmsMessageBeacon", @messageMemoryType, @messageNumber].value.to_i
         @messagePixelService = getter["dmsMessagePixelService", @messageMemoryType, @messageNumber].value.to_i
         @messageRunTimePriority = getter["dmsMessageRunTimePriority", @messageMemoryType, @messageNumber].value.to_i
         @messageStatus = getter["dmsMessageStatus", @messageMemoryType, @messageNumber].value.to_i
         #puts "messageMultiString " + @messageMultiString.to_s
         #puts "messageOwner " + @messageOwner.to_s
         #puts "messageCRC " + @messageCRC.to_s
         #puts "messageBeacon " + @messageBeacon.to_s
         #puts "messagePixelService " + @messagePixelService.to_s
         #puts "messageRunTimePriority " + @messageRunTimePriority.to_s
         #puts "messageStatus " + @messageStatus.to_s
      end
      status
    end
    def set_message(messageMemoryType:, messageNumber:, messageMultiString: "", messageOwner: "local", messageBeacon: 0, messagePixelService: 0, messageRunTimePriority: 1)
      @messageMemoryType = messageMemoryType
      @messageNumber = messageNumber
      @messageMultiString = messageMultiString
      @messageOwner = messageOwner
      @messageBeacon = messageBeacon
      @messagePixelService = messagePixelService
      @messageRunTimePriority = messageRunTimePriority
      case @messageMemoryType
      when ENUM_dmsMessageMemoryType::PERMANENT
          return :cantWrite
      when ENUM_dmsMessageMemoryType::CHANGEABLE
        if @messageNumber > @maxChangeableMsg
          return :invalidMessageNumber
        end
      when ENUM_dmsMessageMemoryType::VOLATILE
        if @messageNumber > @maxVolatileMsg
          return :invalidMessageNumber
        end
      when ENUM_dmsMessageMemoryType::CURRENTBUFFER
          return :cantWrite
      when ENUM_dmsMessageMemoryType::SCHEDULE
          return :cantWrite
      when ENUM_dmsMessageMemoryType::BLANK
          return :cantWrite
      end

      #####
      # set the status to modifying
      #####
      setter = SNMPAccess::AccessList.new @oidList
      setter.add(oidName: "dmsMessageStatus", value: ENUM_dmsMessageStatus::MODIFYREQ, index1: @messageMemoryType, index2: @messageNumber)
      status =  set(setter)
      if :noError ==  status
        #####
        # now set the message details
        #####
        setter = SNMPAccess::AccessList.new @oidList
        setter.add(oidName: "dmsMessageMultiString", value: @messageMultiString, index1: @messageMemoryType, index2: @messageNumber)
        setter.add(oidName: "dmsMessageOwner", value: @messageOwner, index1: @messageMemoryType, index2: @messageNumber)
        setter.add(oidName: "dmsMessageBeacon", value: @messageBeacon, index1: @messageMemoryType, index2: @messageNumber)
        setter.add(oidName: "dmsMessagePixelService", value: @messagePixelService, index1: @messageMemoryType, index2: @messageNumber)
        setter.add(oidName: "dmsMessageRunTimePriority", value: @messageRunTimePriority, index1: @messageMemoryType, index2: @messageNumber)
        status =  set(setter)
        if :noError == status
          #####
          # set the status to validating
          #####
            setter = SNMPAccess::AccessList.new @oidList
            setter.add(oidName: "dmsMessageStatus", value: ENUM_dmsMessageStatus::VALIDATEREQ, index1: @messageMemoryType, index2: @messageNumber)
            status =  set(setter)
            if :noError ==  status
              #####
              # get the CRC and Status
              #####
              getter = SNMPAccess::AccessList.new @oidList
              getter.add(oidName: "dmsMessageStatus", index1: @messageMemoryType, index2: @messageNumber)
              getter.add(oidName: "dmsMessageCRC", index1: @messageMemoryType, index2: @messageNumber)
              status =  get(getter)
              if :noError ==  status
                @messageCRC = getter["dmsMessageCRC", @messageMemoryType, @messageNumber].value.to_i
                @messageStatus = getter["dmsMessageStatus", @messageMemoryType, @messageNumber].value.to_i
              end
            end
        end
      end
      status
    end
    def activate_message( messageMemoryType: nil, messageNumber: nil, messageCRC: nil, duration: nil, activatePriority: nil, sourceAddress: nil)
      retValues = [:snmpError, ENUM_dmsActivateMsgError::NONE, ENUM_dmsMultiSyntaxError::NONE]
      if nil == messageMemoryType
        messageMemoryType = @messageMemoryType
      end
      if nil == messageNumber
        messageNumber = @messageNumber
      end
      if nil == messageCRC
        messageCRC = @messageCRC
      end
      #####
      # if we still don't have the CRC
      # then get it now
      ######
      if nil == messageCRC
        getter = SNMPAccess::AccessList.new @oidList
        getter.add(oidName: "dmsMessageCRC", index1: messageMemoryType, index2: messageNumber)
        status = get(getter)
        if :noError == status
          messageCRC = getter["dmsMessageCRC", messageMemoryType, messageNumber].value.to_i
        end
        if nil == messageCRC
          retValues[0] = :invalidMessageCRC
          return retValues
        end
      end
      messageActivationCode = MessageActivationCode.new(messageMemoryType: messageMemoryType, messageNumber: messageNumber, messageCRC: messageCRC, duration: duration, activatePriority: activatePriority, sourceAddress: sourceAddress)
puts "activatePriority "+activatePriority.to_s

     setter = SNMPAccess::AccessList.new @oidList
     setter.add(oidName: "dmsActivateMessage", value: messageActivationCode.get_value, index1: messageMemoryType, index2: messageNumber)
      status = set(setter)
puts "status "+status.to_s+"["+messageActivationCode.get_value.length.to_s+"]"
      case status
      when :noError
        #####
        # now, check to see if the message was actually set
        #####
        getter = SNMPAccess::AccessList.new @oidList
        getter.add(oidName: "dmsActivateMsgError", index1: messageMemoryType, index2: messageNumber)
        getter.add(oidName: "dmsMultiSyntaxError", index1: messageMemoryType, index2: messageNumber)
        status =  get(getter)
        if :noError ==  status
          activateMsgError = getter["dmsActivateMsgError", messageMemoryType, messageNumber].value.to_i
          multiSyntaxError = getter["dmsMultiSyntaxError", messageMemoryType, messageNumber].value.to_i
          retValues[0] = :noError
          retValues[1]  = ENUM_dmsActivateMsgError::NONE
          if ENUM_dmsActivateMsgError::NONE != activateMsgError
            retValues[0] = :genError
          end
          retValues[2] = multiSyntaxError
        end
      when :timeOut
         #####
         # Amsig response may have been corrupted
         # so try to verify the activate message
         # by getting the dmsActivateMessageCode
         # and the current dmsMessageMultiString
         # and comparing to what we sent
         #####
         getter = SNMPAccess::AccessList.new @oidList
         getter.add(oidName: "dmsActivateMessage")
         getter.add(oidName: "dmsMessageMultiString", index1: 5, index2: 1)
         getter.add(oidName: "dmsMessageMultiString", index1: messageMemoryType, index2: messageNumber)
         status =  get(getter)
         retValues[0] = :timeOut
         if :noError ==  status
          currentMessageActivationCode = MessageActivationCode.new(octetString: getter["dmsActivateMessage"].get_value)
         
          if messageActivationCode == currentMessageActivationCode
             if getter["dmsMessageMultiString", 5, 1].to_s == getter["dmsMessageMultiString", messageMemoryType, messageNumber].to_s
               retValues[0] = :noError
               retValues[1]  = ENUM_dmsActivateMsgError::NONE
             end
          end
         end
         retValues[0]
     end
        retValues
    end
    def delete_message( messageMemoryType: nil, messageNumber: nil)

      if nil == messageMemoryType
        messageMemoryType = @messageMemoryType
      end
      if nil == messageNumber
        messageNumber = @messageNumber
      end
      #####
      # check type
      #####
      
      case messageMemoryType
      when ENUM_dmsMessageMemoryType::PERMANENT
          return :cantWrite
      when ENUM_dmsMessageMemoryType::CHANGEABLE
        if messageNumber > @maxChangeableMsg
          return :invalidMessageNumber
        end
      when ENUM_dmsMessageMemoryType::VOLATILE
        if @messageNumber > @maxVolatileMsg
          return :invalidMessageNumber
        end
      when ENUM_dmsMessageMemoryType::CURRENTBUFFER
          return :cantWrite
      when ENUM_dmsMessageMemoryType::SCHEDULE
          return :cantWrite
      when ENUM_dmsMessageMemoryType::BLANK
          return :cantWrite
      end
     setter = SNMPAccess::AccessList.new @oidList
     setter.add(oidName: "dmsMessageStatus", value: ENUM_dmsMessageStatus::NOTUSEDREQ, index1: messageMemoryType, index2: messageNumber)
     status =  set(setter)
    end
  end
  ###########################################################3
  class NTCIPSimple < NTCIPAccess
    def initialize(port: 161, community: 'administrator', host: 'localhost')

      super

      @oidList = NTCIPOIDList::TheList.new
    end

    def get_list(variableNameList)
      @getter = SNMPAccess::AccessList.new @oidList
      variableNameList.each { |oid|
        #puts oid.to_s
        @getter.add(oidName: oid.to_s)
      }
      status =  get(@getter)
    end

    def get_single(variableName)
      @getter = SNMPAccess::AccessList.new @oidList
      @getter.add(oidName: variableName)
      status =  get(@getter)
    end

    def set_list(varableNameValueList)
      @setter = SNMPAccess::AccessList.new @oidList
      varableNameValueList.each { |v|
        @setter.add(oidName: v[0], value: v[1])
      }
      status =  set(@setter)
    end

    def set_single(variableName, variableValue)
      @setter = SNMPAccess::AccessList.new @oidList
      @setter.add(oidName: variableName, value: variableValue)
      status =  set(@setter)
    end

    def get_value(index=nil)
      if nil == index
        vals = []
        @getter.each { |v| 
          v2 = [v.oidName, v.get_value]
          vals << v2
        }
        vals
      else
        @getter[index].get_value
      end
    end
  end
  ###########################################################3
end
