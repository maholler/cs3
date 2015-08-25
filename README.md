# cs3
The cs3 system is a low cost, scalable, open system, for monitoring and control of agricultural operations. 
It is easily constructed from low cost components off the shelf. 

The CS3 system consists of three major components:

    Field Stations - XBee Digimesh radio + arduino microcontroller
    Internet Gateway - Linux pcDuino running simple communication daemon. 
    Web Services - Grapher + Node Controls + Data Base of Sensor data/

The CS3 Field Stations have the sensors and/or actuators connected to them. They can be placed anywhere within 2 miles line of sight of the gateway or within 2 miles of another field station which has a path back to the gateway. The CS3 Internet gateway acts as a relay to pass data from field stations to a CS3 server or commands in the opposite direction. It requires no static IP address or firewall reconfiguration at the user's site or any cellular subscription. Just plug it in, turn on your nodes and go to the CS3 server access your data, and/or control whatever you have connected to your field stations.

Field Stations:

There are 3 different CS3 field station models, the Z, ZX, and Terraduino. They all use standard XBee 900HP 900MHz radio modules with DigiMesh self organizing mesh technology. The Z model is a basic model for data acquisition. The ZX model has an arduino compatible base board with a microcontroller, XBee radio, and solar power supply.

Thus, far the Z model has been used for well pump control, temp and soil moisture monitoring.  The ZX has been used for water metering, valve actuation, water level monitoring, remote data display, and GPS tracking of vehicles. The ZX node counts switch closures and reports switch position every 15 seconds. This function can be used for monitoring door/gate/window security as well as water metering. The GPS monitoring function is useful for keeping track of vehicles especially where cell coverage is incomplete and a record of paths needs to be saved. Nodes can be easily placed to cover hilly wooded terrain using a connectivity indicating LED visible on each node.

All of the field stations are powered by three NiMH batterys charged by a solar panel. Typical battery life with no sun is 3-6 weeks depending on sensors and interface card installed. Battery life with sun is typically 4 years.

The CS3-Terraduino Weather Station. Data is taken every 2 minutes and relayed back to a CS3 gateway and on to a webserver with a database where the data is immediately available for viewing via the internet with your favorite smart phone, tablet or PC. Here the Terraduino is shown with the industry standard Davis Weather station instrument package that it supports.  The Terraduino enclosure cover is shown removed to show the internal electronics and rechargeable batteries.

Gateway:

The gateway, is a cost effective Linux computer originally designed for use in smart phones and tablets. It has HDMI graphics output and 2 USB ports for keyboard, and mouse connections enabling its use as a desktop PC but, it usually ends up on a window sill somewhere near your internet router. It automatically reboots itself after power failures and internet outages.

Web Services:

The user interface of the CS3 system can be served by any Linux Server running Linux.  It uses RRDtools for database and graphing  and drraw.cgi for graph management.  .cgi PERL scripts are used to generate the remaining web pages including the control pages.  

Go to http://99.115.132.118/html/cs3prod.htm  for pictures of one instantiation of a cs3 system which is in commercial use for vineyard management. 

This open source site is in early stages of development.  I'm in the process of adding the latest code for all three of the components described above.  This code has been developed over 3 years starting in 2012 and is in production use at 4 sites. This code was put into open source in May of 2014.  It was developed in collaboration with  Professor Michael Delwiche's Biological and Agricultural Engineering Lab at UC Davis, particularly Bob Coates.  Alan Broad also made major contributions to the wireless network optimization and many sensor interfaces.   
