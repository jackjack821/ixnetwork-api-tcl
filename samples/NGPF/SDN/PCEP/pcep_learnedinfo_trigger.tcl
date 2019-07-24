################################################################################
#                                                                              #
#    Copyright 1997 - 2019 by IXIA  Keysight                                   #
#    All Rights Reserved.                                                      #
#                                                                              #
################################################################################

################################################################################
#                                                                              #
#                                LEGAL  NOTICE:                                #
#                                ==============                                #
# The following code and documentation (hereinafter "the script") is an        #
# example script for demonstration purposes only.                              #
# The script is not a standard commercial product offered by Ixia and have     #
# been developed and is being provided for use only as indicated herein. The   #
# script [and all modifications enhancements and updates thereto (whether      #
# made by Ixia and/or by the user and/or by a third party)] shall at all times #
# remain the property of Ixia.                                                 #
#                                                                              #
# Ixia does not warrant (i) that the functions contained in the script will    #
# meet the users requirements or (ii) that the script will be without          #
# omissions or error-free.                                                     #
# THE SCRIPT IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND AND IXIA         #
# DISCLAIMS ALL WARRANTIES EXPRESS IMPLIED STATUTORY OR OTHERWISE              #
# INCLUDING BUT NOT LIMITED TO ANY WARRANTY OF MERCHANTABILITY AND FITNESS FOR #
# A PARTICULAR PURPOSE OR OF NON-INFRINGEMENT.                                 #
# THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SCRIPT  IS WITH THE #
# USER.                                                                        #
# IN NO EVENT SHALL IXIA BE LIABLE FOR ANY DAMAGES RESULTING FROM OR ARISING   #
# OUT OF THE USE OF OR THE INABILITY TO USE THE SCRIPT OR ANY PART THEREOF     #
# INCLUDING BUT NOT LIMITED TO ANY LOST PROFITS LOST BUSINESS LOST OR          #
# DAMAGED DATA OR SOFTWARE OR ANY INDIRECT INCIDENTAL PUNITIVE OR              #
# CONSEQUENTIAL DAMAGES EVEN IF IXIA HAS BEEN ADVISED OF THE POSSIBILITY OF    #
# SUCH DAMAGES IN ADVANCE.                                                     #
# Ixia will not be required to provide any software maintenance or support     #
# services of any kind (e.g. any error corrections) in connection with the     #
# script or any part thereof. The user acknowledges that although Ixia may     #
# from time to time and in its sole discretion provide maintenance or support  #
# services for the script any such services are subject to the warranty and    #
# damages limitations set forth herein and will not obligate Ixia to provide   #
# any additional maintenance or support services.                              #
#                                                                              #
################################################################################

################################################################################
# Description: 
# 1. Pre - Established SR LSPs are statically configured in PCC, 
#	 with initial delegation TRUE. When PCC starts, it synchronizes 
#	 these LSPs with PCE.
# 2. Assign ports
# 3. Start all protocols
# 4. Retrieve protocol statistics.  (PCE Sessions Per Port)
# 5. Retrieve protocol statistics. (PCC Per Port)
# 6. Fetch Pre - Established SR LSPs learned Info in PCE side.
# 7. Change LSP & Symbolic Path Name Value in PCE Learned Info 
#    over Pre - Established SR LSPs.
# 8. Send PCUpdate from Learned Info from PCE side.
# 9. Stop all protocols
################################################################################

puts "Load ixNetwork Tcl API package"
package req IxTclNetwork
# Edit this variables values to match your setup
namespace eval ::ixia {
    set ports       {{10.39.50.227 1 5} {10.39.50.227 1 6}}
    set ixTclServer 10.39.50.102
    set ixTclPort   8785
}

################################################################################
# Connect to IxNet client
################################################################################
ixNet connect $ixia::ixTclServer -port  $ixia::ixTclPort -version "8.50"

