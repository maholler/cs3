#!/usr/bin/perl -w
#
# Copyright (C) 2012, 2013 Mark Holler All rights reserved
#
# snetbase.pl is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# see <http://www.gnu.org/licenses/>. http://www.gnu.org/licenses/gpl.html

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 2. All advertising materials mentioning features or use of this software
#    must display the following acknowledgement:
#      This product includes software developed by Camalie Networks.
# 3. The name of the author may not be used to endorse or promote products
#     derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
# EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# $Id: snetbase.pl 1570 2013 12:15:15:15 holler $
#
# Home Page -- http://camalienetworks.com

#  This program, snetbase.pl, (sensor-network-base station) receives data from XBee remote nodes
#  and pushes it to cloud server(s). It also receives commands from cloud servers such as actuation, 
#  configuration and query commands and passes them on to XBee nodes. It provides a gateway 
#  between an XBee Digimesh network and the internet. This code is compatible with a CS3 shareware
#  cloud server and can be run on the same linux platform as the server to form a stand alone 
#  offline monitoring/control system. Perhaps useful for maximum security applications.    

#History:
# Incoming data captured using the Eagle XBee::API perl module. M.H. 11/30/12
# Porting to second machine Zbox5 and cleaning up.  M.H. 12/3/12
# Combining actuation and data reading into one loop.   M.H. 12/4/12 
# Modifying to receive actuation command back from remote server and actuate accordingly M.H. 1/12/13
# Added sqlite DB to store network + node information; sqlite manager able to view tables M.H.  1/14/13
# Added Network Discovery M.H. 1/19/13 
# Worked for a while then stopped being able to get network ID or do Network Discovery. 1/23/13 M.H. 
# Going back to simpler form and shorter sleep cycle to see if I can get that stuff working again.  
# Do Network disovery and put results into the nodes table.  Done M.H. 1/27/13
# Set up sqlite tables on remote host to store same data as on CS3 gateway + some user input. 
# Pass node and network data to the remote server in http requests.
# Develop U.I. on remote server to show Network/Node status and accept commands. 
# Query the remote server for commands such as actuate node-pin and execute 2/7/13 M.H. 
# integrate drraw graphing with the remote server U.I.  
# Enable network map graphic upload
# Execute commands received from the remote server, from some web client. 
# Creating Subroutines to read and write base and remote nodes 2/19/13 M.H.
# Changing loop timing to sync with Sleep cycles using Modem status packets 3/2/13 M.H.   
# Added Ugly hack to keep 2.4gHz nodes synchronized 3/3/13 M.H. Didn't work long.
# Removed Ugly hack 4/22/13 M.H. 
# Added variable length multi variable data transmission via port 80. 4/22/13 M.H. 
# Put data packet processing into a function.  4/22/13 M.H. 
# Added a watch program and a start up program to get code to start immediately.  
# Added type 0x10H (type 144) TX packet from arduino stalker reception. 6/17/13 M.H. 
#  Enables water meter or other more complex sensor data capture that requires 
#  microcontroller in the remote node.  
# Added pin state as well as count to be able to monitor door/window states with reed switches. M.H. 6/26/13
# Sending pin number as port number with data.  Arduino or XBee pin number work as long as sensor type unique. 
# Started on Actuation, Major code restructuring, Network Discovery function  6/28/13 M.H. 
# Cleaned up Sleep and Wake Loop timing and housekeeping. 
# Functionalized remote_AT command.  7/14/13 M.H. Actuation from web working.     
# Add actuation receipt and response/acknowledgment packets from snetbase, Store to Server sqliteDB
# Got Actuation Loop Working. 7/30/13 M.H.  Introduced hardware reset button on base radio pin 5. 
# Debugging intermittent base radio responses after snetbase.pl restart.  8/11/13
# Base radio hang issue went away. Cause unknown.  It will be back.  
# Deployed code to pcD0 8 node net, works M.H. 8/11/13
# Added Query command and value return.  8/12/13 M.H.
# Moved net pcD0 to AP=2 using the control interface and over air programming 8/20/13 M.H. worked 11 nodes. 
# Added GPS node coordinates reception, packet type 144-2. M.H. 10/31/13 
# Added push to second web site. 11/5/13 M.H. Push to Multiple Websites/scripts  11/15/13 M.H. 
# Built cs3 gateway + cs3 cloud server on same platform, CubieTruck 11/22/13 M.H. 
# Reduced Debug text verbosity.  11/29/13 M.H. 
# Added push of base radio node information after a network discovery  11/29/13  M.H. 
# Added web configuration of base radio modem to the system, snetbase.pl + snetServe3.cgi 11/29/13 M.H.
# Demonstrated commissioning of new nodes using only the /camalie.net/cs3/cs3control.cgi web Interface. 12/3/13 M.H.
# Added association of at_frame_ids with command times for delayed command confirmation when responses delayed. 
# Fixed various bugs in Command execution loop 12/14/13 M.H. Enabled programming and read of NI strings. 
# Added Commissioning page to web cs3Commission.cgi, just has instructions added. 12/15/13 
# Fixed Bug, hang on base SP set due to $netID getting set to null in writeXBbase()  12/15/13 M.H.
# Added Terraduino packet parser to process144packet function. 12/20/13 M.H. 
# Added sendToArduino() to send a packet to an arduino processor on a remote nodes 12/22/13 M.H.    
# Tx_Request to remote node with payload for arduino to interpret and act on. see WGXXAcom sketch for reception.
# Added parsing of Alan's Terraduino Data Packets  1/12/14 M.H.
# Added XBee Reset using connection from pcD7 to XBee reset pin5  1/14/14 M.H. 
# Added Serial port ttyS1 pin mode initialization, replacement for setuart2 hack   1/14/14  M.H.
# Bug fixed; infinite wake cycle loop, Output stream reduced/cleaned up  1/14/13
# Bug fixed; error finding first portName due to variable length packetNum  1/27/13 M.H. 
# Added parser for Terraduino port I1 internal data packetNum and added it and sampleTime to push 1/27/14 M.H.
# Assigned Terraduino port I1 (internal data) a sensorType of 201 1/28/14 
# Added function to substitute http Get compatible delimiters for Alan's delimiters in sensor config packets.
# Added pass up of sensor configuration data to cloud.  1/28/14 M.H.
# Modified the main loop to handle absense of 138 packets better, added reset on no 138s for 25 cycles. 3/6/14 M.H.
# Added push to all 4 servers.  Reduced printing especially for each server if no commands received. 3/9/14 M.H.
# Modified serial timeout to be 22% of the sleep time rather than an explict value.  3/9/14 M.H. 
# Modified type 144-48 packet; added &atTime parameter with Gateway Unix Time, was in node payload 4/21/14 M.H.
# Commented out network_discover() call which has been crashing snetbase with an illegal characters '-' seen 5/21/14 M.H. 
#  known_nodes() call does all the work and doesn't block.  It just monitors packets coming in to build list. 
# Working on threads.  Need to add a Queue.  PERL threads have a major memory leak can't continually create and destroy them. M.H. 6/2/14 
# First version with Queues working but, still has a memory leak!  PERL threads are not good. M.H. 6/3/14 
# Added wait for packet from field before setting sleep time in field, code from pcD4  10/02/14 M.H. 
# Added gateway status packet send from pcD4 10/2/14 M.H. Must install vnstat
# Changed status packet sensor type from x4 to 208 to fix server type issue with non numeric value 10/2/14 M.H.
# moved touch of pushed out of threads into end of doCommands.  
# Assign value 0 if $netBWavg is x to eliminate errors storing data on servers  10/10/14 M.H. 
# Moved sendStatus to end of wake cycle to reduce packet sends.  10/111/14 M.H. Turned off Network Discover.
# added -b to top call for batch mode, text only output. This eliminates odd full screen update mode of top
# Increased Baud rate of Gateway to Base radio communication from 9600 to 115200 for less back up in serial 10/15/14 M.H. 
# Per Alan's standard.  

#Next Steps: 
#  1. Forward Terraduino config packets to cloud as pktType sConfig, one big string or not. 
#  2. Parse Terraduino/arduino config packets, store keys in hash and forward to cloud. or not
#    2b.  Use the hash to add sensorType and parameter names to arduino data packets sent up. or not 
#  6. Send a ACK packets back to gateway and web indicating action was taken successfully.    

# Extract a list of configuration parameters from a selected node either from command DB or by slow query one by one. 
# Check for valid parameters and values before executing commands.  Do in cs3control.cgi (seat belts)
# Add commissioning web page Step 1: Select CS3 net of interest, nodes in factory default config discovered, List Displayed
#                            Step 2: Select Node(s) to commission, Enter Node Name(s) if desired, Submit
#                            Step 3: Use Command/Control page to fine tune the configuration. send WR to save config to NVM
# add delayed processing of type 136 packets, responses to base radio AT commands. like 151 processsing. Don't seem to need. 
# Generate or use Network ID from the base radio serial number to have a unique NetID and to eliminate editing
#    a unique netID into this code on each gateway and to prevent users from assigning their own netIDs which could conflict. 
# Add camera image input
# Add field node .wav file play
# Build a gateway that uses GPRS cellular shield to communicate with the cloud.   
# Put the value of an XBee configuration parameter in the command table in a column called Read  
#   Also Store it in a table of parameter values read from that node and the times they were read. 
# Create a node config display showing the most recent values of the parameters read from a specified node.  
# Add actuation status sensor like packets to monitor state. Allows plotting of actuation state.
  #Goal is to be able to see when an actuator is activated and when actuation completes. 
  #This is needed only if arduino manages actuation timeout.
  #Alternatively can query actuation state by sending actuation command with no value. Value will be in response packet. 
# Create Actuation U.I. like eKo View with available actuators, status, actuation buttons, time
# Add actuation queues management to Gateway/Server. Have snetServe3 update table.   
# Store data during a remote server link failure and forward data when the link recovers. 
# Add a timeout if a remote cloud server doesn't respond. 
# Make a function that unpacks a byte or two bytes with all different PERL unpack options to accelerate unpack hacking. 

# Bug Fixes Needed:

# Initial SP sleep time setting not taking effect with nodes in field. Sets O.K. from command prompt?
# Not getting a success response to IR commands
# atTime not getting sent or stored to cloud from arduino nodes.  
# Need to use XBee packet receive time on gateway rather than Server receive time of Gateway push. 

#Notes:
# Requires installation of libdbi-perl and libdbd-sqlite3-perl for data base functions to work, use synaptic
# Requires installation of Device::XBee::API from CPAN for communication with XBee nodes in API mode. use cpanm to install
# Must also install XBeeReset and ttyS1init executables in /cs3code
# Must install vnstat network monitor for gateway monitoring

# XBee configuration notes. *****************************
#     SO bit 2 = 1 In order to get type 138 modem sleep status packets from the base radio.
# Nodes with shorter sampling times than the sleep cycle send only one data packet each wake cycle 

# Sparkfun XBee base radio breakout board connections to Gateway pcDuino:
#  Solder the following 4 wires 6" long between the two. This eliminates need for USB->Serial converter like UartsBee
#  Dout     -> pcDuino pD0=Rx
#  Din      -> pcDuino pD1=Tx
#  Reset(5) -> pcDuino pD7
#  5V       -> pcDuino 5V
#  GND      -> pcDuino GND

 use Device::SerialPort;
 use Device::XBee::API;
 use Data::Dumper;
 use LWP::Simple;
 use DBI;
 use threads ('stack_size' => 64*4096,'yield', 'exit' => 'threads_only','stringify');
 use threads::shared;
 use Thread::Queue;
 
 #use strict;

$Data::Dumper::Useqq = 1;

my $networkType = "Camalie Networks CS3 Network "; # this will end up getting set from remote.
my $codeRevision = "snetbase.pl for pcD11_10/11/14 Hestia w/wait&status M.H.";
   # The servers this program will push data to and receive commands from.  
