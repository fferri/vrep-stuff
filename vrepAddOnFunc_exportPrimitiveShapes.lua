local win=sim.getInt32Parameter(sim.intparam_platform)==0
local visibleLayers=sim.getInt32Parameter(sim.intparam_visible_layers)

local allIndividualShapesToRemove={}

            --local indivMatr=sim.getObjectMatrix(individualShapes[j],-1)
            --local totIndivMatrix=sim.getObjectMatrix(objHandle,-1)
            --sim.invertMatrix(totIndivMatrix)
            --totIndivMatrix=sim.multiplyMatrices(totIndivMatrix,indivMatr)

function exportShapeToJSON(f,objHandle,depth)
    local indent0=''
    for i=1,depth do indent0=indent0..'  ' end
    local indent=''
    for i=0,depth do indent=indent..'  ' end
    local objType=sim.getObjectType(objHandle)
    local objName=sim.getObjectName(objHandle)
    local res,layers=sim.getObjectInt32Parameter(objHandle,10)
    local visibility=sim.boolAnd32(visibleLayers,layers)
    if visibility==0 or objType~=sim.object_shape_type then return end
    local res,pureType,dim=sim.getShapeGeomInfo(objHandle)
    if res==-1 then return end
    local compound=sim.boolAnd32(res,1)
    local pure=sim.boolAnd32(res,2)
    local convex=sim.boolAnd32(res,4)
    if pure==0 then return end
    if compound~=0 then
        local tmpObj=sim.copyPasteObjects({objHandle},0)
        local individualShapes=sim.ungroupShape(tmpObj[1])
        for j=1,#individualShapes,1 do
            allIndividualShapesToRemove[#allIndividualShapesToRemove+1]=individualShapes[j]
            exportShapeToJSON(f,individualShapes[j],depth)
        end
        return
    end
    f:write(string.format('%s{\n',indent0))
    f:write(string.format('%s"handle": "%s",\n',indent,objHandle))
    f:write(string.format('%s"name": "%s",\n',indent,objName))
    local m=sim.getObjectMatrix(objHandle,-1) -- 12 elements
    f:write(string.format('%s"R": [%.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f],\n',indent,m[1],m[2],m[3],m[5],m[6],m[7],m[9],m[10],m[11]))
    f:write(string.format('%s"p": [%.6f, %.6f, %.6f],\n',indent,m[4],m[8],m[12]))
    f:write(string.format('%s"dim": [%.6f, %.6f, %.6f, %.6f],\n',indent,dim[1],dim[2],dim[3],dim[4]))
    local typeStr='unknown'
    if pureType==sim.pure_primitive_plane then
        typeStr='plane'
    elseif pureType==sim.pure_primitive_cuboid then
        typeStr='cuboid'
    elseif pureType==sim.pure_primitive_spheroid then
        typeStr='sphereoid'
    elseif pureType==sim.pure_primitive_cylinder then
        typeStr='cylinder'
    end
    f:write(string.format('%s"type": "%s"\n',indent,typeStr))
    f:write(string.format('%s},\n',indent0))
end

--local objs=sim.getObjectsInTree(sim.handle_scene, sim.handle_all, 2)
--for i=1,#objs do
--    visitTree(objs[i], -1)
--end

local selectedObjects=sim.getObjectSelection()
if selectedObjects then
    sim.addStatusbarMessage(''..#selectedObjects..' selected objects')
    local xml_filename=sim.fileDialog(sim.filedlg_type_save, 'Export primitive shapes to JSON...', os.getenv('HOME'), 'shapes.json', 'JSON file', 'json')
    if xml_filename then
        sim.addStatusbarMessage('Selected filename: '..xml_filename)
        local file=io.open(xml_filename, 'w')
        file:write('{\n')
        file:write('  "shapes": [\n')
        for i=1,#selectedObjects do
            exportShapeToJSON(file,selectedObjects[i],2)
        end
        file:write('  ]\n')
        file:write('}\n')
        file:close()
    else
        sim.addStatusbarMessage('No file selected')
    end
else
    sim.addStatusbarMessage('Selection is empty')
end


--if selectedObjects and #selectedObjects==1 then
--    local objList=sim.getObjectsInTree(selectedObjects[1])
--else
--    local objList=sim.getObjectsInTree(sim.handle_scene)
--end

for i=1,#allIndividualShapesToRemove,1 do
    sim.removeObject(allIndividualShapesToRemove[i])
end
