--track_objects = {}
--
--function Track:new (o)
--    o = o or {}
--    setmetatable(o, self)
--    self.__index = self
--    return o
--end

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
    local cylinder = simCreatePureShape(2, visible_edges + respondable, {diam, diam, depth}, 0.06)
    simSetObjectName(cylinder, name .. 'r' .. num)
    simSetObjectParent(cylinder, joint, false)
    local z = (num - 1)%8
    simSetObjectIntParameter(cylinder, 3019, 2^(0+z) + 130560)
    simResetDynamicObject(cylinder)
    local col = {{1,0,0}, {0,1,0}, {0,0,1}, {1,1,0}, {1,0,1}, {0,0,0}, {0,1,1}, {1,1,1}}
    simSetShapeColor(cylinder, nil, sim_colorcomponent_ambient_diffuse, col[1+z])
    
    simSetObjectPosition(joint, parent, pos)
    simSetObjectOrientation(joint, parent, orient)

    return joint, cylinder
end

function getRollerDiam(roller_diam, num_rollers, i)
    local a = (i - 1) / (num_rollers - 1)
    local d = roller_diam[1] * a + roller_diam[2] * (1 - a)
    return d
end

function createTrack(parent, name, pos, orient, roller_diam, depth, length, num_rollers, center_offset)
    if type(roller_diam) ~= 'table' then
        roller_diam = {roller_diam, roller_diam}
    end

    local min_d = math.min(roller_diam[1], roller_diam[2])
    local track = simCreatePureShape(0, 2, {min_d, min_d, 0.999*depth}, 0.6)
    simSetObjectName(track, name)

    for i=1,num_rollers,1 do
        local a = (i - 1) / (num_rollers - 1)
        local x = length * (center_offset + a)
        local y = 0.0
        local z = 0.0
        local d = getRollerDiam(roller_diam, num_rollers, i)
        createRoller(track, name, i, {x, y, z}, {0, 0, 0}, d, depth)
    end

    simSetObjectParent(track, parent, false)
    pos1 = {pos[1]+0*(center_offset+0.5)*length, pos[2], pos[3]}
    simSetObjectPosition(track, parent, pos1)
    simSetObjectOrientation(track, parent, orient)

    return track
end

function createTrackWithFlippers(parent, name, pos, orient, track_length, flipper_length, track_diam, flipper_diam, track_depth, flipper_depth, num_rollers, track_flipper_spacing)
    local track = createTrack(parent, name, pos, orient, track_diam, track_depth, track_length, num_rollers, -0.5)

    local joint = {}
    local flipper = {}
    local fr = {'f', 'r'}
    local xoff = {-0.5*track_length, 0.5*track_length}
    local aoff = {0, math.pi}
    for f=1,2 do
        local n = 'f' .. fr[f]
        joint[f] = simCreateJoint(sim_joint_revolute_subtype, sim_jointmode_force, 0)
        simSetObjectName(joint[f], name .. n .. 'j')
        simSetObjectParent(joint[f], track, false)
        simSetObjectPosition(joint[f], track, {xoff[f],0,track_flipper_spacing+0.5*track_depth+0.5*flipper_depth})
        simSetObjectOrientation(joint[f], track, {0,0,0})
        simSetObjectIntParameter(joint[f], 2000, 1)

        flipper[f] = createTrack(joint[f], name .. n, {0,0,0}, {0,0,0}, {track_diam, flipper_diam}, flipper_depth, flipper_length, num_rollers, -1.0)

        simSetJointPosition(joint[f], aoff[f])
    end

    return track
end

function createRobot(parent, name, pos, orient, body_size, hoff, joffx, joffz, track_length, flipper_length, track_diam, flipper_diam, track_depth, flipper_depth, num_rollers, body_track_spacing, track_flipper_spacing)
    local body = simCreatePureShape(0, 2+8+0*16, body_size, 0.006)
    simSetObjectName(body, name)

    local track = {}
    local track_j = {}
    local lr = {'l', 'r'}
    local joffy = {0.5*(body_size[2]+track_depth)+body_track_spacing, -0.5*(body_size[2]+track_depth)-body_track_spacing}
    local toffy = {0.5*track_depth, -0.5*track_depth}
    local jrot = {math.pi, 0}
    for t=1,2 do
        local n = 't' .. lr[t]
        track_j[t] = simCreateJoint(sim_joint_revolute_subtype, sim_jointmode_force, 0)
        simSetObjectName(track_j[t], name .. '_' .. n .. 'j')
        simSetObjectParent(track_j[t], body, false)
        simSetObjectPosition(track_j[t], body, {joffx,joffy[t],-0.5*body_size[3]-hoff+joffz})
        simSetObjectOrientation(track_j[t], body, {math.pi*0.5,jrot[t],0})
        simSetObjectIntParameter(track_j[t], 2000, 1)

        --track[t] = createTrack(track_j[t], name .. n, {0,0,0}, {0,0,0}, track_diam, track_depth, track_length, num_rollers, -0.5)
        track[t] = createTrackWithFlippers(track_j[t], name .. '_' .. n, {0,0,0}, {0,0,0}, track_length, flipper_length, track_diam, flipper_diam, track_depth, flipper_depth, num_rollers, track_flipper_spacing)
    end

    simSetObjectParent(body, parent, false)
    simSetObjectPosition(body, parent, pos)
    simSetObjectOrientation(body, parent, orient)

    local script = simAddScript(sim_scripttype_childscript)
    simAssociateScriptWithObject(script, body)
    simSetScriptText(script, [[
if (sim_call_type==sim_childscriptcall_initialization) then 
    left_track_j = simGetObjectHandle(']]..name..[[_tlj')
    right_track_j = simGetObjectHandle(']]..name..[[_trj')
end
if (sim_call_type==sim_childscriptcall_actuation) then 
	local l = simGetJointPosition(left_track_j)
	local r = simGetJointPosition(right_track_j)
    local m = (l+r)/2
	--simSetJointTargetPosition(left_track_j, (l+r)/2)
	--simSetJointTargetPosition(right_track_j, -(l+r)/2)
    simSetJointTargetVelocity(left_track_j, m-l)
    simSetJointTargetVelocity(right_track_j, m-r)
end
]])
end

function setRollerVelocity(name, roller_num, vel)
    local joint = simGetObjectHandle(name .. 'j' .. roller_num)
    simSetJointTargetVelocity(joint, vel)
end

function setTrackVelocity(name, roller_diam, num_rollers, vel)
    for i=1,num_rollers,1 do
        local d = getRollerDiam(roller_diam, num_rollers, i)
        local r = d / 2
        local va = vel / r
        setRollerVelocity(name, i, va)
    end
end

function setRobotVelocity(name, roller_diam, num_rollers, vel)
    local t = {'tl', 'tr'}
    local f = {'', 'ff', 'fr'}
    local rd = {{roller_diam[1], roller_diam[1]}, roller_diam, roller_diam}
    local vs = {-1, 1}
    for i=1,2 do
        for j=1,3 do
            for r=1,num_rollers do
                local n = name .. '_' .. t[i] .. f[j] .. 'j' .. r
                local d = getRollerDiam(rd[j], num_rollers, r)
                local joint = simGetObjectHandle(n)
                simSetJointTargetVelocity(joint, vs[i] * vel[i] * 2 / d)
            end
        end
    end
end