#my @cloudServers = ("http://camalie.net/cs3/snetServe3.cgi", "http://yo-z-o.com/snetServe3.cgi", "http://camalienetworks.net/cs3/snetServe3.cgi", "http://cogitat.es:8090/cs3/snetServe3.cgi");
my @cloudServers = ("http://camalie.net/cs3/snetServe3.cgi", "http://yo-z-o.com/snetServe3.cgi", "http://camalienetworks.net/cs3/snetServe3.cgi");
#my @cloudServers = ("http://camalie.net/cs3/snetServe3.cgi", "http://yo-z-o.com/snetServe3.cgi", "http://camalienetworks.net/cs3/snetServe3.cgi", "http://107.21.101.71/cs3"); # with Aji's new non Amazon server
#my @cloudServers = (); # No push during development to avoid sending trash to servers 
#my @cloudServers = ("http://camalie.net/cs3/snetServe3.cgi"); # Single push for less verbosity during Dev. 
#my @cloudServers = ("http://99.115.132.117/cs3/snetServe3.cgi"); # unresponsive URL for test purposes.
#my @cloudServers = ("http://camalie.net/cs3/snetServe3.cgi", "http://yo-z-o.com/snetServe3.cgi");# Two best Camalie Servers
#my @cloudServers = ("http://camalie.net/cs3/snetServe3.cgi", "http://yo-z-o.com/snetServe3.cgi", "http://cogitat.es/cs3/snetServe3.cgi");# all but camalienetworks.net
   # The remote server must be set up with RRDTools and have a snetServeX.cgi script installed.
   # It must also have sqlite installed and PERL modules DBI and DBD-sqlite installed. 
   # The User interface is a PERL script called CS3Viewxxx.cgi 
   # snetServeX.cgi is a CGI script that Apache runs when it is invoked via a port 80 request from this program.
my $touchFile="/home/ubuntu/cs3code/pushed";
my $serialPortName = '/dev/ttyS1';

my $netID = 0x7FFF; # This is the Digi default ID for networks. The netID of the specific gateway 
                    # this code is running on is extracted shortly from the base radio with an NI query 
my $destH = 0x0013A200; # High 32 bits of all XBee Radio Modules' Serial number

   # Initial default configuration parameters for the base radio module
my $sleepTime =12000;   # SP = Sleep Time in 10s of milliseconds.  100 = 1 second
                         # SO = Sleep Options   SM = sleep Mode  See XBee specs. for details   
my %baseConfig = (SO => 5, SP=>$sleepTime, SM=> 7);
my $serialPortTimeout = $sleepTime*.00225; #Serial port timeout in seconds if no response
my $maxWakeLoops = 200; # wake loops without 138 packets before resetting base radio hangs on reset. 
my $nodeDiscoverInterval = 3600; # Time between Network Discoveries sec.
my $firstNDDelay= 3000; # Delay before first Network Discover sec.

# Maximum working threads ****************
my $MAX_THREADS = 40;

my $nodeCount = 0; 
my %pktID = (   # This hash stores the elements which identify a specific data source
       'net', $netID, # Three Letter Acronym for the network
       'node', "",
       'port', "", 
       'sensorType', "",
       'RRDname', "" );    #fully path qualified file name of the RRD 
my %frameIDcmdTime; # This is a hash of frame_id=>cmdTime  pairs used to match responses to commands.
                    # The keys used are at_frame_id values, the hash values are command times
my $adcsPort=0;
   # This is a wasteful way of enumerating sensor types but is adequate 
my $adcsSensorType=200; # sends an0-an3 values on XBee Analog input pins 20-17
my $terraduinoInternalsType=201; # Terraduino internal data Vbatt, Vsolar, Vext 
my $countSensorType=202;  #with count pin state included,  type 201 is now deprecated
my $GPSsensorType=203;  #sends latitude and longitude FP numbers as strings
my $testType=204;       #temp test type used initially for Terraduino watermark + thermistor testing.
#  $unknownSensorType=205;   used temporarily as unknown SensorType can delete all RRDs of this type 
#my $unknownSensorType=206; # initially the sensor type may be unknown but, data is still useful.  
my $unknownSensorType=207; # advanced again as parser changed 1/28/14
my $gtwSensorType=208;  # sensor type given to data packet from the gateway.
my $baseSLval = "";
my $baseNIval = "";

#********************* SETUP ******************************************************************************************

print "$networkType \n";
print "$codeRevision \n";

#************** Get the local IP address of this CS3 gateway **************************************
#  
system("ip addr show eth0 > localIPaddr"); # This gets a paragraph with the local IP address in it 
open LOCALIPADDR, localIPaddr ;
read LOCALIPADDR, my $localIPaddrStr, 300;       
#print "\n\nMy Local IP string = $localIPaddrStr\n";
my $ipAddrPos = index $localIPaddrStr, "inet ";
my $localIPaddr = substr $localIPaddrStr, ($ipAddrPos+5),15;
my $slashPos = index $localIPaddr, "/";
$localIPaddr = substr $localIPaddr, 0, $slashPos;
print "\nThe Local IP address of this CS3 gateway is $localIPaddr\n\n";

#************** Open or Create sqlite Database ************************************************

my $dbh = DBI->connect('DBI:SQLite:/home/ubuntu/sqliteDBs/CS3.sqlite')
            or print "Couldn't connect to database: ". DBI->errstr."\n";

#************** Create Tables if they don't already exist  ************************************

if (! tableExists($dbh,"nodes")) {
   $sth = $dbh->prepare('CREATE TABLE nodes(snl INTEGER, nodeID TEXT, location TEXT, lastheard TEXT)')
            or print "Couldn't prepare nodes table creation statement: " .$dbh->errstr."\n";
   $sth->execute()
            or print "Couldn't execute create nodes table " . $sth->errstr."\n";
}
if (! tableExists($dbh,"network")) {
   $sth2 = $dbh->prepare('CREATE TABLE network(networkID INTEGER, networkName TEXT, lastUpdated TEXT)')
            or print "Couldn't prepare network table creation statement: " .$dbh->errstr."\n";
   $sth2->execute()
            or print "Couldn't execute create network table " . $sth2->errstr."\n";
}
if (! tableExists($dbh,"data")) {
   $sth3 = $dbh->prepare('CREATE TABLE data(node_snl INTEGER, time TEXT, parameterName TEXT, value REAL)')
            or print "Couldn't prepare data table creation statement: " .$dbh->errstr."\n";
   $sth3->execute()
            or print "Couldn't execute create data table " . $sth3->errstr."\n";
}
print "\n";

#********* Set arduino like pins, Xmit and Receive on pcDuino to uart pins  ****************
  system("./ttyS1init");  # Put pcDuino pins 0,1 into serial port mode, replaces setuart2
  select(undef,undef,undef, 2); # delay to let serial port change mode, probably not needed
  system("./XBeeReset");  # Apply half second reset pulse to XBee base radio module 
  select(undef,undef,undef, 5); #  delay to let XBee reset

#********* Configure the serial port *******************************************************
 my $serial_port_device = Device::SerialPort->new( $serialPortName )  || die $!;
 $serial_port_device->baudrate( 115200 );
 $serial_port_device->databits( 8 );
 $serial_port_device->stopbits( 1 );
 $serial_port_device->parity( 'none' );
 $serial_port_device->read_char_time( 0 );  # don't wait for each character
 $serial_port_device->read_const_time( 1000 ); # 1 second per unfulfilled "read" call
 if ($serial_port_device->write_settings()) { print "Wrote serial port settings successfully\n";} 

#*********  Create the Idle Threads Queue and one Queue per thread  *********************************** 
# Threads add their ID to the IDLE_QUEUE when they are ready for work
my $IDLE_QUEUE = Thread::Queue->new();
# Thread work queues referenced by thread ID
my %work_queues;
# Create the thread pool
for (1..$MAX_THREADS) {
    # Create a work queue for a thread
    my $work_q = Thread::Queue->new();
    # Create the thread, and give it the work queue
    my $thr = threads->create('worker', $work_q);
    # Remember the thread's work queue
    $work_queues{$thr->tid()} = $work_q;
    } # end creation of worker threads

#********  Create the XBee::API object ***************************************************
my $api = Device::XBee::API->new( { fh => $serial_port_device,packet_timeout => $serialPortTimeout, api_mode_escape => 1 } )
# pass an anonymous hash to the constructor with just the element keyed by fh set to a value. 
     || print $!;
#********* Read base modem Sleep Time value ****************************
if (my $baseSPval = getXBbaseParam('SP')) {
   print "Base Radio Modem Sleep Time(SP) value initially = $baseSPval x 10ms\n";
}# should add transmit of the data above to the remote server base node entry

#This wait for incoming packet is required or XBee radios in field won't accept new sleep time.  Works
# commented out below temporarily to speed up boot during debugging
while(!($rxM = $api->rx())) { # make sure that a packet has been received.
   print "Reading and waiting for packet to come in before setting sleep time.\n";
}    
print "Got packet from field\n";   
$rxM = ''; # clear the packet hash, ignore this packet.
#  select(undef,undef,undef, 1.5*$sleepTime/100); # alternative brute force delay to let a packet come in. 
  #This is required or XBee radios in field won't accept new sleep time.  Works

#********* Write base modem Sleep Time *********************************
if (my $baseSPwrite = writeXBbaseParam('SP',$baseConfig{'SP'})) {
   #print "Base Radio Modem Sleep Time(SP) value written to value = $baseSPwrite x10ms \n";
}
#********* Read base modem Sleep Time value after Write ****************
if (my $baseSPval = getXBbaseParam('SP')) {
   print "Base Radio Modem Sleep Time(SP) value read after write = $baseSPval x10ms\n";
   print "Gateway serial timeout time = $serialPortTimeout  seconds.\n";
}
#********* Read base modem API mode value ****************
#if (my $baseAPval = getXBbaseParam('AP')) {
#   print "Base Radio Modem API mode (AP) value =$baseAPval \n";
#}
#********* Read base modem Low 32 bits of serial number, SL ****************
if ($baseSLval = getXBbaseParam('SL')) {
   print "Base Radio Modem Serial Number Low 32 bits (SL) value =$baseSLval \n";
}
#********* Read base radio name, NI  ****************
if ($baseNIval = getXBbaseParam('NI')) {
   print "Base Radio Modem Name, NI value =$baseNIval \n";
}else{
   print "No Base Radio Name returned\n";
   $baseNIval = "";
}
#********* Read XBee NetworkID from the Base Radio Modem **************************
# Note: Network ID can alternatively be set manually above, used to label packets sent to camnets
getNetworkID();   

#***************************** Main Loop Architecture *****************************************
   #  **** Sleep Loop
   #    Start by assuming network is asleep and wait for packet indicating it has awakened.
   #    While waiting check camnets for a command from the Web Client, if so execute
   #    While waiting check if its time to do another Network Discovery and initiate if yes. 
   #    If the next packet is a data packet(146), process the data packet, note network is awake 
   #    If the next packet is a modem status packet(138-status 11), note the network is awake
   #  **** Wake Loop
   #    Loop reading packets and acting on them while network is awake, .  
   #    Read Packets and Process them until a packet(138-status 12) comes in indicating network asleep
#*****************************************************************************************

my $lastNetworkDiscoveryTime = time - $nodeDiscoverInterval + $firstNDDelay;
my $networkIsAwake = "";  #assume the network is asleep initially.
my $actuationValue = 4; #4=Low   #5=HIGH
my $sleepCycleIndex = 0;
my $rxM = ''; # Needs to be global.

