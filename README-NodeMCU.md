Tango
=====

tango is a small, simple and customizable RPC (remote procedure call)
module for Lua.

It now can be run on ESP MCU-based NodeMCU firmware (just server, no client).
This opens opportunity to RPC from a PC to this MCU through the Wi-Fi
networking.

Quick start
===========

Quick plan:
1. Prepare the NodeMCU
2. Connect to Wi-Fi
3. Launch server on the NodeMCU
4. Test/run the client

Prepare the NodeMCU
-------------------

First you need the Tango code on the MCU. The easiest way is to upload files
to the SPIFFS, though options also available (the very good alternative would
be to use LFS).

So first upload the essential files to SPIFFS, e.g using ESPlorer. The files are:
1. tango/config.lua
2. tango/dispatcher.lua
3. tango/server/nodemcu/net.lua
4. tango/utils/serialization.lua
5. (optional) test_server_nodemcu.lua

If files uploaded without path (config.lua, dispatcher.lua, ...) then rename
them in-place:
1. config.lua → tango/config.lua
2. dispatcher.lua → tango/dispatcher.lua
3. net.lua →  tango/server/nodemcu/net.lua
4. serialization.lua → tango/utils/serialization.lua

Connect to Wi-Fi
----------------

You can use whichever way you like. The goal is to have NodeMCU and your PC
in one network so PC can connect to NodeMCU's TCP port.

Example script to run may be found [here](https://gist.github.com/ildar/38019d0e01b85df531e1b0f272a6f3e4)

Launch server on the NodeMCU
----------------------------

may be done with simple `dofile("test_server_nodemcu.lua")`
The main core part of it is:
> require "tango.server.nodemcu.net".new()

Test/run the client
-------------------

If you have `busted` framework you can run like this:
> TANGO_SERVER=10.42.0.22 busted --tags=BasicTests --exclude-tags=io

Otherwise use the sample script:
> TANGO_SERVER=10.42.0.22 lua5.1 test_client.lua copas_socket socket

The latter will fail on `io.popen` because NodeMCU obviously missing that.
But before that you'll see several OK-s which is (generally) the success.

