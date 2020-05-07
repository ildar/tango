-- #TODO: add more backends
local server_backend = "lgi_async"
local client_backend = "socket"
local option = nil

local tango = require 'tango'
local config = { address = os.getenv("TANGO_SERVER") }
if option then
  if option == 'ssl' then
    config.sslparams = require'test_ssl_config'.client
  end
end

local connect = tango.client[client_backend].connect
local server, client
local function spawn_server(backend,access_str)
  local cmd = [[
      lua test_server.lua %s %s %s &
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

-- Types of Lua passed by reference: tables, functions, userdata and threads
describe("Remote tables", function()
  setup(function()
      server = spawn_server(server_backend,'rw')
      client = connect(config)
    end)
  teardown(function()
      if server then
        server:kill()
      end
    end)

  it("can be created",
    function()
      client.tab1 ( {} )
      local l_tab1 = tango.ref(client.tab1)
      l_tab1.name = 'John'
      assert.equal( 'John', l_tab1.name )
      --[[
      l_tab1.surname( 'Doe' )
      assert.equal( 'Doe', l_tab1.surname )
      tango.unref(l_tab1)
      ]]
    end)

  pending("can be passed as an argument",
     function()
       client.a1 ( {"a","b"} )
       local l_a1 = tango.ref(client.a1)
       local a1_str = client.table.concat(l_a1)
       tango.unref(l_a1)
       assert.equals("ab", a1_str)
     end)

  pending("can be passed as double arguments",
     function()
       client.a1 ( {"a","b"} )
       local l_a1 = tango.ref(client.a1)
       client.a2 ( {"c","d"} )
       local l_a2 = tango.ref(client.a2)
       client.table.move(l_a1, 1, 2, 3, l_a2)
       local a2_str = client.table.concat(l_a2)
       tango.unref(l_a1) ; tango.unref(l_a2)
       assert.equals("cdab", a2_str)
     end)

end)

describe("Remote functions", function()
  setup(function()
      server = spawn_server(server_backend,'rw')
      client = connect(config)
    end)
  teardown(function()
      if server then
        server:kill()
      end
    end)

  it("can be stored and called", function()
    local rem_print = client.print
    -- rem_print("Hello, world!")
  end)

end)