#**************** MAIN LOOP STARTS HERE *******************************************************
while(1) {
#****************** NETWORK ASLEEP ***********************************************

   my $sleepLoopIndex = 0; # Indicates how many times this while() executes while the net is asleep.
                           # This loop iterates once every $serialPortTimeout  
   my $packetType;
   my $packetStatus="";
   while (!$networkIsAwake) {  #while the network is asleep
      $CAtime=localtime(time);
      print "\n  -- Starting Sleep Loop at $CAtime Sleep Read # $sleepLoopIndex\n";

      #****************************************************************

      doCommands(); #Request command(s) from cloud servers and queue commands into XBee base radio serial queue 

      #*********** Check if it is time for a Network Discovery and do if it is time
      #my $timeSinceLastND=time - $lastNetworkDiscoveryTime;
      #my $timeTilNextND = ($nodeDiscoverInterval - $timeSinceLastND)/60;
      #print "Time until next Network Discovery = $timeTilNextND  min. \n";  
      #if ($timeSinceLastND >= $nodeDiscoverInterval){ 
         #discoverNetwork(); #careful this will block for a while. queue after other commands
      #   $lastNetworkDiscoveryTime = time;
      #}# end if (time for another network discovery);

      #*********** Request a packet. If received it indicates the network is awake 
      #            unless its some other packet from the base radio like AT command response(136). 
      #            138-11 indicates wakeup;   138-12 indicates gone to sleep      
      $rxM = ''; # reinitialize the packet hash
      print "Trying a read while net is asleep.\n";
      $rxM = $api->rx(); # Try to get packet, will be null if serial port times out before sleep cycle over
      if ($rxM) { # if packet received before serial timeout 
         #print Dumper( $rxM ); #
         $packetType = $rxM->{api_type};
         if(!$rxM->{status}) {
            $packetStatus = "none,  non-138 packet";
         }else{
            $packetStatus = $rxM->{status};
         }
         print "\n Packet type $packetType, status $packetStatus received, ending sleep Loop\n";
         system("touch $touchFile"); #If packets are being received 
         #print " Touched $touchFile\n";
         $networkIsAwake = 1;
         $awakeLoopIndex = 0; # Indicates how many times the wake loop has been executed while the network is awake.
         # end if packet received
         $CAtime=localtime(time);
         print "\n  ++ Starting Wake Read Loop at $CAtime  Wake Read # $awakeLoopIndex\n"; 
      }else { # No packet received
         print "No packet received before serial timeout,  Net still asleep. \n";
      } # end if packet received or not. 
      $sleepLoopIndex++;  # if serial port times out with no packet received increment loop counter. 
   } # end while(network is asleep)

   #my @threadsArray = (); # reinitialize array to put thread objects into

#************* NETWORK AWAKE *********************************************************************************

   while ($networkIsAwake) {
     if ($rxM->{api_type}) { # make sure that a packet has been received.  
         #print Dumper( $rxM ); #Sometimes get here with no value in $rxM causing error messages. 
         $CAtime=localtime(time);
      if ( $rxM->{api_type} == 138 && ($rxM->{status} == 12)) { #indicates network went to sleep
         print "Status = $rxM->{status}\n";
	 #Type 138 modem status packet received and network has gone to sleep
         #print Dumper( $rxM ); 
         print "\nNetwork went to sleep  at $CAtime Sleep cycle # $sleepCycleIndex\n";
         $networkIsAwake = ""; # set flag to indicate net has gone to sleep.
         #print Dumper( $rxM );
         $rxM = ''; # clear the packet hash
         $awakeLoopIndex = 0; # reinitialize Wake loop index when net goes to sleep.
         last;  # end of while($networkIsAwake) 
         # end if(modem status says network is asleep)
      }elsif ( $rxM->{api_type} == 138 && ($rxM->{status} == 11)) { 
         print "Status = $rxM->{status} 138-11 wake up packet received  \n";
	 # received a 138 packet indicating network is awake
         # this will happen if network sends some other packet than 138 first on wake up
         $rxM = ''; 
      }elsif ( $rxM->{api_type} == 138 && ($rxM->{status} == 0)) { 
         print "Status = $rxM->{status} 138-0 Hardware Reset took place \n";
	 # received a 138 packet indicating network is awake
         # this will happen if network sends some other packet than 138 first on wake up
         $rxM = ''; 
      }elsif ( $rxM->{api_type} == 146 ) { # if XBee Sample Data Packet Received (92H receive side)
         #print Dumper( $rxM ); 
	 processDataPacket($rxM);
         $rxM = ''; 
      }elsif ( $rxM->{api_type} == 144 ) { # if Arduino Transmit Packet Received  (10H send side) (90H receive side)
         process144Packet($rxM); 
         $rxM = ''; 
      }elsif( $rxM->{api_type}  == 136 ) { #(local)AT command response to base radio read or write
         #print Dumper( $rxM ); #
         print "Local AT command response (packet type 136) received. No action at this time. \n"; 
         #Need to do something here like for the 151 packet.  
         $rxM = '';
      }elsif( $rxM->{api_type}  == 139 ) { # Tx_Request packet response received, (send to Arduino usually)
         print "\nDetected type 139 Transmit Status packet \n";
         print Dumper( $rxM ); # just dump it for now.  Later send command_Resp to server.
         $rxM='';   
      }elsif ( $rxM->{api_type} == 151 && !defined($rxM{data_as_int})) { 
         # Response to Remote AT command to set parameter value 
         print Dumper( $rxM ); # $rxm{data_as_int} is undefined in this case. 
         my $cmdTime151 = $frameIDcmdTime{$rxM->{frame_id}};
         if (defined($cmdTime151)) {
            delete $frameIDcmdTime{$rxM->{frame_id}};
         }
         print "Remote AT write command response (packet type 151) received, Status = $rxM->{status} (0=Good) \n";
         print "From node $rxM->{sl}, Command $rxM->{command}, Frame_ID = $rxM->{frame_id} Command Time = $cmdTime151\n"; 
         #***************** Push command execution result to the remote server(s) ***********
         pushHTTP("?packetType=commandResp&netID=$netID&nodeID=$rxM->{sl}&param=$rxM->{command}&value=&cmdTime=$cmdTime151&result=success");
         #need to send cmdTime use frame_id to get it. 
         #$rxM{data_as_int} will be undefined if this is a write acknowledgement.
         $rxM = ''; 
      }elsif ( $rxM->{api_type} == 151 && defined($rxM{data_as_int})) { 
         print "Got a query response packet but shouldn't have\n"; #getXBeeRemoteParam blocks til. receives.
         #This is a query response packet, need to send data back and associated command time. 
         print Dumper( $rxM ); # $rxm{data_as_int} is undefined in this case. 
         my $cmdTime151 = $frameIDcmdTime{$rxM->{frame_id}};
         if (defined($cmdTime151)) {
            delete $frameIDcmdTime{$rxM->{frame_id}};
         }
         print "Remote AT query command response (packet type 151) received, Status = $rxM->{status} (0=Good) \n";
         print "From node $rxM->{sl}, Command $rxM->{command}, Value $rxM->{data_as_int} Frame_ID = $rxM->{frame_id} Command Time = $cmdTime151\n"; 
         #***************** Push command execution result to the remote server ***********
         pushHTTP("?packetType=commandResp&netID=$netID&nodeID=$rxM->{sl}&param=$rxM->{command}&value=$rxM->{data_as_int}&cmdTime=$cmdTime151&result=read $rxM->{data_as_int}");
         $rxM = ''; 
      }else {
         print "Packet type not recognized during Wake Read Loop $awakeLoopIndex \n";
         $rxM ='';  # clear the packet hash $rxM for the next packet.
      } # end if packetType A, elsif packetType B, else Didn't recognize packet type  
      if ($awakeLoopIndex > $maxWakeLoops) { # reset XBee and escape wake loop if no 138-12s to exit wake loop  
         system("./XBeeReset");  # Apply half second reset pulse to XBee base radio module 
         select(undef,undef,undef, 5); #  delay 5 sec to let XBee reset
         #********* Write base modem Sleep Time after Reset *********************************
         if (my $baseSPwrite = writeXBbaseParam('SP',$baseConfig{'SP'})) {
         print "Base Radio Modem Sleep Time(SP) value written to value = $baseSPwrite x10ms \n";
         }
         #********* Read base modem Sleep Time value after Write ****************
         if (my $baseSPval = getXBbaseParam('SP')) {
            print "Base Radio Modem Sleep Time(SP) value after write = $baseSPval x10ms\n";
         }
         $CAtime=localtime(time);  
         print "No Packets, Exiting Wake loop after resetting base radio at $CAtime Sleep cycle # $sleepCycleIndex\n";
         $networkIsAwake = ""; # set flag to indicate net has gone to sleep though it may not have
         $rxM = '';  
         $awakeLoopIndex = 0; #reinitialize to prevent immediate reset on next cycle. 
      } # end if too many loops without network going to sleep. 
      select(undef,undef,undef, .1); #.1 second delay 
      $awakeLoopIndex++;
     }else {
        print "Skipped over packet-type parser because no packet received \n"; 
     }# end if packet has been received.

   # Get packet at the end of this loop to allow first pass to process packet received at end of sleep loop. 
      $rxM = ''; # reinitialize $rxM for the next packet.  
      $CAtime=localtime(time);
      print "\n  ++ Next Wake Read Loop at $CAtime  Wake Read # $awakeLoopIndex,  Getting a packet\n"; 
      if ($rxM = $api->rx()) { # If packet received
         #print Dumper( $rxM ); 
         my $packetType = $rxM->{api_type};
         print "\nPacket type $packetType , received in Wake Loop \n";
      }else {# end if packet received
         print "No packet received in wake loop $awakeLoopIndex \n";
      }
   } # end while (network is awake) 
   $sleepCycleIndex++;

   #***********  Send gateway status packet to cloud ***************
   sendStatus();  

} # End MAIN LOOP  while (1)

 
#***********************************************************************************************
#**********************  Subroutine Implementations ********************************************
#***********************************************************************************************
#
#******* Send Gateway status data packet to cloud servers. 
#
sub sendStatus {
   print "Sampling and Sending Gateway status\n";
   my $unixTime= time;   
   # Use nodeID = netID to indicate packet is from the gateway not the base radio. netID may not be unique like base radio sl
         my $urlString = ("?packetType="."data"."&netID=".$pkID{'net'}."&nodeID=".$pkID{'net'}."&port=gtw"."&sensorType=".$gtwSensorType."&atTime=".$unixTime);
         print "Getting Gateway Status Data: \n";
         
         my $memFreekB; 
         my $loadAvg1min; 
         my $cpuUser; 
         my $cpuSys;
         my $diskFreeGB;
         my $netBWavg;
         
         my $top = `top -b -n 1`; #get top information string 
         #print "$top\n";
         #print Dumper( $top ); 
         #print " top output line 3:\n $top\n";
         my $posMf = index($top, 'free');
         #print "Position of searchkey = $posMf\n";
	 #my $lengthNat = length($top);
	 #print "topStr length $lengthNat\n"; 

         $memFreekB = substr($top,($posMf-25),7); 
	 print "Free memory =$memFreekB\n"; 
         
         my $position = index($top, 'average:');
         $loadAvg1min = substr($top, ($position+8), 5);
         print "Load Average 1 min =$loadAvg1min\n";
         
         $position = index($top, '%us,');
         $cpuUser = substr($top, ($position-4), 4);
         print "CPU User =$cpuUser\n";

         $position = index($top, '%sy,');
         $cpuSys = substr($top, ($position-4), 4);
         print "CPU System =$cpuSys\n"; 

         my $df = `df`; #get df information string
         #print "$df\n";
         $position = index($df, '% /');
         $diskFreeGB = substr($df, ($position-2), 2);# changed 10/15/14 M.H. 
         print "Disk Free % = $diskFreeGB\n";
         
         my $vnstat = `vnstat`; #get vnstat information string
         #print "$vnstat\n";
         $position = index($vnstat, 'today');
         $netBWavg = substr($vnstat, ($position+40), 5);
         if ($netBWavg eq "x    ") {
            $netBWavg = 0;
            print "Subsbstituting 0 for x in netBWavg. \n";
         } # little hack to make output numeric before first valid average
         print "Net Bandwidth 1D =$netBWavg\n";	 

         #foreach $key (keys %ENV) {
         #   print "$key->$ENV{$key}\n";
         #}

         print "Node Count = $nodeCount,  Sleep Cycle = $sleepCycleIndex, free Memory = $memFreekB kB, Load Average 1 min = $loadAvg1min, CPU User = $cpuUser, CPU System = $cpuSys, Disk Free = $diskFreeGB, Net Bandwidth 1D = $netBWavg\n";
         $urlString =($urlString."&sleepCycle=".$sleepCycleIndex."&nodeCount=".$nodeCount."&freeMem=".$memFreekB."&loadAvg1min=".$loadAvg1min."&cpuUser=".$cpuUser."&cpuSys=".$cpuSys."&diskFree=".$diskFreeGB."&netBWavg1D=".$netBWavg); # concatenate parameter onto end of http packet
         #Strip out spaces from the urlString here.
         while (($pos_1 = index($urlString,' ')) gt 0) {
            #print "Index of first space = $pos_1 \n";  
            substr($urlString, $pos_1,1) = '';
         }  
         print " urlString with nulls/spaces stripped = $urlString|\n";

         print "cs3 gateway Status packet sensorType $gtwSensorType = \n    $urlString \n";  
         # Push data to remote server via http: request.
         pushHTTP("$urlString");

}



