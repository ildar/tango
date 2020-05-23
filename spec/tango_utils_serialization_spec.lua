local serialization_mod = require'tango.utils.serialization'
local serialize = serialization_mod.serialize
local unserialize = serialization_mod.unserialize

describe("Serialization module", function()
    it("can s-ze simple types", function()
        assert.equal("{true}", serialize( {true} ))
        assert.equal("{42}", serialize( {42} ))
        assert.equal('{"a quick brown fox"}', serialize( {"a quick brown fox"} ))
      end)
    it("can s-ze an array", function()
        assert.equal('{true,42,"a quick brown fox"}',
          serialize( {true, 42, "a quick brown fox"} ))
      end)
--[[
    pending("can s-ze a record. Hard to test as the fields order isn't stable", function()
        assert.equal('{boo=true,num=42,str="a quick brown fox"}',
          serialize( {boo=true, str="a quick brown fox", num=42} ))
      end)
]]
    it("can s-ze nested tables", function()
        assert.equal('{{1},{{2}},{{{3}}}}',
          serialize( { {1}, {{2}}, {{{3}}} } ))
      end)
    it("can uns-ze an array", function()
        local arr = {true, 42, "a quick brown fox"}
        local arr1 = unserialize(serialize( arr ))
        for k,_ in ipairs(arr) do
          assert.equal(arr[k], arr1[k])
        end
      end)
  
    it("can handle problematic strings",
    function()
      local s1,ss1
      s1 = "s1 contains \',\",\\, ok?"
      ss1 = serialize({s1})
      assert.truthy( ss1 and (#ss1>0) )
      assert.is_equal( s1, unserialize(ss1)[1] )
      s1 = "s1 contains newlines,\nok?"
      ss1 = serialize({s1})
      assert.truthy( ss1 and (#ss1>0) )
      assert.is_equal( s1, unserialize(ss1)[1] )
      s1 = "s1 contains non-latin chars (аәбвгғ), ok?"
      ss1 = serialize({s1})
      assert.truthy( ss1 and (#ss1>0) )
      assert.is_equal( s1, unserialize(ss1)[1] )
      s1 = "s1 contains null chars (\0), ok?"
      ss1 = serialize({s1})
      assert.truthy( ss1 and (#ss1>0) )
      assert.is_equal( s1, unserialize(ss1)[1] )
      
      s1 = string.dump(function() return 33 end) -- this is truly problematic string
      ss1 = serialize({s1})
      assert.truthy( ss1 and (#ss1>0) )
      local unss1 = unserialize(ss1)[1]
      assert.is_equal( s1:len(), unss1:len() )
      for i=1,#s1 do
        assert.is_equal( s1:byte(i), unss1:byte(i) )
      end
      assert.is_equal( s1, unss1 )
    end)

  end)
