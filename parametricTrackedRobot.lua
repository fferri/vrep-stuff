function createRoller(parent, name, num, pos, orient, diam, depth)
	local hybrid = 1
	local joint = simCreateJoint(sim_joint_revolute_subtype, sim_jointmode_force, 0)
	simSetObjectName(joint, name .. 'j' .. num)
    simSetObjectParent(joint, parent, false)
    simSetObjectIntParameter(joint, 2000, 1)

	local backface_culling = 1
	local visible_edges = 2
	local smooth = 4
	local respondable = 8
	local static = 16
	local cyl_open_ends = 32
	local cylinder = simCreatePureShape(2, visible_edges + respondable, {diam, diam, depth}, 0.6)
	simSetObjectName(cylinder, name .. num)
	simSetObjectParent(cylinder, joint, false)
    local z = (num - 1)%4
    simSetObjectIntParameter(cylinder, 3019, 2^(4+z) + 130560)
    simResetDynamicObject(cylinder)
    local col = {{1,0,0}, {0,1,0}, {0,0,1}, {1,1,0}}
    simSetShapeColor(cylinder, nil, sim_colorcomponent_ambient_diffuse, col[1+z])
    
    simSetObjectPosition(joint, parent, pos)
    simSetObjectOrientation(joint, parent, orient)

    return joint, cylinder
end

function createTrack(parent, name, num, pos, orient, roller_diam, depth, length, num_rollers)
    --local track = simCreateDummy(0)
	local track = simCreatePureShape(0, 2, {length, roller_diam, 0.999*depth}, 0.6)
	simSetObjectName(track, name .. num)

    local x = -0.5*length
    local y = 0.0
    local z = 0.0
    for i=1,num_rollers,1 do
        createRoller(track, name .. num .. 'r', i, {x, y, z}, {0, 0, 0}, roller_diam, depth)
        x = x + length/(num_rollers - 1)
    end

    simSetObjectParent(track, parent, false)
    simSetObjectPosition(track, parent, pos)
    simSetObjectOrientation(track, parent, orient)
end

function setRollerVelocity(name, track_num, roller_num, vel)
    local joint = simGetObjectHandle(name .. track_num .. 'rj' .. roller_num)
    simSetJointTargetVelocity(joint, vel)
end

function setTrackVelocity(name, num, num_rollers, vel)
    for i=1,num_rollers,1 do
        setRollerVelocity(name, num, i, vel)
    end
end