#******** Request a command from each server and if command, execute ***************************
#
sub doCommands {
   foreach $server (@cloudServers){
      #print "Getting Command From: $server \n";
      #***** Send Request to server for a command and execute
      my $commandStr = get($server."?packetType=commandReq&netID=$netID");
      #print "Received = $commandStr \n";
      my $destL=""; # need to clear this here. 
      my $paramR=""; # this too.
      my $value=""; 
      if(defined($commandStr)) { #if server online and responded, maybe with null command 
        my $commandHashRef = parseCommand($commandStr);
        if(($commandHashRef)) { #if command parser returned a command hash
           my %commandHash = %$commandHashRef;   # dereference command hash ref to get command hash
           #foreach  $commandKey (keys %commandHash) {
              #print "Command Hash $commandKey,  $commandHash{$commandKey} "; # if ($commandHash{$commandKey});
           #}
           $paramR = $commandHash{command}; # should do some validity checking here. 
           $destL = $commandHash{nodeID};
           $cmdTime = $commandHash{cmdTime};
           $value = $commandHash{value};
           #********* If command is for a remote arduino **************************
           if (substr($paramR,0,1) eq "-") { # if command starts with a "-" it is an arduino command
               print "\n***********************************************************************************************\n"; 
               sendToArduino($destL,$paramR,$value,$cmdTime);
               print "Sent to Arduino at $destL,  parameter $paramR, value $value at $cmdTime\n";
               print "***********************************************************************************************\n"; 
               # should store commandTimeS for later matching to a response with a commandTime in it. 
                    pushHTTP("?packetType=commandResp&netID=$netID&nodeID=$destL&param=$paramR&value=$value&cmdTime=$cmdTime&result=sent");
               return;
           } 
           if ($value) { # if value was provided with command 
              #********* Write the remote node command parameter to value ******************************
              my $IOvalue = $commandHash{value}; # set node parameter
              if ($destL eq $baseSLval){
		 #********* Write base modem parameter *********************************
                 if (my $baseWrite = writeXBbaseParam($paramR,$IOvalue)) {  # returns param not the value
                    print "Base Radio Modem $paramR value written to value = $IOvalue \n";
                    if ($paramR eq "ID") { # if the base radio ID was written update $netID
                       print "Writing base modem ID  and netID = $IOvalue\n";
                       $netID = $IOvalue;
                    } 
                    pushHTTP("?packetType=commandResp&netID=$netID&nodeID=$destL&param=$paramR&value=$baseWrite&cmdTime=$cmdTime&result=success");
                 }
              }else{ #******Write Remote Node Parameter ********************************
                 my $frame_id1 = writeXBremoteParam($destL,$paramR,$IOvalue,$cmdTime);
                 if ($frame_id1) { #API accepted call and returned a frame_ID
                    print "Remote_AT Command Sent: $paramR = $IOvalue to $destL, Frame_ID =  $frame_id1 Command Time = $cmdTime \n";
                    pushHTTP("?packetType=commandResp&netID=$netID&nodeID=$destL&param=$paramR&value=$IOvalue&cmdTime=$cmdTime&result=sent");
                 } #end if API accepted remote write call
              } #end if-else write base-remote modem parameter
           # end if command value defined
           }elsif (!$commandHash{value} && $commandHash{command}) { 
              #command but no parameter passed with the command means read parameter value from node.
              if ($destL eq $baseSLval){
                 #********* Read base modem parameter value *************************
                 if (my $baseReadVal = getXBbaseParam($paramR)) {
                    print "Base Radio Modem $paramR value = $baseReadVal read\n";
                    pushHTTP("?packetType=commandResp&netID=$netID&nodeID=$destL&param=$paramR&value=$baseReadVal&cmdTime=$cmdTime&result=success"); # should actually wait for 151 packet to come back before declaring success. 
                 }
              }else{
                 $paramValue = getXBremoteParam($netID,$destL,$paramR,$cmdTime);# blocks until response or timeout;danger
                 print "Remote XBee $commandHash{nodeID} $commandHash{command} read value = $paramValue \n"; #works
                 # Send response packet with the value read.  
                 pushHTTP("?packetType=commandResp&netID=$netID&nodeID=$destL&param=$paramR&value=$paramValue&cmdTime=$cmdTime&result=success"); # should actually wait for 151 packet to come back before declaring success.
              } #end if-else get parameter
           } # end elsif() read value of param from remote node and push to server
         } # end if commandHash defined - non null command values received from server
      }# end if(defined($commandStr)  command string received from cloud server

      # don't check for an acknowledgement packet here because it would block for too long.
      # When acknowledgement packet 151 comes in send command response packet to update command status on server.  
   } # end foreach $server
} # end doCommands()
#************************Arduino Commands*******************************
# This is the command string format to use in the payload of the tx_request packet that is sent to a node
# //
# //  -ABC123--123XYZ    arbitrary command--value pair
# //  -ap3h              set arduino pin PD3 High
# //  -ap3               query arduino pin 3 state, mode and value
# //  -ap4l              set arduino pin 4 LOW until command to contrary, puts pin in digitarl out mode. 
# //  -ap5h--100         set arduino pin PD5 High for 100 seconds
# //  -aps3              apply voltage to SS3 pin opt01/pwr 
# //  -rs4--300          apply current to coil of relay #4 on arduino relay shield 
# //  -rss3--180         apply current to coil of relay on SS3 
# //  -txt--Hello World  Display text on arduino display shield. 
# //  -cp2--9            chargepump capacitor on SS2 to 9V and maintain until discharge command. or default timout
# //  -av3--600          pulse bistable valve connected to SS3 open and after 10 minutes pulse it closed.
# //  -sac1              sample the voltage on SS1 cap 
# //  -saa3              sample the voltage on pin A3 and send back to gateway.
# //  -ps--23            play sound sample 23 on wav shield.
# //  -ci--4             capture image with camera shield resolution 4 and send back. 
#
#
#*********************************************************************************************

#********************** Parse commands from remote server ************************************
 
sub parseCommand {# receives a string and returns a hashRef which points to a Hash with the following keys 
   #print " parseCommand() received the following string $_[0] \n";
   my $command = getValue($_[0],'command');
   my $value = getValue($_[0],'value');# This will be null for a query command
   my $node = getValue($_[0],'nodeID');
   my $cmdTime = getValue($_[0],'cmdTime');
   if (!($command eq "")) {
      print " Command parsed= command $command, value $value, node $node cmdTime $cmdTime\n";
      my $commandHash = {command=>$command, value=>$value, nodeID=>$node, cmdTime=>$cmdTime};
      return $commandHash; # returns a reference to a Hash
   }else {
      #print "Command Parser did not receive a string to parse\n";
      return "";
   }
}
#********************** Push HTTP format data string into an available thread's queue *******************************
#   Takes an http parameter string and sends it to the next available thread, The thread is responsible for pushing 
#   the data to all servers on the server list.   
sub pushHTTP {
       my $postString = $_[0];
       # Wait for an available thread.  idle thread IDs are put into the IDLE_QUEUE which is separate from the thread queues.
       my $tid = $IDLE_QUEUE->dequeue();  # this better not block very often but it will if no thread IDs enqueued available.
                                          # use dequeue_nb()  "non blocking to avoid blocking if this becomes a problem.  
       # Give the thread some work to do;   enqueue a postString for push
       #my $work = $postString;
       print "Enqueueing postString $postString \n";
       $work_queues{$tid}->enqueue($postString);  #put the $work item into the work queue associated with thread, $tid 
       # 5 lines below useless.   the threads are always running. Left here for reference.
       #my @threadsList = threads->list();
       #my $thread_count = threads->list(); 
       #my @running = threads->list(threads::running);
       #my @joinable = threads->list(threads::joinable); 
       #print "Threads not currently detached = @threadsList Thread_count = $thread_count Running = @running  Joinable = @joinable\n";
}

#********************** Push data to cloud servers *********************************************
#   Takes an http parameter string and sends it to the list of cloud servers
#   prints the response string from each server
#   This function is called by the threads. 
sub pushHTTPthread {
       my $postString = $_[0];
       my $server;
       foreach $server (@cloudServers){
          #print "Pushing to: $server $postString\n";
          getprint($server.$postString);# Use this to see server's response. 
          #get($server.$postString);
       } 
}

#******************** worker thread subroutine, used to push HTTP format packets to servers *******************************
#    MAX_THREADS copies of which run continuously after startup of this program
#      
sub worker   
{
    my ($work_q) = @_;  #redundant use of a variable here creating mass confusion. ($work_q) here it is a list of the parameters passed to sub worker. 
                            # it contains a Thread::Queue object in this case

    # This thread's ID
    my $tid = threads->tid();

    # Work loop
    do {
        # Indicate to main that we are ready to do work and which thread we are. main will then enqueue a task in the queue associated with this thread
        # but, only ever one since this subroutine doesn't get called until main see's it is idle 
        printf("Idle     -> %2d\n", $tid);
        $IDLE_QUEUE->enqueue($tid);  #put our ID into the idle_queue
        # could skip the idle queue and just sample each of the threads in sequence to see if they are still running or not.  

        # Wait for work from the queue   This can block because it is in a separate thread  Main thread needs to keep running. 
        my $work = $work_q->dequeue();  #  again same variable reused in different scope.  This code sucks. 
            # pull a work item off of the queue for this thread. This is stupid because only one item at a time ever get's put into a thread's queue
            # $work here would be a list item capable of fitting into the queue list, it would have to be an array with the server name and packet string to push. 

        # If no more work, exit
        #last if ($work < 0);

        # Do some work while monitoring $TERM
        printf("            %2d <- Working\n", $tid);
        #while (($work > 0) && ! $TERM) {
            print "thread $tid pushing $work \n\n";
            #pushHTTP ("?packetType=data&netID=20501&nodeID=1084807054&port=0&sensorType=200&atTime=1401886521&an0=797&an1=1023&an2=1023&an3=1023");
            pushHTTPthread ($work); 
            sleep (8);      
            #print "work = $work \n";
            #$work -= sleep($work); # count down work until less than zero, dummy work
        #}
        # Loop back to idle state if not told to terminate
        #last;
    } while (! $TERM);

    # All done
    printf("Finished -> %2d\n", $tid);
} # end subroutine worker()