################################################################################
# Cleaning up IxNetwork
################################################################################
puts "Cleaning up IxNetwork..."
ixNet execute newConfig
puts "Get IxNetwork root object"
set root [ixNet getRoot]
################################################################################
# Adding virtual ports
################################################################################
puts "Adding virtual port 1"
set vport1 [ixNet add $root vport]
ixNet commit
set vport1 [lindex [ixNet remapIds $vport1] 0]
ixNet setAttribute $vport1 -name "10GE LAN - 001"
ixNet commit
puts "Adding virtual port 2"
set vport2 [ixNet add $root vport]
ixNet commit
set vport2 [lindex [ixNet remapIds $vport2] 0]
ixNet setAttribute $vport2 -name "10GE LAN - 002"
ixNet commit
################################################################################
# Adding topology
################################################################################
puts "Adding topology 1"
set topology1 [ixNet add $root "topology"]
ixNet commit
set topology1 [lindex [ixNet remapIds $topology1] 0]
ixNet setAttribute $topology1 -name "Topology 1"
ixNet setAttribute $topology1 -vports $vport1
ixNet commit
################################################################################
# Adding device group
################################################################################
puts "Adding device group 1"
set device1 [ixNet add $topology1 "deviceGroup"]
ixNet commit
set device1 [lindex [ixNet remapIds $device1] 0]
ixNet setAttribute $device1 -name "Device Group 1"
ixNet setAttribute $device1 -multiplier "1"
ixNet commit
################################################################################
# Adding ethernet layer
################################################################################
puts "Adding ethernet 1"
set ethernet1 [ixNet add $device1 "ethernet"]
ixNet commit
set ethernet1 [lindex [ixNet remapIds $ethernet1] 0]
set macMv [ixNet getAttribute $ethernet1 -mac]
ixNet add $macMv "counter"
ixNet setMultiAttribute $macMv/counter\
             -direction "increment"\
             -start     "00:11:01:00:00:01"\
             -step      "00:00:00:00:00:01"

ixNet commit
################################################################################
# Adding IPv4 layer
################################################################################
puts "Adding ipv4 1"
set ipv4Addr1  [ixNet add $ethernet1 "ipv4"]
ixNet commit
set ipv4Addr1 [lindex [ixNet remapIds $ipv4Addr1] 0]
set addressMv [ixNet getAttribute $ipv4Addr1 -address]
ixNet add $addressMv "singleValue"
ixNet setMultiAttribute $addressMv/singleValue\
            -value "1.1.1.1"
set gatewayIpMv [ixNet getAttribute $ipv4Addr1 -gatewayIp]
ixNet add $gatewayIpMv "singleValue"
ixNet setMultiAttribute $gatewayIpMv/singleValue\
            -value "1.1.1.2"
################################################################################
# Adding PCE layer
################################################################################
puts "Adding PCE 1"
set pce1 [ixNet add $ipv4Addr1 "pce"]
ixNet commit
set pce1  [lindex [ixNet remapIds $pce1] 0]
################################################################################
# Adding PCC Group
# Configured parameters :
#    -pccIpv4Address
#    -multiplier
#    -pceInitiatedLspsPerPcc
#    -pcReplyLspsPerPcc
################################################################################
puts "Adding PCC Group1"
set pccGroup1 [ixNet add $pce1 "pccGroup"]
ixNet commit
set pccGroup1 [lindex [ixNet remapIds $pccGroup1] 0]
set pccIpv4AddressMv [ixNet getAttribute $pccGroup1 -pccIpv4Address]
ixNet add $pccIpv4AddressMv "counter"
ixNet setMultiAttribute $pccIpv4AddressMv/counter\
             -direction "increment"\
             -start     "1.1.1.2"\
             -step      "0.0.0.1"

ixNet commit
ixNet setAttribute $pccGroup1 -multiplier "10"
ixNet commit
ixNet setAttribute $pccGroup1 -pceInitiatedLspsPerPcc "0"
ixNet commit
ixNet setAttribute $pccGroup1 -pcReplyLspsPerPcc "0"
ixNet commit

