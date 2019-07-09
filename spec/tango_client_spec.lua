#TODO: add more backends
local server_backend = "copas_socket"
local client_backend = "socket"
local option = nil

local tango = require'tango'
local config = {}
if option then
  if option == 'ssl' then
    config.sslparams = require'test_ssl_config'.client
  end
end

local connect = tango.client[client_backend].connect

local spawn_server = 
  function(backend,access_str)
    local cmd = [[
        lua5.1 test_server.lua %s %s %s &
        echo $!            
    ]]
    cmd = cmd:format(backend,access_str,option or '')
    local process = io.popen(cmd)
    local pid = process:read()
    if backend ~= 'zmq' then
      os.execute('sleep 1')
    end
    return {
      process = process,
      pid = pid,
      kill = function()
               os.execute('kill '..pid)
             end
    }
  end

print('==============================')
print('running tests with:')
print('server backend:',server_backend)
print('client backend:',client_backend)
if option then
  print('option:',option)
end
print('------------------------------')

describe("Tests the client side of Tango moodule (rw cases)", function()
  setup(function()
      server = spawn_server(server_backend,'rw')
      client = connect(config)
    end)
  teardown(function()
      server:kill()
    end)

  it("can run `add` remotely",
     function()
       assert.is_equal( 3, client.add(1,2) )
     end)

  it("can run `echo` remotely",
     function()
       local tab = {number=444,name='horst',bool=true}
       local tab2 = client.echo(tab)
       assert.is_equal( tab.number, tab2.number )
       assert.is_equal( tab.name, tab2.name )
       assert.is_equal( tab.bool, tab2.bool )
     end)

  it("can return multiple values",
     function()
       local a,b,c = 1.234,true,{el=11}
       local a2,b2,c2 = client.echo(a,b,c)
       assert.is_equal( a, a2 )
       assert.is_equal( b, b2 )
       assert.is_equal( c.el, c2.el )
     end)

  it("can do string error",
     function()
       local status,msg = pcall(function()client.strerror()end)
       assert.is_equal( false, status )
       assert.is_equal( 'string', type(msg) )
       assert.is.truthy( msg:find('testmessage') )
     end)

  it("can do custom error",
     function()
       local errtab = {code=117}
       local status,errtab2 = pcall(function()client.customerror(errtab)end)
       assert.is_equal( false, status )
       assert.is_equal( 'table', type(errtab2) )
       assert.is_equal( errtab2.code, errtab.code )
     end)

  it("can nested method name",
     function()
       assert.is_equal( true, client.nested.method.name() )
     end)

  it("can tango.ref with io.popen",
     function()
       local pref = tango.ref(client.io.popen,'echo hello')
       local match = pref:read('*a'):find('hello')
       pref:close()
       tango.unref(pref)
       assert.is.truthy( match )
     end)

  it("can tango.ref with person",
     function()
       local pref = tango.ref(client.person,'horst')
       pref:name('peter')
       local match = pref:name() == 'peter'
       tango.unref(pref)
       assert.is.truthy( match )
     end)

  it("should create and access variables with number",
     function()
       client.x(4)
       assert.is_equal( 4, client.x() )
       assert.is_equal( 8, client.double_x() )
     end)

  it("should create and access variables with tables",
     function()
       client.abc({sub='horst',tab={}})
       client.abc.tab.num(1234)
       local abc = client.abc()
       assert.is_equal( 'table', type(abc) )
       assert.is_equal( 'horst', abc.sub )
       assert.is_equal( 1234, abc.tab.num )
     end)

  it("should accessing not existing tables to cause error",
     function()
       local ok,err = pcall(
         function()
           client.horst.dieter()
         end)
       assert.is_equal( false, ok )
       assert.is.truthy( err:find('horst.dieter') )
     end)
end)

describe("Tests the client side of Tango moodule (ro cases)", function()
  setup(function()
      server = spawn_server(server_backend,'r')
      client = connect(config)
    end)
  teardown(function()
      server:kill()
    end)
  it("can read remote variable",
     function()         
       local d = client.data()
       assert.is_equal( 0, d.x )
       assert.is_equal( 3, d.y )
     end)

  it("writing remote variable should cause a error",
     function()
       local ok,err = pcall(
         function()
           client.data(33)
         end)
       assert.is_equal( false, ok )
     end)
end)

describe("Tests the client side of Tango moodule (wo cases)", function()
  setup(function()
      server = spawn_server(server_backend,'w')
      client = connect(config)
    end)
  teardown(function()
      server:kill()
    end)
  it("reading remote variable should cause a error",
     function()
       local ok,err = pcall(
         function()
           client.data()
         end)
       assert.is_equal( false, ok )
     end)

  it("should successfully write remote variable",
     function()
       local ok,err = pcall(
         function()
           client.data(33)
         end)
       assert.is_equal( true, ok )
     end)
end)