#********************** Process Data Packet  type 146 (92H)****************************************
#   Sample four 10 bit ADC data values  and push to remote server
#   Called with packet hash received from the XBee API. 
#   If any of the input pins are not defined as ADC inputs the API returns undefined values for those pins. 
#   If data value[0] is undefined no action is taken.  

sub processDataPacket { # This parses an XBee type 146 packet with data sampled by the XBee Radio
   my $rxMs = $_[0];  # this is a pointer to the packet hash
   if ($rxMs->{analog_inputs}->[0] || $rxMs->{analog_inputs}->[1] || $rxMs->{analog_inputs}->[2] || $rxMs->{analog_inputs}->[3]) { #if there is some data data defined in the hash
        # if D0 is set to pin mode 1, commisioning input then its value is undefined when sending data 
      #print Dumper( $rxMs );
      $pkID{'net'} = $netID;
      $pkID{'node'} = $rxMs->{sl};
      $pkID{'port'} = $adcsPort; # Should be one port for each analog input but, hard to append then.  Leave as is. 
      $pkID{'sensorType'} = $adcsSensorType;
      my $unixTime= time;   
      my $urlString = ("?packetType="."data"."&netID=".$pkID{'net'}."&nodeID=".$pkID{'node'}."&port=".$pkID{'port'}."&sensorType=".$pkID{'sensorType'}."&atTime=".$unixTime);
      my $avIndex = 0;
      print "************************************************** $pkID{'node'} *********** \n";
      while ($avIndex <= 3) {# while there are still analog inputs to process
#     while ($rxMs->{analog_inputs}->[$avIndex]) {  # while there are still analog inputs to process
         my $dataValue =  $rxMs->{analog_inputs}->[$avIndex];
         my $sParam = "an".$avIndex;
         #print ($sParam,"=",$dataValue,"  ");
         # Build the URL string to send via port 80. 
         $urlString =($urlString.'&'.$sParam.'='.$dataValue);  
         $avIndex++;
      } # end while still some analog input values to process
      # Push data to remote server via http: request.
      #print "\nURL String  = $urlString \n";   
      pushHTTP("$urlString");
      #get("$urlString");
      system("touch $touchFile");
      #print "touched $touchFile" ;
   } # end if there is data defined in the hash
}# end processDataPacket 

#************** Process Data Packet type 144, (90H)  Packet with payload from Arduino ***********************
#   Translate and Push data received from Arduino in field node to remote server
#   called with received type 144 packet hash from Eagle XBee API.
#   First instantiation parses out a water meter like count and a packet count. second includes GPS
#   Third includes Terraduino internal voltages, batt/solar/external   

sub process144Packet {
   my $rxMs = $_[0];  # this is a pointer to the packet hash
   my $unixTime= time; # capture time as close to when packet was received as possible, closer to sampling time 
   #print Dumper( $rxMs );
   $pkID{'node'} = $rxMs->{sl};
   my $pktSubType = unpack("C",substr($rxMs->{'data'},0,1));# get the packet subtype from first byte(int) (arduino payload type)  C unpacks into a char, if 0 PERL interprets it as a zero in the numeric tests below. 
   $pktSubType = $pktSubType + 0; # try to force char value to become an int.  Could also unpack to int with "i"
        #**********************************************************************
        #Packet sub-Type 0-Obsolete Terraduino-N135 specific combo packet     #
        #                1&  Terraduino generic data packet no sensorType     #
        #                1?  Camalie http format packet deprecated            # 
        #                1(!& and !?) Old count packet                        #
        #                2   arduino GPS payload                              #
        #                48  "0" 0x30H Camalie http format packet,arduino .analog in  #
        #                50  Terraduino Config payload                        #
        #**********************************************************************
   print "Packet type 144 - $pktSubType from arduino based Node ->  ****************** $pkID{'node'} *********** \n";
   if ($pktSubType == 2) { # ************************  Parse GPS coordinates out of packet.
      my $latitude = substr($rxMs->{'data'}, 1,11);
      $latitude = $latitude + 0.0; #convert $latitude from string to F.P. 
      my $longitude = substr($rxMs->{'data'}, 13,11);
      $longitude = $longitude + 0.0; #convert $longitude from string to F.P. 
      print "latitude = $latitude  longitude = $longitude \n";
      $pkID{'net'} = $netID;
      $pkID{'node'} = $rxMs->{sl};
      $pkID{'port'} = 0;
      $pkID{'sensorType'} = $GPSsensorType;
      # Build the URL string to send via port 80. 
      my $urlString = ("?packetType="."data"."&netID=".$pkID{'net'}."&nodeID=".$pkID{'node'}."&port=".$pkID{'port'}."&sensorType=".$pkID{'sensorType'}."&atTime=".$unixTime.'&latitude='.$latitude.'&longitude='.$longitude);
      # Push data to remote server via http: request.
      pushHTTP("$urlString");
      # end if subType 2; GPS packet

   }elsif ($pktSubType == 1) { #*******  Parse switch closure count and switch state 1(!&)or                 
      #print Dumper( $rxMs );   #*******  generic arduino data including Terraduino 1&
      my $tempChar = unpack("A",substr($rxMs->{'data'},2,1)); #Get second byte and see if it is an &;
      #print "Looking for first & at position 2, found = $tempChar\n"; 
      if ($tempChar eq "&") {#if the second byte is an ASCII ampersand then this is an arduino data packet.
         #my $pktNumber = substr($rxMs->{'data'},3,3); # Can't take 3 as sometimes it is only 1 or 2 char.
         my $pktNumber; 
         my $pos2 = -1;
         ($pktNumber,$pos2) = getPacketNumber($rxMs->{'data'}); # returns position of "&" after the packet Number
         print "arduino data payload number $pktNumber found, Parsing...\n";
         # If no configuration meta data is available do the following
         my $pos1 = $pos2; # start looking for sensor blocks after & after packet number
         #$pos2 = 0; #position in character string of end of last string parsed out.  -1 if at end
         my $portName = "";
         while ($pos2 != -1) { #while still finding sensor data blocks 
            #Parse out a portname string between & and :  expect $pos2 on final delimiter or -1 if nothing found
            my $urlString = ("?packetType="."data"."&netID=".$netID."&nodeID=".$rxMs->{sl}."&atTime=".$unixTime); 
            ($portName,$pos2) = getPortName($rxMs->{'data'},$pos1); #pos2 pointing to char after portName or -1
            if($portName ne "") { #portName found, add portName to urlString, parse out sValues and append to urlString
               #Append portname to urlString;
               $urlString = ($urlString."&port=".$portName); # only stuff after port name goes into RRDs
               if ($portName eq "I1") {
		  $urlString = ($urlString."&sensorType=".$terraduinoInternalsType); # vBatt, vSolar, vExt
               }else {
		  $urlString = ($urlString."&sensorType=".$unknownSensorType); #temporary until config data known.
               }
               $urlString = ($urlString."&sampleTime=".$unixTime."&pktNum=".$pktNumber);# redundant to get data into RRD.
               my $pIndex = 1; #sValue index, used to generate default parameter name for sValue until config data known.
               #while pos2 is not pointing at & and is not -1 Parse out sValues associated with this port
               while(($pos2 != -1) && (substr($rxMs->{'data'}, $pos2, 1) ne "&")) {
                  #parse out sValue between (:) and (: or & or null) Leave pointer on final delimiter
                  ($sValue,$pos2) = getSensorValue($rxMs->{'data'}, $pos2);
                  #print "SensorValue Parsed and Returned = $sValue final char at position $pos2\n";
                  #append data value urlString after p.i an array entry data value
                  $urlString = ($urlString."&p".$pIndex."=".$sValue);
                  $pIndex++;
               } # end while finding more sensor data
            }#end if portName found
            #push to web http format sensor data packet for this port    
            #print "urlString for port $portName = $urlString \n\n";
            pushHTTP($urlString);
            $pos1 = $pos2; # Advance position start to end of the current sensor Block
         }#end while still finding sensor data blocks
      }elsif($tempChar eq "?") { # Then we have an http format packet
         # Example packet    1?p=An6&s=210&t=31000&V0=0130&V2=0243 .... &V5=0156 
         #    p=port, s=sensorType, t=time(hearBeat count) 
         print " Received an obsolete http format packet starting with 1? s/b 0x30? now \n"; 
         print " Payload String =  $rxMs->{'data'} \n";
      }elsif($tempChar ne "&" && $tempChar ne "?"){ #the packet should be a deprecated count data packet
         my $count = unpack("n",substr($rxMs->{'data'}, 1,2));# get the count out of the packet
         my $pinNumber = unpack("C", substr($rxMs->{'data'},3,1));
         my $pinState = unpack("C", substr($rxMs->{'data'},4,1));
         my $packetNumber = unpack("n",substr($rxMs->{'data'},9,2));
         my $stringLeft = substr($rxMs->{'data'},15,42);  
         print "count = $count pinNumber = $pinNumber pinState = $pinState packetNumber= $packetNumber\n";
         print "Remainder of Payload = $stringLeft \n";
         $pkID{'net'} = $netID;
         $pkID{'node'} = $rxMs->{sl};
         $pkID{'port'} = $pinNumber; 
         $pkID{'sensorType'} = $countSensorType;
         # Build the URL string to send via port 80. 
         my $urlString = ("?packetType="."data"."&netID=".$pkID{'net'}."&nodeID=".$pkID{'node'}."&port=".$pkID{'port'}."&sensorType=".$pkID{'sensorType'}."&atTime=".$unixTime);
         $urlString =($urlString.'&count='.$count.'&pinState='.$pinState.'&packetNum='.$packetNumber);  
         #print "\nURL String  = $urlString \n"; 
         # Push data to remote server via http: request.
         pushHTTP( "?packetType="."data"."&netID=".$pkID{'net'}."&nodeID=".$pkID{'node'}."&port=".$pkID{'port'}."&sensorType=".$pkID{'sensorType'}."&atTime=".$unixTime.'&count='.$count.'&pinState='.$pinState.'&packetNum='.$packetNumber); 
      } # end else packet is a count packet
   # end elsif subtype == 1 Switch closure counting and switch state or arduino generic data packet. 
   }elsif($pktSubType == 0) {  # *********************  parse Terraduino internal voltages and send. 
      print "Obsolete pktSubType 0 encountered, N135 on Terraduino G is the only node that sends this packet type \n";   
      #print Dumper( $rxMs );
      my $packetNumber = unpack("S",substr($rxMs->{'data'},2,2));# S worked
      my $internalSensorID = unpack("n" ,substr($rxMs->{'data'},4,2)); # should always be 0xff00
      my $vBatt = unpack("S",substr($rxMs->{'data'},7,2));# get the voltages out of the packet
      my $vSolar = unpack("S", substr($rxMs->{'data'},9,2));
      my $vExt = unpack("S", substr($rxMs->{'data'},11,2));
      print "Terraduino Vbatt = $vBatt VSolar = $vSolar VExt = $vExt Sensor ID = $internalSensorID  packetNumber= $packetNumber\n";
      #  Doing a temporary hard wired parse of Alan's test code here
      my $vWatermark = unpack("S", substr($rxMs->{data},16,2));
      my $vThermistor = unpack("S", substr($rxMs->{data},21,2)); 
      print "Terraduino VWatermark = $vWatermark  VThermistor = $vThermistor\n";
      $pkID{'net'} = $netID;
      $pkID{'node'} = $rxMs->{sl};
      $pkID{'port'} = 0; 
      $pkID{'sensorType'} = $terraduinoType;
      # Build the URL string to send via port 80. 
      my $urlString = ("?packetType="."data"."&netID=".$pkID{'net'}."&nodeID=".$pkID{'node'}."&port=".$pkID{'port'}."&sensorType=".$pkID{'sensorType'}."&atTime=".$unixTime);
      $urlString =($urlString.'&vBatt='.$vBatt.'&vSolar='.$vSolar.'&vExt='.$vExt.'&packetNum='.$packetNumber);  
      #print "\nTerraduino URL String  = $urlString \n"; 
      # Push data to remote server via http: request.
      pushHTTP("$urlString");

      # Send temp hard wired SMT and Temp from Terraduino in a second packet.       
      $pkID{'sensorType'} = $testType;
      $urlString = ("?packetType="."data"."&netID=".$pkID{'net'}."&nodeID=".$pkID{'node'}."&port=".$pkID{'port'}."&sensorType=".$pkID{'sensorType'}."&atTime=".$unixTime);
      $urlString =($urlString.'&vWatermark='.$vWatermark.'&vThermistor='.$vThermistor.'&packetNum='.$packetNumber);  
      #print "\nTerraduino URL String  = $urlString \n"; 
      # Push data to remote server via http: request.
      pushHTTP("$urlString");

    }elsif ($pktSubType == 48) { # ***********  Camalie http format packet starting with 0x30(ASCII 0 or 48 decimal)
         # Just add netID, nodeID, packetType, atTime 
         print " Received a CS3 stalker http format packet type 144-48";
         #print Dumper( $rxMs );   
         my $pos_1; 
         #print " Payload 144-48 pre strip =  $rxMs->{'data'}| \n";
         my $tmpString = substr($rxMs->{'data'},1); #strip off the leading 0x30 
         #Strip out spaces from the payload here.
         while (($pos_1 = index($tmpString,' ')) gt 0) {
            #print "Index of first space = $pos_1 \n";  
            substr($tmpString, $pos_1,1) = '';
         }  
         print " Payload = $tmpString|\n";
         my $urlString = ("?packetType="."data"."&netID=".$pkID{'net'}."&nodeID=".$pkID{'node'}."&atTime=".$unixTime);
         $urlString =($urlString.$tmpString); # concatenate pktType,net,node with http data string from node
         #print "cs3 stalker node analog data String = $urlString \n";  
         # Push data to remote server via http: request.
         pushHTTP("$urlString");

    }elsif ($pktSubType == 50) {  # **********  Terraduino port configuration packet, forward to cloud 
      print "Received Terraduino Config Packet from node $rxMs->{sl},  Forwarding \n";   
      #print Dumper( $rxMs );
      $pkID{'net'} = $netID;
      $pkID{'node'} = $rxMs->{sl};
      $pkID{'port'} = 0; 
      $pkID{'sensorType'} = $terraduinoType;
      my $urlString = "";
      # Build the URL string to send via port 80. 
      $urlString =($urlString."?packetType="."pConfig"."&netID=".$pkID{'net'}."&nodeID=".$pkID{'node'});
      my $configStr = "";
      my $pos1 = 0;
      my $pos2 = 0;
       while($pos2 ne -1) { # chop packet into one port chunks and send each.
          ($configStr, $pos2) = getPortConfigStr($rxMs->{data},$pos1);
           ($pkID{'port'}) = getPortName2($configStr); 
           $configStr = replaceSubstr($configStr,';','%3B');
           $configStr = replaceSubstr($configStr,'#','%23');
           my $pUrlString =($urlString."&port=".$pkID{'port'}."&atTime=".$unixTime."&configStr=".$configStr);  
           #print "\nSending Terraduino Sensor Configuration URL String  = $pUrlString \n"; 
           # Push data to remote server via http: request.
           pushHTTP("$pUrlString");
           $pos1 = $pos2; #advance the string pointer past the current port config substring
       } # end while still port strings to parse. 
    } # end if subtype = 50 (Terr)arduino sensor config packet
   system("touch $touchFile");
   #print "touched $touchFile" ;
}# end process144Packet() 


