savePCL=function(data,filename)
    local fprintf=function(f,fmt,...) f:write(string.format(fmt,...)) end
    if #data>0 and not saved then
        local f,err=io.open(filename,'w')
        if not f then return print(err) end
        fprintf(f,'# .PCD v0.7\nVERSION 0.7\n')
        fprintf(f,'FIELDS x y z\nSIZE 4 4 4\nTYPE F F F\nCOUNT 1 1 1\n')
        fprintf(f,'WIDTH %d\nHEIGHT %d\n',#data/3,1)
        fprintf(f,'VIEWPOINT %f %f %f %f %f %f %f\n',o[1],o[2],o[3],q[1],q[2],q[3],q[4])
        fprintf(f,'POINTS %d\nDATA ascii\n',#data/3)
        for i=1,#data,3 do
            fprintf(f,'%f %f %f\n',data[i],data[i+1],data[i+2])
        end
        f:close()
    end
end
