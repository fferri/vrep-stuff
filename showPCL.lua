showPCL=function(data,color)
    points=simAddDrawingObject(sim_drawing_spherepoints,0.01,0,-1,100000,nil,nil,nil,color)
    for i=1,#data,3 do
        local p={data[i],data[i+1],data[i+2]}
        simAddDrawingObjectItem(points,p)
    end
    return points
end