################################################################################
# Adding topology
################################################################################
puts "Adding topology 2"
set topology2 [ixNet add $root "topology"]
ixNet commit
set topology2 [lindex [ixNet remapIds $topology2] 0]
ixNet setAttribute $topology2 -name "Topology 2"
ixNet setAttribute $topology2 -vports $vport2
ixNet commit
################################################################################
# Adding device group
################################################################################
puts "Adding device group 2"
set device2 [ixNet add $topology2 "deviceGroup"]
ixNet commit
set device2 [lindex [ixNet remapIds $device2] 0]
ixNet setAttribute $device2 -name "Device Group 2"
ixNet setAttribute $device2 -multiplier "10"
ixNet commit
################################################################################
# Adding ethernet layer
################################################################################
puts "Adding ethernet 2"
set ethernet2 [ixNet add $device2 "ethernet"]
ixNet commit
set ethernet2 [lindex [ixNet remapIds $ethernet2] 0]
set macMv [ixNet getAttribute $ethernet2 -mac]
ixNet add $macMv "counter"
ixNet setMultiAttribute $macMv/counter\
             -direction "increment"\
             -start     "00:12:01:00:00:01"\
             -step      "00:00:00:00:00:01"

ixNet commit
################################################################################
# Adding IPv4 layer
################################################################################
puts "Adding ipv4 2"
set ipv4Addr2  [ixNet add $ethernet2 "ipv4"]
ixNet commit
set ipv4Addr2 [lindex [ixNet remapIds $ipv4Addr2] 0]
set addressMv [ixNet getAttribute $ipv4Addr2 -address]
ixNet add $addressMv "counter"
ixNet setMultiAttribute $addressMv/counter\
             -direction "increment"\
             -start     "1.1.1.2"\
             -step      "0.0.0.1"

set gatewayIpMv [ixNet getAttribute $ipv4Addr2 -gatewayIp]
ixNet add $gatewayIpMv "singleValue"
ixNet setMultiAttribute $gatewayIpMv/singleValue\
            -value "1.1.1.1"
################################################################################
# Adding PCC layer
# Configured parameters :
#    -pceIpv4Address
#    -expectedInitiatedLspsForTraffic
#    -preEstablishedSrLspsPerPcc
#    -requestedLspsPerPcc
################################################################################
puts "Adding PCC 2"
set pcc2 [ixNet add $ipv4Addr2 "pcc"]
ixNet commit
set pcc2 [lindex [ixNet remapIds $pcc2] 0]
set pceIpv4AddressMv [ixNet getAttribute $pcc2 -pceIpv4Address]
ixNet add $pceIpv4AddressMv "singleValue"
ixNet setMultiAttribute $pceIpv4AddressMv/singleValue\
            -value "1.1.1.1"
ixNet commit
ixNet setAttribute $pcc2 -expectedInitiatedLspsForTraffic "0"
ixNet commit
ixNet setAttribute $pcc2 -preEstablishedSrLspsPerPcc "1"
ixNet commit
ixNet setAttribute $pcc2 -requestedLspsPerPcc "0"
ixNet commit

################################################################################
# Adding Pre-Established SR LSPs
# Configured parameters :
#    -initialDelegation
#    -includeBandwidth
#	 -includeLspa
#    -includeMetric
################################################################################
set preEstablishedSRLsps $pcc2/preEstablishedSrLsps:1
set initialDelegation [ixNet getAttribute $preEstablishedSRLsps -initialDelegation]
ixNet add $initialDelegation "singleValue"
ixNet setMultiAttribute $initialDelegation/singleValue\
            -value "true"
ixNet commit

set includeBandwidth [ixNet getAttribute $preEstablishedSRLsps -includeBandwidth]
ixNet add $includeBandwidth "singleValue"
ixNet setMultiAttribute $includeBandwidth/singleValue\
            -value "true"
ixNet commit

