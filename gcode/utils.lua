function asserttype(x,t,name)
    assert(type(x)==t,name..' must be a '..t)
end

function assertnumber(x,name)
    asserttype(x,'number',name)
end

function assertstring(x,name)
    asserttype(x,'string',name)
end

function asserttable(x,name,size,subtype)
    asserttype(x,'table',name)
    if size~=nil then assert(#x==size,name..'\'s size must be '..size) end
    if subtype~=nil then for i=1,#x do asserttype(x[i],subtype,name..'\'s element') end end
end

function assertmember(x,X,name)
    asserttable(X,'X',nil,type(x))
    for i=1,#X do if x==X[i] then return end end
    assert(false,name..' must be one of '..table_join(X,', '))
end

function table.val_to_str(v)
    if "string"==type(v) then
        v=string.gsub(v,"\n","\\n")
        if string.match(string.gsub(v,"[^'\"]",""),'^"+$') then
            return "'"..v.."'"
        end
        return '"'..string.gsub(v,'"','\\"')..'"'
    else
        return "table"==type(v) and table.tostring(v) or tostring(v)
    end
end

function table.key_to_str(k)
    if "string"==type(k) and string.match(k,"^[_%a][_%a%d]*$") then
        return k
    else
        return "["..table.val_to_str(k).."]"
    end
end

function table.tostring(tbl)
    local result,done={},{}
    for k,v in ipairs(tbl) do
        table.insert(result,table.val_to_str(v))
        done[k]=true
    end
    for k,v in pairs(tbl) do
        if not done[k] then
            table.insert(result, table.key_to_str(k).."="..table.val_to_str(v))
        end
    end
    return "{"..table.concat(result,",").."}"
end

function math.hypotn(a,b)
    asserttable(a,'a',nil,'number')
    asserttable(b,'b',#a,'number')
    local d=0
    for i=1,#a do d=d+math.pow(a[i]-b[i],2) end
    return math.sqrt(d)
end

function string.formatex(fmt,...)
    local arg1={}
    for i,v in ipairs(arg) do
        arg1[i]=(type(v)=='table' and table.val_to_str(v) or v)
    end
    return string.format(fmt,unpack(arg1))
end

function string.split(s,pat)
    local fields={}
    local function helper(field) table.insert(fields,field) return '' end
    helper((s:gsub(pat,helper)))
    return fields
end

function string.splitlines(s)
    return string.split(s,"(.-)\r?\n")
end

