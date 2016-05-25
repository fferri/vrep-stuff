GCodeInterpreter = {
    verbose=false,
    warnAboutUnimplementedCommands=true,
    unitMultiplier=0.001,
    absolute=true,
    rapid=false,
    currentPos={0,0,0},
    targetPos={0,0,0},
    currentOrient={0,0,0},
    targetOrient={0,0,0},
    speed=0,
    lastMotion=1,
    motion=0, -- 1=linear, 2=cw, 3=ccw
    center={0,0,0}, -- if useCenter==true
    radius=0, -- if useCenter==false
    pathResolution=150,
    useCenter=true,
    lineNumber=0,
    wordNumber=0,
    pathNumber=0,
    param=0,

    trace=function(self,txt)
        if self.verbose then simAddStatusbarMessage(txt) end
    end,

    dist=function(self,a,b)
        local p=math.pow
        return math.sqrt(p(a[1]-b[1],2)+p(a[2]-b[2],2)+p(a[3]-b[3],2))
    end,

    scalar=function(self,x,name)
        if type(x)~='number' then error(name..' must be a number') end
    end,

    oneof=function(self,x,X,name)
        found=false
        e=''
        for i=1,#X do
            e=(e=='' and '' or ', ')..X[i]
            if x==X[i] then found=true end
        end
        if not found then error(name..' must be one of {'..e..'}') end
    end,

    vector=function(self,v,size,name)
        if type(v)~='table' then error(name..' must be a table') end
        if size>=0 and #v~=size then error(name..' must have '..size..' elements') end
        for i=1,#v do
            if type(v[i])~='number' then error(name.."'s elements must be numbers") end
        end
    end,

    str=function(self,x,name)
        if type(x)~='string' then error(name..' must be a string') end
    end,

    any2str=function(self,x)
        if type(x)=='string' then return x end
        if type(x)=='number' then return ''..x end
        if type(x)=='table' then
            local s=''
            for i=1,#x do
                s=s..(s=='' and '' or ', ')..self:any2str(x[i])
            end
            return '{'..s..'}'
        end
    end,

    createLinearPath=function(self,from,to)
        self:vector(from,3,'from')
        self:vector(to,3,'to')

        local d=self:dist(from,to)
        local n=math.max(1,math.floor(d*self.pathResolution))
        local points={}
        for i=0,n do
            local tau=i/n
            local point={}
            for j=1,3 do table.insert(point, from[j]*(1-tau)+to[j]*tau) end
            table.insert(points, point)
        end
        return points,d
    end,

    createCircularPath=function(self,from,to,direction,centerOrRadius)
        self:vector(from,3,'from')
        self:vector(to,3,'to')
        self:oneof(direction,{-1,1},'direction')

        local t=type(centerOrRadius)
        if t=='number' then
            return self:createCircularPathWithRadius(from,to,direction,centerOrRadius)
        elseif t=='table' then
            return self:createCircularPathWithCenter(from,to,direction,centerOrRadius)
        else
            error('centerOrRadius must be a table or a number')
        end
    end,

    createCircularPathWithCenter=function(self,from,to,direction,center)
        self:vector(from,3,'from')
        self:vector(to,3,'to')
        self:oneof(direction,{-1,1},'direction')
        self:vector(center,3,'center')

        if math.abs(from[3]-to[3])>0.0001 then
            self:trace('createCircularPathWithCenter:'..
                       ' from='..self:any2str(from)..
                       ' to='..self:any2str(to)..
                       ' center='..self:any2str(center)..
                       ' r1='..self:dist(from,center)..
                       ' r2='..self:dist(to,center))
            error('from/to points do not have the same Z')
        end

        -- compute start/end radiuses:
        local r1=self:dist(from,center)
        local r2=self:dist(to,center)
        if math.abs(r1-r2) > 0.0025 then
            error('start and end radius are not the same: error='..math.abs(r1-r2))
        end

        -- compute start/end angles:
        local As=math.atan2(from[2]-center[2],from[1]-center[1])
        local Ae=math.atan2(to[2]-center[2],to[1]-center[1])

        -- compute distance in radians:
        local angular_distance=0
        if direction>0 and As<Ae then
            angular_distance=Ae-As
        elseif direction>0 and As>Ae then
            angular_distance=2*math.pi-(As-Ae)
        elseif direction<0 and As<Ae then
            angular_distance=2*math.pi-(Ae-As)
        elseif direction<0 and As>Ae then
            angular_distance=As-Ae
        else
            error('WTF?')
        end

        -- linear distance:
        local d=angular_distance*r1

        -- circular (i.e. polar) interpolation:
        local n=math.max(1,math.floor(d*self.pathResolution))
        local da=angular_distance/n
        local points={}
        for i=0,n do
            local a=As+direction*da*i
            local point={center[1]+r1*math.cos(a),center[2]+r1*math.sin(a),from[3]}
            table.insert(points, point)
        end
        return points,d
    end,

    createCircularPathWithRadius=function(self,from,to,direction,radius)
        self:vector(from,3,'from')
        self:vector(to,3,'to')
        self:oneof(direction,{-1,1},'direction')
        self:scalar(radius,'radius')

        local r=radius
        local x1=from[1]
        local y1=from[2]
        local x2=to[1]
        local y2=to[2]
        local z=from[3]

        -- find the centers of the two circles passing thru (x1,y1) and (x2,y2):
        local x3=(x1+x2)/2
        local y3=(y1+y2)/2
        local d=self:dist({x1,y1,z},{x2,y2,z})
        local xA=x3+math.sqrt(r*r-d*d/4)*(y1-y2)/d
        local yA=y3+math.sqrt(r*r-d*d/4)*(x2-x1)/d
        local xB=x3-math.sqrt(r*r-d*d/4)*(y1-y2)/d
        local yB=y3-math.sqrt(r*r-d*d/4)*(x2-x1)/d

        if ((x2-x1)*(yA-y1)-(y2-y1)*(xA-x1))>0 then
            xL,yL,xR,yR=xA,yA,xB,yB
        else
            xL,yL,xR,yR=xB,yB,xA,yA
        end

        if direction>0 then
            return self:createCircularPathWithCenter(from,to,direction,{xL,yL,z})
        else
            return self:createCircularPathWithCenter(from,to,direction,{xR,yR,z})
        end
    end,

    onBeginProgram=function(self,program)
    end,

    onEndProgram=function(self,program)
        self:trace('parsed '..self.wordNumber..' words in '..self.lineNumber..' lines')
    end,

    runProgram=function(self,program)
        self:str(program,'program')

        self:onBeginProgram(program)

        local lines={}
        local function helper(line) table.insert(lines,line) return '' end
        helper((program:gsub("(.-)\r?\n", helper)))
        for i=1,#lines do
            self.lineNumber=self.lineNumber+1
            self:runLine(lines[i])
        end

        self:onEndProgram(program)
    end,

    onBeginLine=function(self,line)
        self:trace('>>>>>>>>  '..line)
    end,

    onEndLine=function(self,line)
        self:executeMotion()
    end,

    runLine=function(self,line)
        self:str(line,'line')

        self.center={0,0,0}
        self.radius=0
        self.motion=0

        self:onBeginLine(line)

        local handler=function(address,value)
            self.wordNumber=self.wordNumber+1
            local valueNum=tonumber(value)
            local f=address:upper()
            local f1=f..valueNum
            if self[f1]~=nil then
                self[f1](self)
            elseif self[f]~=nil then
                self[f](self,valueNum)
            elseif self.verbose or self.warnAboutUnimplementedCommands then
                simAddStatusbarMessage('WARNING: command '..address..valueNum..' not implemented')
            end
        end

        local comment=false
        local comment2=false
        local addr=nil
        local val=''
        for ch in line:gmatch('.') do
            if ch==';' then comment2=true
            elseif ch=='(' then comment=true
            elseif ch==')' then comment=false
            elseif not (ch==' ' or ch=='\t' or comment or comment2) then
                if ch:match('%a') then
                    if addr~=nil and val~='' then handler(addr,val) end
                    addr,val=ch,''
                elseif addr==nil then
                    error('unexpected "'..ch..'" while waiting for an address')
                else
                    val=val..ch
                end 
            end
        end
        if addr~=nil and val~='' then handler(addr,val) end

        self.lastMotion=self.motion

        self:onEndLine(line)
    end,

    mkpath=function(self,points,startOrient,endOrient,color,duration)
        local status,dh=pcall(function() return simGetObjectHandle('Path') end)
        if not status then
            dh=simCreateDummy(0)
            simSetObjectName(dh,'Path')
        end
        local prop=sim_pathproperty_show_line
        local h=simCreatePath(prop,nil,nil,color)
        simWriteCustomDataBlock(h,'duration',simPackFloats({duration}))
        simSetObjectName(h,string.format('Path_%06d',self.pathNumber))
        simSetObjectParent(h,dh,true)
        data={}
        for i=1,#points do
            local tau=(i-1)/(#points-1)
            for j=1,3 do table.insert(data,points[i][j]) end
            for j=1,3 do table.insert(data,startOrient[j]*(1-tau)+endOrient[j]*tau) end
            for j=1,5 do table.insert(data,0) end
        end
        simInsertPathCtrlPoints(h,0,0,#points,data)
        return h
    end,

    executeMotion=function(self)
        local from={0,0,0}
        local to={0,0,0}
        local center={0,0,0}
        local radius=self.radius
        local os=self.currentOrient
        local oe=self.targetOrient

        local red={1,0,0,0,0,0,0,0,0,0,0,0}
        local green={0,1,0,0,0,0,0,0,0,0,0,0}
        local blue={0,0,1,0,0,0,0,0,0,0,0,0}

        -- scale units:
        for i=1,3 do
            center[i]=(self.currentPos[i]+self.center[i])*self.unitMultiplier
            from[i]=self.currentPos[i]*self.unitMultiplier
            to[i]=self.targetPos[i]*self.unitMultiplier
        end
        radius=radius*self.unitMultiplier

        local pstr='    [path '..self.pathNumber..'] '
        local d=self:dist(from,to)

        if self.motion==1 then
            local p,len=self:createLinearPath(from,to)
            self:trace('    '..#p..' path points')
            self:trace(pstr..'line from '..self:any2str(from)..' to '..self:any2str(to)..' (d='..d..')')
            self.pathNumber=self.pathNumber+1
            self:mkpath(p,os,oe,(self.rapid and red or green),len/self.speed)
        elseif self.motion==2 or self.motion==3 then
            local direction=2*self.motion-5
            local centerOrRadius=(self.useCenter and center or radius)
            local p,len=self:createCircularPath(from,to,direction,centerOrRadius)
            self:trace('    '..#p..' path points')
            self:trace(pstr..'arc from '..self:any2str(from)..' to '..self:any2str(to)..' with '..(self.useCenter and ('center '..self:any2str(self.center)) or ('radius '..self.radius))..' (d='..d..')')
            self.pathNumber=self.pathNumber+1
            self:mkpath(p,os,oe,(self.rapid and red or green),len/self.speed)
        elseif self.motion==4 then
            -- pause
            local seconds=0.001*self.param
            self.pathNumber=self.pathNumber+1
            local h=simCreateDummy(0)
            simSetObjectName(h,string.format('Path_%06d',self.pathNumber))
            simSetObjectParent(h,dh,true)
            simWriteCustomDataBlock(h,'duration',simPackFloats({seconds}))
        end

        for i=1,3 do
            self.currentPos[i]=self.targetPos[i]
            self.currentOrient[i]=self.targetOrient[i]
        end
    end,

    A=function(self,value)
        -- A: Absolute or incremental position of A axis (rotational axis around X axis)
        self:trace('A'..value..'  A-axis position')
        self.targetOrient[1]=(self.absolute and 0 or self.targetOrient[1])+value
    end,

    B=function(self,value)
        -- B: Absolute or incremental position of B axis (rotational axis around Y axis)	
        self:trace('B'..value..'  B-axis position')
        self.targetOrient[2]=(self.absolute and 0 or self.targetOrient[2])+value
    end,

    C=function(self,value)
        -- C: Absolute or incremental position of C axis (rotational axis around Z axis)	
        self:trace('C'..value..'  C-axis position')
        self.targetOrient[3]=(self.absolute and 0 or self.targetOrient[3])+value
    end,

    F=function(self,value)
        -- F: Defines feed rate.
        --    Common units are distance per time for mills (inches per minute, IPM, or
        --    millimeters per minute, mm/min) and distance per revolution for lathes
        --    (inches per revolution, IPR, or millimeters per revolution, mm/rev)
        self:trace('F'..value..'  Feedrate')
        speed=value
    end,

    G0=function(self)
        self:trace('G00  Rapid positioning')
        self.rapid=true
        self.motion=1
    end,

    G1=function(self)
        self:trace('G01  Linear interpolation')
        self.rapid=false
        self.motion=1
    end,

    G2=function(self)
        self:trace('G02  Circular interpolation, clockwise')
        --      Center given with I,J,K commands (or radius with R)
        self.rapid=false
        self.motion=2
    end,

    G3=function(self)
        self:trace('G03  Circular interpolation, counterclockwise')
        --      Center given with I,J,K commands (or radius with R)
        self.rapid=false
        self.motion=3
    end,

    G4=function(self)
        self:trace('G03  Dwell (pause)')
        self.motion=4
    end,

    G20=function(self)
        self:trace('G20  Programming in inches')
        self.unitMultiplier=25.4*0.001
    end,

    G21=function(self)
        self:trace('G21  Programming in millimeters (mm)')
        self.unitMultiplier=0.001
    end,

    G28=function(self)
        self:trace('G28  Return to home position')
        self.targetPos={0,0,0}
    end,

    G90=function(self)
        self:trace('G90  Absolute programming')
        self.absolute=true
    end,

    G91=function(self)
        self:trace('G91  Incremental programming')
        self.absolute=false
    end,

    I=function(self,value)
        -- I: Defines arc center in X axis for G02 or G03 arc commands.
        --    Also used as a parameter within some fixed cycles.
        self:trace('I'..value..'  Arc center in X axis')
        self.center[1]=value
        self.useCenter=true
    end,

    J=function(self,value)
        -- J: Defines arc center in Y axis for G02 or G03 arc commands.
        --    Also used as a parameter within some fixed cycles.	
        self:trace('J'..value..'  Arc center in Y axis')
        self.center[2]=value
        self.useCenter=true
    end,

    K=function(self,value)
        -- K: Defines arc center in Z axis for G02 or G03 arc commands.
        --    Also used as a parameter within some fixed cycles, equal to L address.	
        self:trace('K'..value..'  Arc center in Z axis')
        self.center[3]=value
        self.useCenter=true
    end,

    P=function(self,value)
        self.param=value
    end,

    R=function(self,value)
        -- R: Defines size of arc radius, or defines retract height in milling canned cycles
        --    For radii, not all controls support the R address for G02 and G03, in which
        --    case IJK vectors are used. For retract height, the "R level", as it's called,
        --    is returned to if G99 is programmed.
        self:trace('R'..value..'  Size of arc radius')
        self.radius=value
        self.useCenter=false
    end,

    U=function(self,value)
        self:trace('U'..value..'  Incremental position of X axis')
        self.targetPos[1]=self.targetPos[1]+value
        if self.motion==0 then self.motion=self.lastMotion end
    end,

    V=function(self,value)
        self:trace('V'..value..'  Incremental position of X axis')
        self.targetPos[2]=self.targetPos[2]+value
        if self.motion==0 then self.motion=self.lastMotion end
    end,

    W=function(self,value)
        self:trace('W'..value..'  Incremental position of X axis')
        self.targetPos[3]=self.targetPos[3]+value
        if self.motion==0 then self.motion=self.lastMotion end
    end,

    X=function(self,value)
        -- X: Absolute or incremental position of X axis.
        --    Also defines dwell time on some machines (instead of "P" or "U").
        self:trace('X'..value..'  Absolute/incremental position of X axis')
        self.targetPos[1]=(self.absolute and 0 or self.targetPos[1])+value
        if self.motion==0 then self.motion=self.lastMotion end
    end,

    Y=function(self,value)
        -- Y: Absolute or incremental position of Y axis	
        self:trace('Y'..value..'  Absolute/incremental position of Y axis')
        self.targetPos[2]=(self.absolute and 0 or self.targetPos[2])+value
        if self.motion==0 then self.motion=self.lastMotion end
    end,

    Z=function(self,value)
        -- Z: Absolute or incremental position of Z axis
        --    The main spindle's axis of rotation often determines which axis of a
        --    machine tool is labeled as Z.
        self:trace('Z'..value..'  Absolute/incremental position of Z axis')
        self.targetPos[3]=(self.absolute and 0 or self.targetPos[3])+value
        if self.motion==0 then self.motion=self.lastMotion end
    end
}

