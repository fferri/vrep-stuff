getPCL=function(visSensorHandle,data,maxDist)
    local r=0
    local t1={}
    local u1={}
    r,t1,u1=simReadVisionSensor(visSensorHandle) -- discard first reading
    r,t1,u1=simReadVisionSensor(visSensorHandle)
    local m1=simGetObjectMatrix(visSensorHandle,-1)
    if u1 then
        for j=0,u1[2]-1,1 do
            for i=0,u1[1]-1,1 do
                local w=2+4*(j*u1[1]+i)
                if u1[w+4]<(maxDist*0.9999) then
                    local p={u1[w+1],u1[w+2],u1[w+3]}
                    p=simMultiplyVector(m1,p)
                    for h=1,3,1 do table.insert(data,p[h]) end
                end
            end
        end
    end
    return data
end
