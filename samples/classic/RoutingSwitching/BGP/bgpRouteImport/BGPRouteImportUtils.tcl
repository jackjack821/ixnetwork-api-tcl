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

proc bgpImportFunctionality {importRouteOptions fileName {changeList ""}} {
   
    set isError 0
    set FAILED 1
   
    if {$changeList == 1} {
        ixNet setAttr $importRouteOptions -routeFileType "Ixia Format"
        log "IXIA Format importing"
     }

     if {$changeList == 2} {
        ixNet setAttr $importRouteOptions -routeFileType "Cisco IOS"
        log "CISCO Format importing"
     }

     if {$changeList == 3} {
        ixNet setAttr $importRouteOptions -routeFileType "Juniper JUNOS"
        log "JUNIPER Format importing"
     }
     ixNet commit
   
     if {[ixNet exec importOpaqueRouteRangeFromFile $importRouteOptions \
         [ixNet readFrom $fileName]] != "::ixNet::OK"} {
         log "FAILURE : Could not import file to neighbor"
         return $FAILED
     } else {
         puts "SUCCESS : Successfully imported file to neighbor"
     }
   
    set isError 0
    return $isError
}
 

proc learnedInfoFetchForRouteImport {bgpNeighbor expectedList} {
    set noMatch 1
    ixNet exec refreshLearnedInfo $bgpNeighbor
    after 5000

    set db {asPath                 \
            multiExitDiscriminator \
            neighbor               \
            ipPrefix}
       
    set learnedInformationList    [ixNet getList $bgpNeighbor learnedInformation]
    set BGPlearnedInformationList [ixNet getList $learnedInformationList ipv4Unicast]
    
    set matchList {}
    foreach BGPInfo $BGPlearnedInformationList  {
        set temp {}
        foreach attr $db {
            set attrVal [ixNet getAttr $BGPInfo -$attr]
            lappend temp $attrVal
        }
        lappend matchList $temp
    }

    puts "$matchList" 
    foreach expectedRoute $expectedList {
        set matchIndex [lsearch $matchList $expectedRoute]
        log "<Expected> : $expectedRoute"
        log "<received> : [lindex $matchList $matchIndex]"
        if {$matchIndex < 0} {
            puts "###############################################################################"
            return 0
        }
    }

   return 1 
}
