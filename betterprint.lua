function is_array(t)
    local i = 0
    for _ in pairs(t) do
        i = i + 1
        if t[i] == nil then return false end
    end
    return true
end

function table_tostring(tt, indent)
	indent = indent or 0
	if type(tt) == 'table' then
		local sb = {}
        if is_array(tt) then
            table.insert(sb, '{')
            for i = 1, #tt do
                table.insert(sb, any_tostring(tt[i], indent))
                if i < #tt then table.insert(sb, ', ') end
            end
            table.insert(sb, '}')
        else
            table.insert(sb, '{\n')
            for key, value in pairs(tt) do
                table.insert(sb, string.rep(' ', indent+4))
                table.insert(sb, tostring(key))
                table.insert(sb, '=')
                table.insert(sb, any_tostring(value, indent+4))
                table.insert(sb, ',\n')
            end
            table.insert(sb, string.rep(' ', indent))
            table.insert(sb, '}')
        end
        return table.concat(sb)
    else
        return any_tostring(tt, indent)
    end
end

function any_tostring(x, tblindent)
    local tblindent = tblindent or 0
    if 'nil' == type(x) then
        return tostring(nil)
    elseif 'table' == type(x) then
        return table_tostring(x, tblindent)
    elseif 'string' == type(x) then
        return string.format('"%s"', x)
    else
        return tostring(x)
    end
end

orig_print=print
function print(x)
    orig_print(type(x) == 'table' and table_tostring(x) or x)
end

print('aaa')
print(199)
print({1,2,3})
print({f=1,g=2,h={a=100,b=200,z={1,2,3},s='hello'}})

function printf(fmt,...)
    local a={...}
    for i=1,#a do
        if type(a[i])=='table' then
            a[i]=any_tostring(a[i])
        end
    end
    print(string.format(fmt,unpack(a)))
end

printf('pi is %.3f, tbl is %s', math.pi, {1,2,f={a=1,b=2}})

