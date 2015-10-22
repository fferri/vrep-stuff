Track = {}
Track.__index = Track

function Track.new(parent, name, roller_diam, depth, length, num_rollers)
    local self = setmetatable({}, Track)
    self.name = name
    self.roller_diam = roller_diam
    self.num_rollers = num_rollers

    self.body = nil
    self.roller_j = {}
    self.roller = {}

    self.roller_d = {}

    local color_mask = false
    local smooth = false

    if type(self.roller_diam) ~= 'table' then
        self.roller_diam = {self.roller_diam, self.roller_diam}
    end

    local min_d = math.min(self.roller_diam[1], self.roller_diam[2])
    self.body = simCreatePureShape(0, 2, {length, min_d, 0.999*depth}, 0.06)
    simSetObjectName(self.body, name)
    simSetObjectParent(self.body, parent, false)

    for i=1,num_rollers do
        self.roller_j[i] = simCreateJoint(sim_joint_revolute_subtype, sim_jointmode_force, 0, {depth, 0.02})
        simSetObjectName(self.roller_j[i], self.name .. '_r' .. i .. '_j')
        simSetObjectParent(self.roller_j[i], self.body, true)
        simSetObjectIntParameter(self.roller_j[i], 2000, 1)
        simSetObjectPosition(self.roller_j[i], self.body, {length * (-0.5 + (i - 1) / (self.num_rollers - 1)), 0, 0})
        simSetObjectOrientation(self.roller_j[i], self.body, {math.pi*0, 0, 0})

        self.roller_d[i] = ((i - 1) / (self.num_rollers - 1)) * (self.roller_diam[1] - self.roller_diam[2]) + self.roller_diam[2]
        self.roller[i] = simCreatePureShape(2, 2+(smooth and 4 or 0)+8, {self.roller_d[i], self.roller_d[i], depth}, 0.06)
        simSetObjectName(self.roller[i], self.name .. '_r' .. i)
        simSetObjectParent(self.roller[i], self.roller_j[i], false)
        local k = (i - 1) % 8
        simSetObjectIntParameter(self.roller[i], 3019, 2^k+(2^8-1)*2^8)
        simResetDynamicObject(self.roller[i])
        if color_mask then simSetShapeColor(self.roller[i], nil, sim_colorcomponent_ambient_diffuse, ({{1,0,0}, {0,1,0}, {0,0,1}, {1,1,0}, {1,0,1}, {0,0,0}, {0,1,1}, {1,1,1}})[1+k]) end
    end

    return self
end

function Track.setVelocity(self, vel)
    for i=1,self.num_rollers do
        simSetJointTargetVelocity(self.roller_j[i], 2 * vel / self.roller_d[i])
    end
end

TrackedRobot = {}
TrackedRobot.__index = TrackedRobot

function TrackedRobot.new(parent, name, body_size, hoff, joffx, joffz, track_length, flipper_length, track_diam, flipper_diam, track_depth, flipper_depth, num_rollers, body_track_spacing, track_flipper_spacing)
    local self = setmetatable({}, TrackedRobot)
    self.name = name
    self.track_diam = track_diam
    self.flipper_diam = flipper_diam
    self.num_rollers = num_rollers

    self.lr = {'l', 'r'}
    self.fr = {'f', 'r'}

    self.body = nil
    self.track_j = {}
    self.track = {}
    self.flipper_j = {{},{}}
    self.flipper = {{},{}}

    local static_root = false
    local flippers = true

    self.body = simCreatePureShape(0, 2+8+(static_root and 16 or 0), body_size, 0.006)
    simSetObjectName(self.body, self.name)


    local joffy = {0.5*(body_size[2]+track_depth)+body_track_spacing, -0.5*(body_size[2]+track_depth)-body_track_spacing}
    local toffy = {0.5*track_depth, -0.5*track_depth}
    local jrot = {math.pi, 0}
    for t=1,2 do
        self.track_j[t] = simCreateJoint(sim_joint_revolute_subtype, sim_jointmode_force, 0, {track_depth, 0.02})
        simSetObjectName(self.track_j[t], self.name .. '_t' .. self.lr[t] .. '_j')
        simSetObjectParent(self.track_j[t], self.body, false)
        simSetObjectPosition(self.track_j[t], self.body, {joffx,joffy[t],-0.5*body_size[3]-hoff+joffz})
        simSetObjectOrientation(self.track_j[t], self.body, {math.pi*0.5,jrot[t],0})
        simSetObjectIntParameter(self.track_j[t], 2000, 1)
        simSetJointForce(self.track_j[t], 20)

        self.track[t] = Track.new(self.track_j[t], self.name .. '_t' .. self.lr[t], track_diam, track_depth, track_length, num_rollers)

        local xoff = {-0.5*track_length, 0.5*track_length}
        local aoff = {0, math.pi}
        for f=1,(flippers and 2 or 0) do
            self.flipper_j[t][f] = simCreateJoint(sim_joint_revolute_subtype, sim_jointmode_force, 0, {track_depth+flipper_depth, 0.02})
            simSetObjectName(self.flipper_j[t][f], self.name .. '_t' .. self.lr[t] .. '_f' .. self.fr[f] .. '_j')
            simSetObjectParent(self.flipper_j[t][f], self.track[t].body, false)
            simSetObjectPosition(self.flipper_j[t][f], self.track[t].body, {xoff[f],0,track_flipper_spacing+0.5*track_depth+0.5*flipper_depth})
            simSetObjectOrientation(self.flipper_j[t][f], self.track[t].body, {0,0,0})
            simSetObjectIntParameter(self.flipper_j[t][f], 2000, 1)

            self.flipper[t][f] = Track.new(self.flipper_j[t][f], self.name .. '_t' .. self.lr[t] .. '_f' .. self.fr[f], {track_diam, flipper_diam}, flipper_depth, flipper_length, num_rollers)
            simSetObjectPosition(self.flipper[t][f].body, self.flipper_j[t][f], {-0.5*flipper_length, 0, 0})

            simSetJointPosition(self.flipper_j[t][f], aoff[f])
        end
    end

    simSetObjectParent(self.body, parent, true)

    local script = simAddScript(sim_scripttype_childscript)
    simAssociateScriptWithObject(script, self.body)
    simSetScriptText(script, [[
if (sim_call_type==sim_childscriptcall_initialization) then 
    left_track_j = simGetObjectHandle(']]..name..[[_tl_j')
    right_track_j = simGetObjectHandle(']]..name..[[_tr_j')
end
if (sim_call_type==sim_childscriptcall_actuation) then 
	local l = simGetJointPosition(left_track_j)
	local r = simGetJointPosition(right_track_j)
    local m = (l+r)/2
    simSetJointTargetVelocity(left_track_j, m-l)
    simSetJointTargetVelocity(right_track_j, m-r)
end
]])

    return self
end

function TrackedRobot.setVelocity(self, vel)
    local vs = {-1, 1}
    for t=1,2 do
        self.track[t]:setVelocity(vel[t]*vs[t])
        self.flipper[t][1]:setVelocity(vel[t]*vs[t])
        self.flipper[t][2]:setVelocity(vel[t]*vs[t])
    end
end
