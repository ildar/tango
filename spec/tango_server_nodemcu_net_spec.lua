local tsnn_module = require "tango.server.nodemcu.net"

describe("tango.server.nodemcu.net module", function ()
    it("should be able to receive some trivial data", function ()
        local testchunk = "10\n0123456789"
        -- tsnn_module.onreceive(conn, testchunk)
        error("fail")
      end)
end)