set includeLspa [ixNet getAttribute $preEstablishedSRLsps -includeLspa]
ixNet add $includeLspa "singleValue"
ixNet setMultiAttribute $includeLspa/singleValue\
            -value "true"
ixNet commit

set includeMetricMv [ixNet getAttribute $preEstablishedSRLsps -includeMetric]
ixNet add $includeMetricMv "singleValue"
ixNet setMultiAttribute $includeMetricMv/singleValue\
            -value "true"
ixNet commit

################################################################################
# 2. Assign ports
################################################################################
puts "Assigning the ports"
set vPorts [ixNet getList $root "vport"]
::ixTclNet::AssignPorts $ixia::ports {} $vPorts force

puts "Starting all protocols"
################################################################################
# 3. Start all protocols
################################################################################
ixNet execute "startAllProtocols"
puts "Wait for 1 minute"
after 60000

puts "Checking statistics"
################################################################################
# 4. Retrieve protocol statistics.  (PCE Sessions Per Port)                    #
################################################################################
puts "Fetching all PCE Sessions Per Port Stats\n"
set viewPage {::ixNet::OBJ-/statistics/view:"PCE Sessions Per Port"/page}
set statcap [ixNet getAttr $viewPage -columnCaptions]
foreach statValList [ixNet getAttr $viewPage -rowValues] {
    foreach statVal $statValList  {
        puts "***************************************************"
        set index 0
        foreach satIndv $statVal {
            puts [format "%*s:%*s" -40 [lindex $statcap $index]\
                -10 $satIndv]
            incr index
        }
    }
}
puts "***************************************************"

################################################################################
# 5. Retrieve protocol statistics. (PCC Per Port)                              #
################################################################################
puts "Fetching all PCC Per Port Stats\n"
set viewPage {::ixNet::OBJ-/statistics/view:"PCC Per Port"/page}
set statcap [ixNet getAttr $viewPage -columnCaptions]
foreach statValList [ixNet getAttr $viewPage -rowValues] {
    foreach statVal $statValList  {
        puts "***************************************************"
        set index 0
        foreach satIndv $statVal {
            puts [format "%*s:%*s" -40 [lindex $statcap $index]\
                -10 $satIndv]
            incr index
        }
    }
}
puts "***************************************************"

################################################################################
# 6. Fetch Pre - Established SR LSPs learned Info in PCE side.				   #
################################################################################
puts "Fetch Pre - Established SR LSPs learned Info in PCE side."
ixNet exec getPceBasicSrPccSyncLspLearnedInfo $pccGroup1 1
after 2000
#---------------------------------------------------------------------------
# Setting the TCL APIs for getting PCUpdate Triggers
#---------------------------------------------------------------------------  
set learnedInfoUpdate1 [lindex [ixNet getList $pccGroup1 learnedInfoUpdate] 0]

set trigger1 [ixNet getList $learnedInfoUpdate1 pceBasicSrSyncLspUpdateParams]

###############################################################################################
# 7. Change LSP & Symbolic Path Name Value in PCE Learned Info over Pre - Established SR LSPs.#
###############################################################################################
puts "Setting LSP Option for Emulated PCC....\n"
set lsp [ixNet getA $trigger1 -configureLsp]
ixNet setA $lsp/singleValue -value "modify"
ixNet commit
after 2000

puts "Setting Symbolic Path Name TLV for Emulated PCC....\n"
set spnTLV [ixNet getA $trigger1 -includeSymbolicPathName]
ixNet setA $spnTLV/singleValue -value "true"
ixNet commit
after 2000

################################################################################
# 7. Send PCUpdate from Learned Info from PCE side.                            #
################################################################################
puts "Send PCUpdate from Learned Info from PCE side"
ixNet exec sendPcUpdate $trigger1 {1}
after 5000

################################################################################
# 8. Stop all protocols                                                        #
################################################################################
ixNet exec stopAllProtocols
puts "!!! Test Script Ends !!!"