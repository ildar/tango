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
      client.tab1 = {}
      client.tab1.name = 'John'
      assert.equal( 'John', client.tab1.name )
    end)

  it("can be passed as an argument",
     function()
       client.a1 = {"a","b"}
       local a1_str = client.table.concat(client.a1)
       assert.equals("ab", a1_str)
     end)

  it("can be passed as double arguments",
     function()
       client.a1 = {"a","b"}
       client.a2 = {"c","d"}
       client.table.move(client.a1, 1, 2, 3, client.a2)
       local a2_str = client.table.concat(client.a2)
       assert.equals("cdab", a2_str)
     end)

  it("can be used as objects",
     function()
       local pref = client.io.popen('echo hello')
       local match = pref:read('*a'):find('hello')
       pref:close()
       assert.truthy(match)
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
