About
=======

tango is small, rather simple and customizable rpc package for Lua.
Calling remote functions is fully transparent and makes syntactically
no difference to local calls. Remote errors are also forwarded.
tango does not imply any certain io / event model. Instead tango provides
different backends for common io / event modules. The table
serialization can be customized as well.

tango supports 1-1 remote calls (send request,receive response) as
well as 1-N notifications (send request, NO reponse).

Backends included
---------------------

* copas  
* [lua-zmq](https://github.com/Neopallium/lua-zmq)
* [lua-ev](https://github.com/brimworks/lua-ev)

Example (with copas backend)
--------------------------------
The greet server code 

      require'tango.copas'
      greet = function(...)
                print(...)
              end         
      tango.copas.serve()


The client code calling the remote server function 'greet'

      require'tango.copas'
      local proxy = tango.copas.client('localhost')
      proxy.greet('Hello','Horst')

Since the server exposes the global table _G per default, the client may even
directly call print and let the server sleep a bit remotely.

      proxy.print('I','call','print','myself')         
      proxy.os.execute('sleep 1')

Serialization
-------------
tango provides a default (lua-only) table serialization which ...well,
just works.

Anyhow, the table serialization is neither exceedingly fast nor
compact in output. If this is a problem for your application, you can
customize the serialization by overwriting tango.serialize and
tango.unserialize appropriate. E.g. with lua-marshal methods table.marshal and table.unmarshal respectively
(from the [lua-marshal](https://github.com/richardhundt/lua-marshal))

      require'tango'
      require'marshal'

      tango.serialize = table.marshal  
      tango.unserialize = table.unmarshal  

Requirements
------------

Either of the supported event/io backends. If your backend is
currently not supported, just write your own :)

The most common socket/io combination might be luasocket+copas.

To install use apt

      $ sudo apt-get install liblua5.1-socket2
      $ sudo apt-get install liblua5.1-copas0


or LuaRocks

      $ sudo luarocks install luasocket
      $ sudo luarocks install copas

Installation
-------------
With LuaRocks > 2.0.4.1:

     $ sudo luarocks install https://raw.github.com/lipp/tango/multi-backend/tango-0.1-0.rockspec

Note: luarocks require lua-sec for doing https requests.
Install with apt

     $ sudo apt-get install liblua5.1-sec1

or LuaRocks

     $ sudo luarocks install luasec