#*************** Network Discovery  ***********************************************
# Do a Network Discovery here, store list of nodes to a local sqlite DB
# The Node Hash that is returned by the XBee::API contains the following keys=>data
#   'sl'  Serial Number low 32 bits in decimal
#   'device_type'  No data
#   'manufacturer_id' No data; can use 'sh" for this if desired 
#   'profile_id'  Occasionally 49413 comes through here
#   'sh' Serial number high 32 bits in decimal, manufacturer specific
#   'sn' "sh_sn" This string is actually the nodesHash key for a given node
#   'last_seen_time'  Unix time the node was last heard from
#   'ni' user assigned name for node, doesn't always come through. 
#   'na' I believe this is the 16 bit address. value=65534(FFFE) if 16 bit addressing is not being used.
# The XBee:API Network Discovery operation does not return a node hash for the base radio. 

sub discoverNetwork {
      $CAtime=localtime(time);
      print "Started Network Discovery at $CAtime\n"; 
      #my $discNet = $api->discover_network(); # these API calls don't block?  
      my $nodesHashRef = $api->known_nodes();  #This is a hash reference 
      my %nodesHash = %$nodesHashRef ;  # this is a hash of hashrefs
      $nodeCount = (keys %nodesHash);
      print "Number of nodes found = $nodeCount \n";
      foreach  $nodeHashKey (keys %nodesHash) { # Keys are listed in comments above. 
         print "$nodeHashKey,  $nodesHash{$nodeHashKey} \n"; # print key for a node hash and print node hash ref.
         my $nodeHashRef =$nodesHash{$nodeHashKey};
         my %nodeHash = %$nodeHashRef;   # dereference node hash ref to get node hash
         foreach $nodeParamKey (keys %nodeHash) {
            print "$nodeParamKey,  $nodeHash{$nodeParamKey} \n" if ($nodeHash{$nodeParamKey});
         }
         # Store node info to the 'nodes' table
         $sthNode = $dbh->prepare('INSERT INTO nodes VALUES (?,?,?,?)')
         #nodes table row definition 
         #(Node low 32 bits of SN(sl) INTEGER, node name(ni) TEXT, Location TEXT, last_seen_time Text)
            or print "Couldn't prepare nodes table insertion statement: " .$dbh->errstr."\n";
         if (!$nodeHash{'ni'}) {$nodeHash{'ni'} = "";}  # if no label found just make it a null string. 
         $sthNode->execute( $nodeHash{'sl'} , $nodeHash{'ni'} , "unknown", $nodeHash{'last_seen_time'})
            or print "Couldn't execute insert node info into nodes table " . $sthNode->errstr."\n";
         # Push data to remote server(s)      
         pushHTTP("?packetType=node&netID=$netID&nodeID=$nodeHash{'sl'}&nodeName=$nodeHash{'ni'}&lastHeard=$nodeHash{'last_seen_time'}");
      } # end foreach $nodeHashKey
      # Now send Base Radio Node info since XBee::API Network Discovery doesn't return info on base radio.  
      my $unixTime = time;
      # Store node info to the 'nodes' table
      $sth2Node = $dbh->prepare('INSERT INTO nodes VALUES (?,?,?,?)')
      #nodes table row definition 
      #(Node low 32 bits of SN(sl) INTEGER, node name(ni) TEXT, Location TEXT, last_seen_time Text)
         or print "Couldn't prepare nodes table insertion statement: " .$dbh->errstr."\n";
      if (!$baseNIval) {$baseNIval = "Base";}  # if no label found for the base radio send "Base" 
      $sth2Node->execute( $baseSLval, $baseNIval, "Gateway $netID", $unixTime)
         or print "Couldn't execute insert base radio node info into nodes table " . $sth2Node->errstr."\n";
      # Push data to remote server(s)      
      pushHTTP("?packetType=node&netID=$netID&nodeID=$baseSLval&nodeName=$baseNIval&lastHeard=$unixTime");
} # end discoverNetwork()

sub getNetworkID { # Get the network ID from the base radio in the CS3 gateway, used in packets sent to camnets
      $netID = getXBbaseParam('ID');
      $unixTime = time;
      $CAtime=localtime($unixTime);
      print "Requested Network ID from base radio module at $CAtime \n";
      $pkID{'net'}=$netID; # 
      print "netID value returned from getXBbaseParam() = $netID \n";
      # Store the network info in the network table
      $sthNet = $dbh->prepare('INSERT INTO network VALUES (?,?,?)')
      #network table row definition (networkID INTEGER, networkName TEXT, lastUpdated TEXT)
            or print "Couldn't prepare data table insertion statement: " .$dbh->errstr."\n";
      # Later the networkName will come from the remote server after the user names this network.
      $sthNet->execute($netID, $networkType.$netID, $unixTime=time)
            or print "Couldn't execute insert in network table " . $sthNet->errstr."\n";
      if ($sthNet) {print "Successful store of Network ID $netID to local TABLE network\n";} 
      # Push network data to the remote server
      pushHTTP("?packetType=network&netID=$netID&networkName=CS3net$baseNIval"." w/Base Radio $baseSLval&localIPaddr=$localIPaddr&lastHeard=$unixTime");
} # end getNetorkID()


#*********************  Subroutine to get a base radio modem parameter.  ********************************************

sub getXBbaseParam { #     Accepts a two letter command code and returns the value read from the base radio module
   #print "command received by getXBbaseParam() =$_[0]\n";
   my $paramR = $_[0]; 
   my $paramString = '';
   my $at_frame_id = $api->at($paramR);  #at() function always reads from the base radio modem regardless of its ID
   print "Transmit failed" unless $at_frame_id;
   # Receive the reply
   my $rxR = $api->rx_frame_id( $at_frame_id );  #Looking for a type 151 packet here, not likely this soon.
   if (!$rxR) {
      print "No immediate reply received\n" ;
      return ""; # Look for a packet type 136 AT command response later. 
   }elsif ($rxR && $rxR->{status} != 0 ) {
      print "API error" if $rxR->{is_error};
      print "Invalid command" if $rxR->{is_invalid_command};
      print "Invalid parameter" if $rxR->{is_invalid_parameter};
      print "Unknown error";
      print Dumper( $rxR );
   }elsif ($rxR && $rxR->{status} == 0 ) { #proper response received
      #type 136(0x88) AT response packet received with no errors. 
      #print Dumper( $rxR );
      $paramValue = $rxR->{data_as_int};  #numeric values in this hash element, e.g. values of ID,SM,SO..
      $paramString = $rxR->{data};        #string values in this hash element, e.g. name string NI. 
      #print "Base Radio Modem $paramR value read:  data = $paramString  "; 
      #if ($paramValue) { 
      #   print "data_as_int = $paramValue\n";
      #}
      if ($paramR eq "ND") { # do a network discovery
         discoverNetwork(); # This function sends node packets to the web for each node discovered
         return $paramString;
      }elsif($paramR eq "NI") { # Return string value if its a node identifier string
         return $paramString; 
      }else{
         return $paramValue; # else return and int 
      }
   } # end if,else
} # end sub getXBbaseParam()

#**************** Subroutine to write a base radio modem parameter.  ***************
sub writeXBbaseParam { # accepts a two letter command and a value and returns value if success else null
   my $paramR = $_[0]; 
   my $IOvalue = $_[1];  
   my $paramBin =  pack("N",$IOvalue); # pack to a long in "Network" Big Endian Order. 
   my $at_frame_id = $api->at( $paramR, $paramBin, apply_changes => '1'); 
   #apply changes doesn't do NVM write just simultaneous write of changes queued up.  
       #put this change into NVM, apply_changes => '1'   
   print "Transmit failed" unless $at_frame_id;
   # Receive the reply
   $rx = $api->rx_frame_id( $at_frame_id );
   if (!$rx) {
      print "No immediate reply received writing Base Radio" ;
      return ""; # Look for a packet type 13      #type 136(0x88) AT response packet received with no errors. 
      #print Dumper( $rx );
      return ""; # Look for a packet type 136 AT command response later. Match up frame_id somehow. 
   }elsif ($rx && $rx->{status} != 0 ) {
      print "API error" if $rx->{is_error};
      print "Invalid command" if $rx->{is_invalid_command};
      print "Invalid parameter" if $rx->{is_invalid_parameter};
      print "Unknown error";
      #print Dumper( $rx );
      return "";
   }elsif ($rx && $rx->{status} == 0 ) {
      #type 136(0x88) AT response packet received with no errors. 
      #print Dumper( $rx );
      #No data is returned with a 136 response to a write. 
      print "Received XBee status=success writing Base Modem parameter $paramR to $IOvalue\n"; 
      #$netID = $rx->{na};  #update the Network ID from the type 136 packet in case it was changed by an ID command.
        # This writes $netID to null when a 136 packet to the base comes in in response to other than ID command.  
        # When a 136 "ID" acknowledgement comes in should automatically do an ID query and update $netID
      return $IOvalue;
   } # end if elsif
} # end sub writeXBbaseParam()

