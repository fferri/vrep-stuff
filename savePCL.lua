savePCL=function(visSensorHandle,maxDist,fov,filename)
    maxDist=math.max(0.1,math.min(1000,maxDist))
    fov=math.max(0.017,math.min(2.37,fov))
    local oldFov=simGetObjectFloatParameter(visSensorHandle,1004)
    local oldMaxDist=simGetObjectFloatParameter(visSensorHandle,1001)
    simSetObjectFloatParameter(visSensorHandle,1001,maxDist)
    simSetObjectFloatParameter(visSensorHandle,1004,fov)
    local data={}
    local r=0
    local t1={}
    local u1={}
    r,t1,u1=simReadVisionSensor(visSensorHandle) -- discard first reading
    r,t1,u1=simReadVisionSensor(visSensorHandle)
    local o=simGetObjectPosition(visSensorHandle,-1)
    local q=simGetObjectQuaternion(visSensorHandle,-1)
    local m1=simGetObjectMatrix(visSensorHandle,-1)
    if u1 then
        for j=0,u1[2]-1,1 do
            for i=0,u1[1]-1,1 do
                local w=2+4*(j*u1[1]+i)
                local v1=u1[w+1]
                local v2=u1[w+2]
                local v3=u1[w+3]
                local v4=u1[w+4]
                if (v4<(maxDist*0.9999)) then
                    local p={v1,v2,v3}
                    p=simMultiplyVector(m1,p)
                    table.insert(data,p[1])
                    table.insert(data,p[2])
                    table.insert(data,p[3])
                end
            end
        end
    end
    local fprintf=function(f,fmt,...) f:write(string.format(fmt,...)) end
    if #data > 0 and not saved then
        local f,err=io.open(filename,'w')
        if not f then return print(err) end
        fprintf(f,'# .PCD v0.7 - Point Cloud Data file format\n')
        fprintf(f,'VERSION 0.7\n')
        fprintf(f,'FIELDS x y z\n')
        fprintf(f,'SIZE 4 4 4\n')
        fprintf(f,'TYPE F F F\n')
        fprintf(f,'COUNT 1 1 1\n')
        fprintf(f,'WIDTH %d\n',#data/3)
        fprintf(f,'HEIGHT 1\n')
        fprintf(f,'VIEWPOINT %f %f %f %f %f %f %f\n',o[1],o[2],o[3],q[1],q[2],q[3],q[4])
        fprintf(f,'POINTS %d\n',#data/3)
        fprintf(f,'DATA ascii\n')
        for i=1,#data,3 do
            fprintf(f,'%f %f %f\n',data[i],data[i+1],data[i+2])
        end
        f:close()
    end
end

