local assert = assert
local tinsert = table.insert
local tconcat = table.concat
local tremove = table.remove
local smatch = string.match
local sgsub = string.gsub
local ipairs = ipairs
local pairs = pairs
local type = type
local tostring = tostring
local tonumber = tonumber
local loadstring = loadstring
local print = print

--- The default tango serialization module.
-- Uses table serialization from http://lua-users.org/wiki/TableUtils and loadstring for unserialize.
module('tango.utils.serialization')

serialize = nil

local converters = {
  string = function(v)
             v = sgsub(v,'["\\]','\\%0')
             v = sgsub(v,"\n","\\n")
             v = sgsub(v,"\r","\\r")
             v = sgsub(v,"%z","\\000")
             return '"' .. v .. '"'
           end,
  table = function(v)
            return serialize(v)
          end,
  number = function(v)
             return tostring(v)
           end,
  boolean = function(v)
              return tostring(v)
            end
}

local valtostr = 
  function(v)
    local conv = converters[type(v)]
    if conv then
      return conv(v)
    else
      return 'nil'
    end
  end

local keytostr = 
  function(k)
    if 'string' == type(k) and smatch(k,"^[_%a][_%a%d]*$") then
      return k
    else
      return '['..valtostr(k)..']'
    end
  end

serialize = 
  function(tbl)
    local result,done = {},{}
    for k,v in ipairs(tbl) do
      tinsert(result,valtostr(v))
      done[k] = true
    end
    for k,v in pairs(tbl) do
      if not done[k] then
        tinsert(result,keytostr(k)..'='..valtostr(v))
      end
    end
    return '{'..tconcat(result,',')..'}'
  end

unserialize = 
  function(strtab)
    local fn = loadstring('return '..strtab)
    assert(fn, "unserialize(): loadstring failed")
    local res = fn()
    assert(type(res) == "table", "unserialize(): got non-table")
    return res
  end

return {
  serialize = serialize,
  unserialize = unserialize
}