#********* Read remote modem parameter value *******************************************
# takes netID, nodeID param/command  like 'ID' and cmdTime and returns value of param from node
# If no parameter returned within timeout it stores the frame_id associated with the commandTime
# in case the response comes back later.  

sub getXBremoteParam { 
   my $netID = $_[0];
   my $nodeID = $_[1]; 
   my $paramR = $_[2];
   my $cmdTimeS = $_[3];
   my $at_frame_id = $api->remote_at( { sh =>$destH , sl =>$nodeID, na => $netID  }, $paramR);
   print "Transmit failed" unless $at_frame_id;
   # Receive the reply
   my $rxR = $api->rx_frame_id( $at_frame_id );
   if (!$rxR) {
      print "No reply received" ;
      if (defined($at_frame_id)){
         $frameIDcmdTime{$at_frame_id} = $cmdTimeS; # save association in global Hash
         # save the frame ID=>cmtTime association if no immediate response received. 
      }
   }elsif ($rxR && $rxR->{status} != 0 ) {
      print "API error" if $rxR->{is_error};
      print "Invalid command" if $rxR->{is_invalid_command};
      print "Invalid parameter" if $rxR->{is_invalid_parameter};
      print "Unknown error";
      print Dumper( $rxR );
   }elsif ($rxR && $rxR->{status} == 0 ) { # clean response received.
      #print Dumper( $rxR );
      $paramValue = $rxR->{data_as_int}; # this is the value unpacked type "n" 
      if ($paramR eq "TP") {
         $paramValue = ($rxR->{data_as_int}-327)*1.8+32;# temp conversion to Fahrenheit
	 #$paramValue = substr($rxR->{data},1);
         print "paramValue  = $paramValue\n";
	 #$paramValue = "0x".$paramValue;
	 #my( $hex ) = unpack( 'H*', $mem );
         #print "Hex repr =$hex\n";
         #$paramValue = unpack("H*", $paramValue);
         #print "paramValue upacked = $paramValue\n";
      }elsif ($paramR eq "%V") {
         $paramValue = ($rxR->{data_as_int})/1000;
      }elsif ($paramR eq "NI") { # Node Identifier comes back as a string
         $paramValue = $rxR->{data};
         print "Remote Modem $nodeID  parameter Node Identifier read (NI) = $paramValue \n"; #
     }
      #print "Remote Modem $nodeID  parameter $paramR read = $paramValue \n"; #
      return $paramValue;
   } # end elsif $rxR
   return "No remote node response received"; 
} # end subroutine getXBremoteParam()

#********* Write remote modem parameter value **********************************************************
# Subroutine to Send an API command to get from a remote XBee module the value of the parameter passed. 
# Added send of -xxx commands in tx_request payload to arduino on node  2/7/14 M.H.   

sub writeXBremoteParam { # takes node number sl and param like 'ID' and IOvalueR like 5
   # Send the API command to get the value of the parameter $paramR from $destH, $destL
   my $destLR = $_[0];
   my $paramR = $_[1]; 
   my $IOvalueR = $_[2];
   my $cmdTimeS = $_[3]; 
   if($paramR eq "NI") { # if parameter to write is a Node Identifier string don't pack it to binary format
      print "\nNI write destLR=$destLR, paramR=$paramR, IOvalueR=$IOvalueR, cmdTimeS=$cmdTimeS, IOvalueBinR=$IOvalueR \n";
      my $at_frame_id = $api->remote_at( { sh =>$destH, sl =>$destLR , na => $netID , apply_changes => '1'}, $paramR,$IOvalueR); 
   }else{ # if any other command string. No seat belts here. 
      my $IOvalueBinR = pack("N",$IOvalueR); # was h but changed to get SP time converted to binary value
      print "destLR=$destLR, paramR=$paramR, IOvalueR=$IOvalueR, cmdTimeS=$cmdTimeS, IOvalueBinR=$IOvalueBinR \n";
      my $at_frame_id = $api->remote_at( {sh =>$destH, sl =>$destLR, na => $netID,apply_changes => '1'},$paramR,$IOvalueBinR); 
   }
   if (defined($at_frame_id)){ # if command was a remote_at command which should return an at_frame_id
      $frameIDcmdTime{$at_frame_id} = $cmdTimeS; 
      # save the frame ID=>cmdTime association in this hash for when a 151 response comes back later.
      # actually seldom if ever used because response always comes back by the next packet read.
      $CAtime=localtime(time);
      print "Command sent to Remote Modem $destLR on Network $netID, parameter $paramR set to $IOvalueR  at $CAtime cmdTime = $cmdTimeS \n";
      return $at_frame_id; 
   }else{ 
      print "remote_at() API call failed" unless $at_frame_id;
      return ;
   }
   # Receive the reply later Not here, will block for too long. Get response in Wake Read Loop
} # end writeXBremoteParam() function implementation

#*********** Send a TX Request with parameter:value pair to arduino on a remote node
#    Takes 4 parameters $destL,$ardParam,$ardValue,$cmdTime     

sub sendToArduino()  {
  # takes node low part of serial number sl,  arduino command or parameter like 'pinPD6' and a value for Command/Parmeter
  # Super Simple Commands as entered into cs3Control.cgi and as sent from Gateway to Arduino  2/7/14 M.H. 
  #   Port:Function:value;value;value  for consistency with Alan's data packet format.       
  #   Example:  a4:1;100    Enter Command(-a4) Value(100)   set arduino pin 4 to OUTPUT mode then HIGH for 100 seconds, then LOW.  

   # execute a tx() XBee::API call to send the arduino command or parmeter and its value to a remote XBee.
   my $destLA = $_[0];
   my $ardParam = $_[1]; 
   my $ardValue = $_[2];
   my $cmdTimeA = $_[3]; 
   if ( my $ardWriteStatus = $api->tx( { sh =>$destH, sl =>$destLA , na => $netID }, $ardParam.":".$ardValue)) {
      print "\nSent TX Request; command: $ardParam  value: $ardValue  commandTime = $cmdTimeA to $destLA on $netID \n";
      # Expecting transmit status type 139 packet later, will send command_response to server when it comes in.  
      return "TRUE";   
   }else{
     print "Tx request didn't return true";
     return "";
   }
} #end sub sendToArduino() 

#*****************************************************************************
# getPortName(string, index) takes a type 144-1 packet string and a 
# character index and returns the first portName that it finds after the index
# and the character position of the delimiter after the portName
#*****************************************************************************
sub getPortName {
   my $content=$_[0]; # The raw string is here.  
   my $index=$_[1];# location to start searching from
   my $pos1=0;# position of first & found
   my $pos2=0;# position of first : found after first & found 
   if ($index <= 4 ) { $index = 4;} # avoid capturing packet count if caller uses too small an index.
   #my $subString = substr($content,$index);
   my $portName;
   my @retList;
   #print "Substring in which to find next portName = $subString \n"; 
   # find the first &
   $pos1 = index($content,"&",$index)+1; #characters skipped over to location of first &
   #print "Position of first & = $pos1\n";
   if($pos1==(-1)){  #if no & found return null portName and pos = -1 
      return @retList = ("", -1);
   }   
   $pos2 = index($content,":",($pos1)); #characters skipped over to location of second :,& or null
   if($pos2 == -1) {  #if no : found after the & packet has format error
      print "Packet format error, no : after portName\n";
      return @retList = ("formatError", -1); 
   }else{  # portName string terminated properly with a : 
      $portName = substr($content,$pos1,($pos2-$pos1)); # get portName string between delimiters
      #print "portName terminated with : = $portName\n";
      return @retList = ($portName,$pos2);    
   }
} # end sub getPortName()
#*****************************************************************************
# getPortName2(string, index) takes a type 144-50 port config sub string 
# and returns the portName which ends with a ;
#*****************************************************************************
sub getPortName2 {
   my $content=$_[0]; # The raw string is here.  
   my $index=0;# location to start searching from
   my $pos1=0;# position of first & found, should be no &s in these strings.
   my $pos2=0;# position of first : found after first & found 
   my $portName;
   my @retList;
   #print "String in which to find port name (getPortName2) $content\n";
   $pos2 = index($content,";",($pos1)); #characters skipped over to location of ;
   if($pos2 == -1) {  #if no ; found after the & packet has format error
      print "Packet format error, no ; after portName in config packet\n";
      return @retList = ("formatError"); 
   }else{  # portName string terminated properly with a ; 
      $portName = substr($content,$pos1,($pos2-$pos1)); # get portName string from begin to ;
      #print "portName terminated with ; = $portName\n";
      return $portName;    
   }
} # end sub getPortName2()

#*****************************************************************************
# getPortConfigStr(composite config String, position to start looking)
# returns port string between &s and position of trailing & or -1 if none.
#*****************************************************************************

sub getPortConfigStr {
   my $content=$_[0]; # The raw string is here.  
   my $index=$_[1];# location to start searching from
   my $pos1=0;# position of first &pr found
   my $pos2=0;# position of first & found after first &pr found 
   my $subString = substr($content,$index);
   my $portConfig; # port configuration string to be extracted
   my @retList;
   #print "Substring in which to find next portConfig = $subString \n"; 
   # find the first &pr
   $pos1 = index($content,"&pr",$index)+1; #characters skipped over to location of first &pr
   #print "Position of first &pr = $pos1\n";
   if($pos1==(-1)){  #if no &pr found return null $portConfig and pos = -1 no portConfig found.
      return @retList = ("", -1);
   }   
   $pos2 = index($content,"&pr",$pos1); #characters skipped over to location of second &pr or null
   if($pos2 == -1) {  #if no &pr found after the first &pr this is the last portConfig string.
      #print "Getting last portConfig in this packet\n";
      $portConfig = substr($content,$pos1+3,); # get remainder of portconfig string
      #print "Last portConfig String extracted = $portConfig\n";
      return @retList = ($portConfig, -1); 
   }else{  # portConfig string terminated with an &pr 
      $portConfig = substr($content,$pos1+3,($pos2-$pos1-3)); # get portconfig string between delimiters
      #print "portConfig String extracted = $portConfig\n";
      return @retList = ($portConfig,$pos2); # still more port config's left to parse out.   
   }
}
#*****************************************************************************
# getPacketNumber (string) takes a type 144-1 packet string 
# and returns the Packet Number that it finds 
# and the character position of the delimiter after the Packet Number
#*****************************************************************************
sub getPacketNumber {
   my $content=$_[0]; # The raw string is here.  
   my $pos1=0;# position of first & found
   my $pos2=0;# position of first & found after first & found 
   my $packetNum;
   my @retList;
   #print "String in which to find the packetNumber = $content \n"; 
   # find the first &
   $pos1 = index($content,"&",0); #characters skipped over to location of first &
   #print "Position of first & = $pos1\n";
   if($pos1==(-1)){  #if no & found return null packetNum and pos = -1 
      return @retList = ("", -1);
   }   
   $pos2 = index($content,"&",($pos1+1)); #characters skipped over to location of second & or null
   #print "Position of second & = $pos2\n";
   if($pos2 == -1) {  #if no & found after the first & packet has format error
      #print "Packet format error, no & after packetType\n";
      return @retList = ("formatError", -1); 
   }else{  # packetNum string terminated properly with an & 
      $packetNum = substr($content,$pos1+1,($pos2-$pos1-1)); # get packetNum string between delimiters
      #print "Packet Number = $packetNum\n";
      return @retList = ($packetNum,$pos2-1);    
   }
} # end sub getPacketNumber()

