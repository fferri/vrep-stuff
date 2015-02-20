simGetObjectSpecialPropertyBit=function(h,p)
    return simGetObjectSpecialProperty(h) % (p + p) >= p
end
simSetObjectSpecialPropertyBit=function(h,p)
    local x = simGetObjectSpecialProperty(h)
    x = simGetObjectSpecialPropertyBit(h,p) and x or x + p
    simSetObjectSpecialProperty(h,x)
end
simClearObjectSpecialPropertyBit=function(h,p)
    local x = simGetObjectSpecialProperty(h)
    x = simGetObjectSpecialPropertyBit(h,p) and x - p or x
    simSetObjectSpecialProperty(h,x)
end