#*****************************************************************************
# getSensorValue(string, index) takes a type 144-1 packet string and a 
# character index and returns the first sensorValue that it finds after the index
# and the character position of the last character in the value found or null. 
# it will only find values after a :  If the pointer is pointing to the first 
# character of a value that value will not be returned. 
# This function needs to send back the position to start parsing for the next value 
#*****************************************************************************
sub getSensorValue {
   my $content=$_[0]; # The raw string is here.  
   my $index=$_[1];# location to start searching from
   my $pos1=0;# position of first : found
   my $pos2=0;# position of second : found or & or no character found.(value terminator)
   my $pos3=0;# position of next & if there is one.   
   my $subString = substr($content,$index);
   my $sValue;
   my @retList;
   #print "Substring after position $index in which to find next sValue = $subString \n"; 
   # find the first :
   $pos1 = index($content,":",$index)+1; #index of the first character after the colon
   #print "Position of first : = $pos1\n";
   if($pos1==(-1)){  #if no : found return null sValue and pos = -1 
      return @retList = ("", -1);
   }   
   $pos2 = index($content,":",$pos1); #index  of second :,& or null
   $pos3 = index($content,"&",$pos1); #index of next &
     # skips over & and gets : of next port's sensor value.  
     # need to find position of next & and see which occurs first
   if ($pos3 != -1 && $pos3 < $pos2) { $pos2 = $pos3; } 
     # cut substring to whichever delimiter occurs first.  
   #if($pos2 == -1) {  #if no : found look for &
   #   $pos2 = index($content,"&",($pos1));
      #print "Position of second : or & = $pos2\n";
   #}
   if ($pos2 == -1) { # string ended after this sValue
      $sValue = substr($content, $pos1); # get the rest of the string
      #print "sValue is last value in the payload = $sValue\n";
   }else{  # sValue string terminated with a : or &
      $sValue = substr($content,$pos1,($pos2-$pos1)); # get sValue string between delimiters
   }
   #print "sValue returned = $sValue\n";
   return @retList = ($sValue,$pos2);    
}

#******************************************************************
# getValue() takes an XML Packet string and the name of a 
# parameter and returns the 
# Value of the first instance of that parameter 
# gets parameters that are not after a <ConvertedValue> tag such as NodeId and Port
# if the packet contains it else it returns undef.  5/19/11 M.H. 
# <Name>soilMoisture</Name><ConvertedValue>6.688895    not this string
# <nodeId>11.000000</nodeId><Port>4.000000</Port>      this one
#*******************************************************************
sub getValue {
   my $content=$_[0]; # The raw string is here.  
   my $name=$_[1];# Name of the parameter whose value is desired
   my $pos1=0; 
   my $pos2=0; 
   #print $name;
   $pos1=index($content,"<".$name.">",0); #index to start of <param name>
   #print $pos1;
   if($pos1==(-1)){
      return "";
   }
   # index to the ">" to the right of the parameter name
   $pos2=index($content,">",$pos1);
   #print $pos2; 
   if($pos2==(-1)){
      return "";
   }
   $pos1=$pos2 + 1; #pos1 now points to first char of the value.
   $content=substr($content,$pos1); # cut off string up to pos1
   #print $content;
   $pos2=index($content,"<",0); #char after value
   #print $pos2;
   if($pos2==(-1)){
      return "";
   }
   my $Cval=substr($content,0,$pos2);
   #print "\n $name = $Cval";
   return ($Cval);
} # end sub getValue()

#**********************  Test to see if a table already exists *******************************
sub tableExists {  # takes two parameters, database handle and  tablename string 
   #print "Checking for table $_[1] \n";
   my @tableNames = $_[0]->tables("main", '%', "$_[1]" ,"TABLE")
            or print "table $_[1] doesn't exist yet " .$_[0]->errstr."\n";
   #print "Checked for table $_[1] \n";
   if (@tableNames) {
      print "Table $_[1] exists; ";
      return 1;
   } # end if
} # end sub tableExists() 

#********************* Replace a string with another string within a larger string ***********
#  Takes a large string a string to be replaced and the string to replace it with 
#  
sub replaceSubstr {
   $string = $_[0];
   $oldString = $_[1];
   $newString = $_[2];
   my $modifiedString = $string;
   $modifiedString =~ s/$oldString/$newString/g;
   #print "Initial String = $string \n Revised String = $modifiedString \n";
   return $modifiedString;
} 

#*********************** LEFTOVERS **********************************************************************
#It is desirable to sync the gateway code to the sleep cycle of the network for efficiency of communication.  I do all my transmissions to the base radio module and queries for commands from the cloud between the end of the wake cycle and when the base radio module "powers down" 40 seconds later according to Bob's characterization.   I do all my receptions during the wake cycle.  currently I try to process the packets during the wake cycle which may use up too much of the wake cycle when i could be receiving more packets.
# So far not a problem. M.H. 6/29/13

# Get Temp and Vcc data from whichever nodeID is specified. 
# This is here because the temp and Vcc data is totally uninformative.  
# Temp values range from 0x1b 27C to 0x1d 29C independent of ambient temp 
# VCC values are all regulated supply values 3.3V +/-50mV. 

   #    $pkID{'node'}= 1084569569; #1084569495; #1084569465; #1084569541; # 1084569465;1084569495
   #    my $remoteVcc = getXBremoteParam($netID, $pkID{'node'},"%V");
   #    print "Remote node ($pkID{'node'} Vcc = $remoteVcc \n"; # voltage in millivolts. 
   #   my $urlString = ($remoteService."?packetType="."data"."&netID=".$pkID{'net'}."&nodeID=".$pkID{'node'}."&port=".$pkID{'port'}."&sensorType="."0"."&atTime=".$unixTime);
   #    $urlString =($urlString.'&'.'intVcc'.'='.$remoteVcc);  
   #    #getprint($urlString);
   #    my $remoteTemp = getXBremoteParam($netID, $pkID{'node'},"TP"); # temp in degrees F
   #    print "Remote node ($pkID{'node'}) Internal temperature = $remoteTemp F\n";  
   #    $urlString =($urlString.'&'.'intTemp'.'='.$remoteTemp);  
   #    getprint($urlString);


#my @drivers = DBI->available_drivers;  # check to see which database drivers are available 
#foreach $DBIdriver (@drivers) {
#   print  "driver  $DBIdriver \n";
#}

#********* Partial API Command list for reference *******************************************
#
#   ID Network ID     Network ID is normally specified in HEX 
#   NI Node Identifier  This is the user assigned name for a node must read =>data not =>data_as_int
#   SM Sleep Mode 
#   ST Sleep Time  
#   SL Serial number Low 32 bits   
#   AC Apply Changes, use this when you want to change many parameters simultaneously
#   D0 Read or set configuration of DIO0  usually 2 for analog input
#   P2 Read or set configuration of DIO12 usually 4 or 5 for 0V out or 3.3V out respectively.
#   MS Missing Syncs. Since last time this parameter was polled I believe.  
#
#*****************************************************************************************************

# Notes on how to commission a new network. 
# Later every network and node will be shipped with the same Network ID.  When the user 
# first sets up his network it will contact Camalie Networks to get a unique network ID.  
# at which point the CS3 gateway will configure its base radio and all nodes to use that ID. 
# When a new node is later added to the network it will initially be configured to the default
# network ID.  The user will then initiate an add node event in the remote server U.I. which
# will cause the CS3 gateway to reconfigure its base radio to the default network ID long enough 
# to configure the new node to the local Network ID.  At this point the gateway radio will 
# switch back to its assigned network ID. Later manage the radio channel as well. 

# Need to functionalize all of the API error checking.  Two many lines per API call. 

#********** Destination Remote Node Parameters  **************************

# Get other diagnostic data:  
#	ER   RF errors  frequency of corrupted packets
#       GD   Good packets received
#       TR   Transmission Errors
#       TP   Module Temperature in degrees Celcius.  Can be negative. 
#       DB   Received RSSI signal strength of last incoming packet. 
#       DN   Use to get 64 bit address of a node given a node Identifier.  Check to see if a node is present with a specific NI.

 	  # Hash contents for one example packet returned in response to a Network Discovery Command 
          #"api_data" => "DND\0\377\376\0\23\242\0\@\230\31iNNODE14\0\377\376\1\0\301\5\20\36",
          #"is_invalid_command" => "",
          #"is_error" => "",
          #"frame_id" => 68,
          #"status" => 0,
          #"my" => 65534,
          #"sl" => "1083709801",
          #"device_type" => 1,
          #"manufacturer_id" => 4126,
          #"sh" => 1286656,
          #"ni" => "NNODE14",
          #"command" => "ND",
          #"profile_id" => 49413,
          #"api_type" => 136,
          #"source_event" => 0,
          #"data" => "\377\376\0\23\242\0\@\230\31iNNODE14\0\377\376\1\0\301\5\20\36",
          #"is_ok" => 1,
          #"is_invalid_parameter" => "",
          #"parent_network_address" => 65534,
          #"na" => 65534

# Packet type 144 packet from terraduino with internal data 
#$VAR1 = {
#          "api_data" => "\0\23\242\0\@\246mv\377\376\301\0\0\b\0\0\377\6\224\20n\4w6",
#          "options" => 193,
#          "api_type" => 144,
#          "data" => "\0\0\b\0\0\377\6\224\20n\4w6",
#          "is_ack" => 1,
#          "sl" => "1084648822",
#          "sh" => 1286656,
#          "na" => 65534,
#          "is_broadcast" => 0
#        };
#
# Proposed type 144 packet payload format with ascii http like delimiters  M.H. 12/26/13  3 example packets
#
# &SS=65280&vBatt=4.12&vBatt_u=V&vSolar=.25&vExt=5.0&time=13894563
# &SS=1&sType=Watermark1&SMT=145&SMT_u=cbar&time=1389456710
# &SS=2&sType=Thrm036&Temp=65&Temp_u=dF&time=1389456812


           

         # If configuration meta data is available do the following
         # Use a hash of hashes where the lower hash is parameter->value pairs and top is portName->sensorHash
             # sensor hash should also have a sensortype key in it 
         # Parse arduino data payload here.
         # while index points to an &
            # Parse out the port, between & and first :
            # while data value is between : and : or : and null
		#Parse out data value, 
		#Get key/name from port config table  
		#put data in hash at key
                #set parse pointer index to the char after value, will be pointing at :,; or null 
            # if pointing at : continue
            # put sensorHash into hash at portName key
         # if pointing at & continue  
       #Read through upper level hash and push one http packet per sensorHash.

 
         #my $packetNumber = unpack("S",substr($rxMs->{'data'},2,2));# S worked
         #my $internalSensorID = unpack("n" ,substr($rxMs->{'data'},4,2)); # should always be 0xff00
         #my $vBatt = unpack("S",substr($rxMs->{'data'},7,2));# get the voltages out of the packet
         #my $vSolar = unpack("S", substr($rxMs->{'data'},9,2));
         #my $vExt = unpack("S", substr($rxMs->{'data'},11,2));
         #print "Terraduino Vbatt = $vBatt VSolar = $vSolar VExt = $vExt Sensor ID = $internalSensorID  packetNumber= $packetNumber\n";

 
