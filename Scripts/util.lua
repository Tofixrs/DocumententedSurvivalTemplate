--util.lua
dofile("$CONTENT_DATA/Scripts/game/survival_shapes.lua")
dofile("$CONTENT_DATA/Scripts/game/survival_constants.lua")
dofile("$CONTENT_DATA/Scripts/game/survival_projectiles.lua")

---Prints a formatted version of its variable number of arguments following the description given in its first argument.
---@param s string string to format
---@vararg any
function printf(s, ...)
    return print(s:format(...))
end

---limits the value between min and max
---@param value number Value to limit
---@param min number minimum value returned
---@param max number maximum value returned
---@return number
function clamp(value, min, max)
    if value < min then
        return min
    elseif value > max then
        return max
    else
        return value
    end
end

---Rounds to the nearest integer
---@param value number
---@return integer
function round(value)
    return math.floor(value + 0.5)
end

---Returns the bigger number between a and b
---@param a number
---@param b number
---@return number
function max(a, b)
    return a > b and a or b
end

---Returns the smaller number between a and b
---@param a number
---@param b number
---@return number
function min(a, b)
    return a < b and a or b
end

---Returns the sign of the number -1 meaning a negative number 1 meaning a positive number
---@param value number
---@return integer
function sign(value)
    return value >= DBL_EPSILON and 1 or (value <= -DBL_EPSILON and -1 or 0)
end

---Checks if the number provided is finite
---@param value any
---@return boolean
function finite(value)
    return value > -math.huge and value < math.huge
end

---Converts radians to degrees
---@param rad number
---@return number
function RadToDeg(rad)
    return rad * 57.295779513082320876798154814105 --- rad * 180/pi
end

---Converts degrees to radians
---@param deg number
---@return number
function DegToRad(deg)
    return deg * 0.01745329251994329576923690768489 --- deg * 1 / (180/pi)
end

---@param a number
---@param b number
---@param p number
---@return number lerp
function lerp(a, b, p)
    return clamp(a + (b - a) * p, min(a, b), max(a, b))
end

---@param a number
---@param b number
---@param dt number Delta time
---@param speed number
---@return number
function easeIn(a, b, dt, speed)
    local p = 1 - math.pow(clamp(speed, 0.0, 1.0), dt * 60)
    return lerp(a, b, p)
end

---@param a number
---@param b number
---@param p number
---@return number lerp
function unclampedLerp(a, b, p)
    return a + (b - a) * p
end

---Checks if the parameter [is] is any of the values in array [off]
---@generic T
---@param is T
---@param off T[]
---@return boolean
function isAnyOf(is, off)
    for _, v in pairs(off) do
        if is == v then
            return true
        end
    end
    return false
end

---Checks if the value exists in a array
---@generic T
---@param array T[]
---@param value T
---@return boolean
function valueExists(array, value)
    for _, v in ipairs(array) do
        if v == value then
            return true
        end
    end
    return false
end

---Concats two arrays together
---@generic T
---@param a T[]
---@param b T[]
function concat(a, b)
    for _, v in ipairs(b) do
        a[#a + 1] = v;
    end
end

---Appends two tables together.
---> # [!Warning]
---> # this doesnt append to an array
---@param a table
---@param b table
function append(a, b)
    for k, v in pairs(b) do
        a[k] = v;
    end
end

---http://lua-users.org/wiki/oSwitchStatement
---TODO: add typings later cuz this is a pain to type
function switch(table)
    table.case = function(self, caseVariable)
        local caseFunction = self[caseVariable] or self.default
        if caseFunction then
            if type(caseFunction) == "function" then
                caseFunction(caseVariable, self)
            else
                error("case " .. tostring(caseVariable) .. " not a function")
            end
        end
    end
    return table
end

---Improved version of a switch i added for my sake. Sadly couldnt get typings to work
---@generic T
---@generic U
---@param case T
---@alias case (fun(case: T): U) | U
---@alias returnFunc fun(codetable: {[T]: case, default: case}): U
---@return returnFunc
function switch2(case)
    ---@type returnFunc
    local fun = function(codetable)
        local f = codetable[case] or codetable.default
        if f then
            if type(f) == "function" then
                return f(case)
            else
                return f
            end
        end
        return nil
    end
    return fun
end

---adds the value to the array if it doesnt exist
---@generic T
---@param array T[]
---@param value T
function addToArrayIfNotExists(array, value)
    local n = #array
    for i = 1, n do
        if array[i] == value then
            return
        end
    end
    array[n + 1] = value
end

---Removes elements from the array based on the result of [fnShouldRemove]
---@generic T
---@param array T[]
---@param fnShouldRemove fun(val: T): boolean
---@return T[]
function removeFromArray(array, fnShouldRemove)
    local n = #array;
    local j = 1
    for i = 1, n do
        if fnShouldRemove(array[i]) then
            array[i] = nil;
        else
            if i ~= j then
                array[j] = array[i];
                array[i] = nil;
            end
            j = j + 1;
        end
    end
    return array;
end

---TODO: figure out what this does
---@param x number The x position of the cell
---@param y number The y position of the cell
---@return number
function CellKey(x, y)
    return (y + 1024) * 2048 + x + 1024
end

---Check whether the ]shapeUuid] is one of a harvest
--- # [!Note]
--- # Only checks from $CONTENT_DATA/Objects/Database/ShapeSets/harvests.json
---@param shapeUuid Uuid
---@return boolean
function isHarvest(shapeUuid)
    local harvests = sm.json.open("$CONTENT_DATA/Objects/Database/ShapeSets/harvests.json")
    for _, harvest in ipairs(harvests.partList) do
        local harvestUuid = sm.uuid.new(harvest.uuid)
        if harvestUuid == shapeUuid then
            return true
        end
    end

    return false
end

---Checks whether the [shapeUuid] is one of a pipe
--- # [!Note]
--- # only checks for PipeStraight, PipeBend, PneumaticPump, PipeMerger
---@param shapeUuid Uuid
---@return boolean
function isPipe(shapeUuid)
    local pipeList = {}
    pipeList[#pipeList + 1] = sm.uuid.new("9dd5ee9c-aa5c-4bec-8fc2-a67999697085") --PipeStraight
    pipeList[#pipeList + 1] = sm.uuid.new("7f658dcd-e31d-4890-b4a7-4cd5e1378eaf") --PipeBend
    pipeList[#pipeList + 1] = sm.uuid.new("339dc807-099c-449f-bc4b-ecad92e9908d") --PneumaticPump
    pipeList[#pipeList + 1] = sm.uuid.new("28f536f2-f812-4bd4-821f-483a76f55de3") --PipeMerger

    for _, pipeUuid in ipairs(pipeList) do
        if shapeUuid == pipeUuid then
            return true
        end
    end

    return false
end

---Get cell pos from world position
---@param x number
---@param y number
---@return integer x
---@return integer y
function getCell(x, y)
    return math.floor(x / 64), math.floor(y / 64)
end

--- Allows to iterate a table of form [key, value, key, value, key, value]
function kvpairs(t)
    local i = 1
    local n = #t
    return function()
        if i < n then
            local a = t[i]
            local b = t[i + 1]
            i = i + 2
            return a, b
        end
    end
end

---Reversed [ipairs]
---@generic T
---@param a T[]
---@return fun(a: T[], i: integer)
---@return T[]
---@return integer
function reverse_ipairs(a)
    ---@diagnostic disable-next-line: redefined-local
    function iter(a, i)
        i = i - 1
        local v = a[i]
        if v then
            return i, v
        end
    end

    return iter, a, #a + 1
end

---Shuffles the array
---@generic T
---@param array T[] array to shuffle
---@param first? integer The beggining of the range where the array shuffles
---@param last? integer  The end of the range where the array shuffles
---@return T[]
function shuffle(array, first, last)
    first = first or 1
    last = last or #array
    for i = last, 1 + first, -1 do
        local j = math.random(first, i)
        array[i], array[j] = array[j], array[i]
    end
    return array
end

---Reverses the array
---@generic T
---@param array T[]
function reverse(array)
    local i, j = 1, #array
    while i < j do
        array[i], array[j] = array[j], array[i]
        i = i + 1
        j = j - 1
    end
end

---@generic T
---@param orig T
---@return T
function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- #region complicated math stuff that i will do comments for later TODO

---@param line0 Vec3
---@param line1 Vec3
---@param point Vec3
---@return Vec3
---@return number
---@return number
function closestPointOnLineSegment(line0, line1, point)
    local vec = line1 - line0
    local len = vec:length()
    local dist = (vec / len):dot(point - line0)
    local t = sm.util.clamp(dist / len, 0, 1)
    return line0 + vec * t, t, len
end

---@param linePoints Vec3[]
---@param point Vec3
---@return nil | { i: number, pt: Vec3, t: number, len: number}
function closestPointInLines(linePoints, point)
    local closest
    if #linePoints > 1 then
        local closestDistance2 = math.huge
        for i = 1, #linePoints - 1 do
            local pt, t, len = closestPointOnLineSegment(linePoints[i], linePoints[i + 1], point)
            local distance2 = (pt - point):length2()
            if distance2 < closestDistance2 then
                closest = { i = i, pt = pt, t = t, len = len }
                closestDistance2 = distance2
            end
        end
    elseif #linePoints == 1 then
        closest = { i = 1, pt = linePoints[1], t = 0, len = 1 }
    end
    return closest
end

---@param linePoints Vec3[]
---@param point Vec3
---@return nil | { i: number, pt: Vec3, t: number, len: number}
function closestPointInLinesSkipFirst(linePoints, point)
    local closest
    if #linePoints > 1 then
        local closestDistance2 = math.huge
        for i = 2, #linePoints - 1 do
            local pt, t, len = closestPointOnLineSegment(linePoints[i], linePoints[i + 1], point)
            local distance2 = (pt - point):length2()
            if distance2 < closestDistance2 then
                closest = { i = i, pt = pt, t = t, len = len }
                closestDistance2 = distance2
            end
        end
    elseif #linePoints == 1 then
        closest = { i = 1, pt = linePoints[1], t = 0, len = 1 }
    end
    return closest
end

---@alias line {p0: Vec3, p1: Vec3, length: number}
---@param linePoints Vec3[]
---@return integer
---@return line[]
function lengthOfLines(linePoints)
    ---@type line[]
    local lines = {}
    local totalLength = 0
    if #linePoints > 1 then
        for i = 1, #linePoints - 1 do
            lines[i] = {}
            lines[i].p0 = linePoints[i]
            lines[i].p1 = linePoints[i + 1]
            lines[i].length = (lines[i].p1 - lines[i].p0):length()
            totalLength = totalLength + lines[i].length
        end
    end
    return totalLength, lines
end

---@param linePoints Vec3
---@param point Vec3
---@return number | nil
function closestFractionInLines(linePoints, point)
    if #linePoints > 1 then
        local closest = closestPointInLines(linePoints, point)

        ---@diagnostic disable-next-line: need-check-nil
        return ((closest.i - 1) + closest.t) / #linePoints
    elseif #linePoints == 1 then
        return 1.0
    end
end

---p = progress from first point (1) to last point (#points)
---@param points Vec3[]
---@param p number
---@param distances number[]
---@return Vec3
---@return Vec3
---@return Vec3
---@return Vec3
---@return Vec3
---@return Vec3
function spline(points, p, distances)
    assert(#points > 1, "Must have at least 2 points")
    local i0 = math.floor(p)
    if i0 < 1 then
        i0 = 1
        p = 1
    elseif i0 >= #points then
        i0 = #points - 1
        p = #points
    end

    local u
    local ui
    if distances then
        local invDistance = 1 / distances[#distances]
        u = ((p - i0) * (distances[i0 + 1] - distances[i0]) + distances[i0]) * invDistance
        ui = function(o)
            local i = i0 + o
            if i < 1 then i = 1 end
            if i > #distances then i = #distances end
            return distances[i] * invDistance
        end
    else
        u = p
        ui = function(o) return i0 + o end
    end

    local pt1_0 = points[math.max(i0 - 1, 1)]
    local pt2_0 = points[i0]
    local pt3_0 = points[i0 + 1]
    local pt4_0 = points[math.min(i0 + 2, #points)]

    local t = (u - ui(-2)) / (ui(1) - ui(-2))
    local pt1_1 = sm.vec3.lerp(pt1_0, pt2_0, finite(t) and t or 0.0)
    t = (u - ui(-1)) / (ui(2) - ui(-1))
    local pt2_1 = sm.vec3.lerp(pt2_0, pt3_0, finite(t) and t or 0.0)
    t = (u - ui(0)) / (ui(3) - ui(0))
    local pt3_1 = sm.vec3.lerp(pt3_0, pt4_0, finite(t) and t or 0.0)

    t = (u - ui(-1)) / (ui(1) - ui(-1))
    local pt1_2 = sm.vec3.lerp(pt1_1, pt2_1, finite(t) and t or 0.0)
    t = (u - ui(0)) / (ui(2) - ui(0))
    local pt2_2 = sm.vec3.lerp(pt2_1, pt3_1, finite(t) and t or 0.0)

    t = (u - ui(0)) / (ui(1) - ui(0))
    local pt1_3 = sm.vec3.lerp(pt1_2, pt2_2, finite(t) and t or 0.0)

    return pt1_3, pt1_2, pt2_2, pt1_1, pt2_1, pt3_1
end

---@param body Body
---@param position Vec3
---@return Shape
function getClosestShape(body, position)
    local closestShape = nil
    local closestDistance = math.huge
    local shapes = body:getShapes()
    for _, shape in ipairs(shapes) do
        local distance = (shape.worldPosition - position):length()
        if closestShape then
            if distance < closestDistance then
                closestShape = shape
                closestDistance = distance
            end
        else
            closestShape = shape
            closestDistance = distance
        end
    end

    return closestShape
end

---@param fromDirection Vec3
---@param toDirection Vec3
---@param p number
---@return Vec3
function lerpDirection(fromDirection, toDirection, p)
    local cameraHeading = math.atan2(-fromDirection.x, fromDirection.y)
    local cameraPitch = math.asin(fromDirection.z)

    local cameraDesiredHeading = math.atan2(-toDirection.x, toDirection.y)
    local cameraDesiredPitch = math.asin(toDirection.z)

    local shortestAngle = (((cameraDesiredHeading - cameraHeading) % (2 * math.pi) + 3 * math.pi) % (2 * math.pi)) -
        math.pi
    cameraDesiredHeading = cameraHeading + shortestAngle

    cameraHeading = sm.util.lerp(cameraHeading, cameraDesiredHeading, p)
    cameraPitch = sm.util.lerp(cameraPitch, cameraDesiredPitch, p)

    local newCameraDirection = sm.vec3.new(0, 1, 0)
    newCameraDirection = newCameraDirection:rotateX(cameraPitch)
    newCameraDirection = newCameraDirection:rotateZ(cameraHeading)

    return newCameraDirection
end

---@param currentDirection Vec3
---@param desiredDirection Vec3
---@param dt number Delta time since the last frame.
---@param speed number
---@return Vec3
function magicDirectionInterpolation(currentDirection, desiredDirection, dt, speed)
    -- Smooth heading and pitch movement
    speed = speed or (1.0 / 6.0)
    local blend = 1 - math.pow(1 - speed, dt * 60)
    return lerpDirection(currentDirection, desiredDirection, blend)
end

---@param currentPosition Vec3
---@param desiredPosition Vec3
---@param dt number Delta time since the last frame.
---@param speed number
---@return Vec3
function magicPositionInterpolation(currentPosition, desiredPosition, dt, speed)
    speed = speed or (1.0 / 6.0)
    local blend = 1 - math.pow(1 - speed, dt * 60)
    return sm.vec3.lerp(currentPosition, desiredPosition, blend)
end

---@param currentValue number
---@param desiredValue number
---@param dt number Delta time since the last frame.
---@param speed number
---@return number
function magicInterpolation(currentValue, desiredValue, dt, speed)
    speed = speed or (1.0 / 6.0)
    local blend = 1 - math.pow(1 - speed, dt * 60)
    return sm.util.lerp(currentValue, desiredValue, blend)
end

---@param p number
---@return number
function TriangleCurve(p)
    local res = math.max(math.min(p, 1.0), 0.0)
    return 1.0 - math.abs(res * 2 - 1.0)
end

-- #endregion

---Checks if uuid provided is any of the drill or saw
---@param shapeUuid Uuid
---@return boolean
function isDangerousCollisionShape(shapeUuid)
    return isAnyOf(shapeUuid, { obj_powertools_drill, obj_powertools_sawblade })
end

---Checks if uuid provided is any of small scrap wheel, small wheel, big wheel, crane wheel
---@param shapeUuid Uuid
---@return boolean
function isSafeCollisionShape(shapeUuid)
    return isAnyOf(shapeUuid,
        { obj_scrap_smallwheel, obj_vehicle_smallwheel, obj_vehicle_bigwheel, obj_spaceship_cranewheel })
end

---Checks if Uuid provided is one of a tape projectile
---@param projectileUuid Uuid
---@return boolean
function isTrapProjectile(projectileUuid)
    return isAnyOf(projectileUuid, { projectile_tape, projectile_explosivetape })
end

---Checks if uuid provided is one of
---[obj_harvest_metal],
---[obj_robotparts_tapebothead01],
---[obj_robotparts_tapebottorso01],
---[obj_robotparts_tapebotleftarm01],
---[obj_robotparts_tapebotshooter],
---[obj_robotparts_haybothead],
---[obj_robotparts_haybotbody],
---[obj_robotparts_haybotfork],
---[obj_robotpart_totebotbody],
---[obj_robotpart_totebotleg],
---[obj_robotparts_farmbotpart_head],
---[obj_robotparts_farmbotpart_cannonarm],
---[obj_robotparts_farmbotpart_drill],
---[obj_robotparts_farmbotpart_scytharm]
---@param shapeUuid Uuid
---@return boolean
function isIgnoreCollisionShape(shapeUuid)
    return isAnyOf(shapeUuid, {
        obj_harvest_metal,

        obj_robotparts_tapebothead01,
        obj_robotparts_tapebottorso01,
        obj_robotparts_tapebotleftarm01,
        obj_robotparts_tapebotshooter,

        obj_robotparts_haybothead,
        obj_robotparts_haybotbody,
        obj_robotparts_haybotfork,

        obj_robotpart_totebotbody,
        obj_robotpart_totebotleg,

        obj_robotparts_farmbotpart_head,
        obj_robotparts_farmbotpart_cannonarm,
        obj_robotparts_farmbotpart_drill,
        obj_robotparts_farmbotpart_scytharm
    })
end

---Returns the hour and minute string of the day in 24 hour format
---@return string
function getTimeOfDayString()
    local timeOfDay = sm.game.getTimeOfDay()
    local hour = (timeOfDay * 24) % 24
    local minute = (hour % 1) * 60
    local hour1 = math.floor(hour / 10)
    local hour2 = math.floor(hour - hour1 * 10)
    local minute1 = math.floor(minute / 10)
    local minute2 = math.floor(minute - minute1 * 10)

    return hour1 .. hour2 .. ":" .. minute1 .. minute2
end

---Formats seconds in a countdown fromat D:HH:MM (in sm time)
---@param seconds number
---@return string
function formatCountdown(seconds)
    local time = seconds / DAYCYCLE_TIME
    local days = math.floor((time * 24) / 24)
    local hour = (time * 24) % 24
    local minute = (hour % 1) * 60
    local hour1 = math.floor(hour / 10)
    local hour2 = math.floor(hour - hour1 * 10)
    local minute1 = math.floor(minute / 10)
    local minute2 = math.floor(minute - minute1 * 10)

    return days .. "d " .. hour1 .. hour2 .. "h " .. minute1 .. minute2 .. "m"
end

---@return number
function getDayCycleFraction()
    local time = sm.game.getTimeOfDay()

    local index = 1
    while index < #DAYCYCLE_SOUND_TIMES and time >= DAYCYCLE_SOUND_TIMES[index + 1] do
        index = index + 1
    end
    assert(index <= #DAYCYCLE_SOUND_TIMES)

    local night = 0.0
    if index < #DAYCYCLE_SOUND_TIMES then
        local p = (time - DAYCYCLE_SOUND_TIMES[index]) /
            (DAYCYCLE_SOUND_TIMES[index + 1] - DAYCYCLE_SOUND_TIMES[index])
        night = sm.util.lerp(DAYCYCLE_SOUND_VALUES[index], DAYCYCLE_SOUND_VALUES[index + 1], p)
    else
        night = DAYCYCLE_SOUND_VALUES[index]
    end

    return 1.0 - night
end

---@param dayCycleFraction number
---@return integer
function getTicksUntilDayCycleFraction(dayCycleFraction)
    local time = sm.game.getTimeOfDay()
    local timeDiff = (time > dayCycleFraction) and (dayCycleFraction - time) + 1.0 or (dayCycleFraction - time)
    return math.floor(timeDiff * DAYCYCLE_TIME * 40 + 0.5)
end

---Brute force testing of a function for randomizing integer ranges
---@param fn fun(): number
function testRandomFunction(fn)
    local a = {}
    local sum = 0
    for _ = 1, 1000000 do
        local n = fn()
        a[n] = a[n] and a[n] + 1 or 1
        sum = sum + n
    end

    for n, v in pairs(a) do
        print(n, "=", (v / 10000) .. "%")
    end
    print("avg =", sum / 1000000)
end

---Returns a random number with [sm.noise.randomNormalDistribution] used for random stack amount
---@param min number min number returned
---@param mean number the avarage number returned
---@param max number the max number returned
---@return number
function randomStackAmount(min, mean, max)
    return clamp(round(sm.noise.randomNormalDistribution(mean, (max - min + 1) * 0.25)), min, max)
end

---Returns a random number between 1 and 2 with a avarage of 1.
---@return number
function randomStackAmount2()
    return randomStackAmount(1, 1, 2)
end

---Returns a random number between 1 and 3 with a avarage of 2.
---@return number
function randomStackAmountAvg2()
    return randomStackAmount(1, 2, 3)
end

---Returns a random number between 2 and 4 with a avarage of 3.
---@return number
function randomStackAmountAvg3()
    return randomStackAmount(2, 3, 4)
end

---Returns a random number between 2 and 5 with a avarage of 3.5
---@return number
function randomStackAmount5()
    return randomStackAmount(2, 3.5, 5)
end

---Returns a random number between 3 and 7 with a avarage of 5
---@return number
function randomStackAmountAvg5()
    return randomStackAmount(3, 5, 7)
end

---Returns a random number between 5 and 10 with a avarage of 7.5
---@return number
function randomStackAmount10()
    return randomStackAmount(5, 7.5, 10)
end

---Returns a random number between 5 and 15 with a avarage of 10
---@return number
function randomStackAmountAvg10()
    return randomStackAmount(5, 10, 15)
end

---Returns a random number between 10 and 20 with a avarage of 20
---@return number
function randomStackAmount20()
    return randomStackAmount(10, 15, 20)
end

---Gets the tool owner pos
---@param tool Tool
---@return Vec3 the worldPos of the player character
function GetOwnerPosition(tool)
    local playerPosition = sm.vec3.new(0, 0, 0)
    local player = tool:getOwner()
    if player and player.character and sm.exists(player.character) then
        playerPosition = player.character.worldPosition
    end
    return playerPosition
end

---@param self Character
---@param other Character | Shape
---@param vCollisionPosition Vec3 Doesnt do anything
---@param vPointVelocitySelf Vec3
---@param vPointVelocityOther Vec3
---@param vCollisionNormal Vec3
---@param maxhp number
---@param velDiffThreshold number
---@return integer
---@return integer
---@return Vec3
---@return Vec3
function CharacterCollision(self, other, vCollisionPosition, vPointVelocitySelf, vPointVelocityOther, vCollisionNormal,
                            maxhp, velDiffThreshold)
    assert(type(self) == "Character")

    if type(other) == "Character" then
        return 0, 0, sm.vec3.zero(), sm.vec3.zero()
    end

    if type(other) == "Shape" and not sm.exists(other) then
        return 0, 0, sm.vec3.zero(), sm.vec3.zero()
    end

    if type(other) == "Shape" and sm.exists(other) then
        if isIgnoreCollisionShape(other:getShapeUuid()) then
            return 0, 0, sm.vec3.zero(), sm.vec3.zero()
        end
    end

    --print( "------ COLLISION", type( other ), "------" )

    local vVelImpact = (vPointVelocitySelf - vPointVelocityOther)
    local fVelImpact = vVelImpact:length()
    local vDirImpact = vVelImpact / fVelImpact
    local fCosImpactAngle = vDirImpact:dot(-vCollisionNormal)

    local vTumbleVelocity = sm.vec3.zero()
    local vImpactReaction = sm.vec3.zero()

    local fallDamage = 0
    local collisionDamage = 0
    local specialCollisionDamage = 0
    local fallTumbleTicks = 0
    local collisionTumbleTicks = 0
    local specialCollision = false

    -- Fall damage
    local fFallMinVelocity = 18
    local fFallMaxVelocity = 36
    local fFallImpact = math.min(-vVelImpact.z, -vPointVelocitySelf.z) * fCosImpactAngle
    local fFallDamageFraction = clamp((fFallImpact - fFallMinVelocity) / (fFallMaxVelocity - fFallMinVelocity), 0.0, 1.0)
    if fFallDamageFraction > 0.5 then
        fallTumbleTicks = MEDIUM_TUMBLE_TICK_TIME
    end
    if self:isOnGround() then
        -- No fall damage if character is already touching the ground
        fFallDamageFraction = 0
        fallTumbleTicks = 0
    end
    fallDamage = fFallDamageFraction * (maxhp or 100)


    local isSafeShape = false
    if type(other) == "Shape" then
        -- Special damage
        if isDangerousCollisionShape(other:getShapeUuid()) then
            if other.body.angularVelocity:length() > SPINNER_ANGULAR_THRESHOLD then
                specialCollisionDamage = 10
                specialCollision = true
            end
        end

        isSafeShape = isSafeCollisionShape(other:getShapeUuid())
    end


    -- Collision damage
    if not isSafeShape then
        local massSelf = self.mass
        local massOther = 0
        if type(other) == "Shape" and other.body:isDynamic() then
            massOther = other.body.mass
        end

        if fCosImpactAngle > 0.5 then -- At least 30 degree impact angle
            local fVel0Self = vPointVelocitySelf:dot(vDirImpact)
            local fVel0Other = vPointVelocityOther:dot(vDirImpact)

            local fVel1Self
            local fVel1Other

            local fRestitution = 0.3
            local fFriction = 0.3

            if massOther > 0 then
                fVel1Self = (fRestitution * massOther * (fVel0Other - fVel0Self) + massSelf * fVel0Self + massOther * fVel0Other) /
                    (massSelf + massOther)
                fVel1Other = (fRestitution * massSelf * (fVel0Self - fVel0Other) + massSelf * fVel0Self + massOther * fVel0Other) /
                    (massSelf + massOther)
            else
                -- Simplified with massSelf as 0, massOther as 1
                fVel1Self = fRestitution * (fVel0Other - fVel0Self) + fVel0Other
                fVel1Other = fVel0Other
            end

            -- Damage is based on the change in velocity from collision
            local fVelDiffSelf = (fVel1Self - fVel0Self)
            local fVelDiffOther = (fVel1Other - fVel0Other)

            if fVelDiffSelf <= -(velDiffThreshold or 12) then
                collisionDamage = round(0.1885715 * (-fVelDiffSelf) ^ 1.464069)
                if fVelDiffSelf <= -80 then
                    collisionTumbleTicks = LARGE_TUMBLE_TICK_TIME
                elseif fVelDiffSelf <= -48 then
                    collisionTumbleTicks = MEDIUM_TUMBLE_TICK_TIME
                else
                    collisionTumbleTicks = SMALL_TUMBLE_TICK_TIME
                end

                -- Tumble body created with zero velocity
                if vDirImpact:dot(vCollisionNormal) > -0.99802673 then -- 4 degrees
                    local vTangent = vDirImpact:cross(vCollisionNormal)
                    vTangent = (vTangent:cross(vCollisionNormal)):normalize()
                    vTumbleVelocity = (vCollisionNormal * vDirImpact:dot(vCollisionNormal) - vTangent * vDirImpact:dot(vTangent) * fFriction) *
                        fVel1Self
                    --sm.debugDraw.addArrow( "vTangent", vCollisionPosition, vCollisionPosition + vTangent, BLUE )
                else
                    vTumbleVelocity = vDirImpact * fVel1Self
                    --sm.debugDraw.removeArrow( "vTangent" )
                end

                -- Value to slow down whatever hit the character
                vImpactReaction = vDirImpact * fVelDiffOther

                --sm.debugDraw.addArrow( "vCollisionNormal", vCollisionPosition, vCollisionPosition + vCollisionNormal, GREEN )
                --sm.debugDraw.addArrow( "vDirImpact", vCollisionPosition, vCollisionPosition + vDirImpact, RED )

                --sm.debugDraw.addArrow( "vVelImpact", vCollisionPosition - vVelImpact, vCollisionPosition, WHITE )
                --sm.debugDraw.addArrow( "vTumbleVelocity", vCollisionPosition, vCollisionPosition + vTumbleVelocity, CYAN )
                --sm.debugDraw.addArrow( "vImpactReaction", vCollisionPosition, vCollisionPosition + vImpactReaction, MAGENTA )
            end
        end
    end

    local damage = fallDamage > 0 and fallDamage or math.max(collisionDamage, specialCollisionDamage)
    local tumbleTicks = specialCollision and 0 or math.max(fallTumbleTicks, collisionTumbleTicks)

    return damage, tumbleTicks, vTumbleVelocity, vImpactReaction
end

---@param targetCharacter Character
---@param direction Vec3
---@param power number
function ApplyCharacterImpulse(targetCharacter, direction, power)
    local impulseDirection = direction:safeNormalize(sm.vec3.zero())
    if impulseDirection:length2() >= FLT_EPSILON * FLT_EPSILON then
        local massImpulse = power / (5000.0 / 10.0)
        local massImpulseSqrt = power / (5000.0 / 12.0)
        local impulse = math.min(
            targetCharacter.mass * massImpulse + math.sqrt(targetCharacter.mass) * massImpulseSqrt, power)
        impulse = math.min(impulse, MAX_CHARACTER_KNOCKBACK_VELOCITY * targetCharacter.mass)

        if targetCharacter:isTumbling() then
            targetCharacter:applyTumblingImpulse(impulseDirection * impulse)
        else
            sm.physics.applyImpulse(targetCharacter, impulseDirection * impulse)
        end
    end
end

---@param targetCharacter Character
---@param direction Vec3
---@param power number
function ApplyKnockback(targetCharacter, direction, power)
    local impulseDirection = sm.vec3.new(direction.x, direction.y, 0):safeNormalize(sm.vec3.zero())
    if impulseDirection:length2() >= FLT_EPSILON * FLT_EPSILON then
        local rightVector = impulseDirection:cross(sm.vec3.new(0, 0, 1))
        impulseDirection = impulseDirection:rotate(0.523598776, rightVector) -- 30 degrees
    end

    ApplyCharacterImpulse(targetCharacter, impulseDirection, power)
end

---@param worldPosition Vec3
---@param maxDistance number
---@param world World
---@return Player|nil
function GetClosestPlayer(worldPosition, maxDistance, world)
    local closestPlayer = nil
    local closestDd = maxDistance and (maxDistance * maxDistance) or math.huge
    local players = sm.player.getAllPlayers()
    for _, player in ipairs(players) do
        if player.character and player.character:getWorld() == world then
            local dd = (player.character.worldPosition - worldPosition):length2()
            if dd <= closestDd then
                closestPlayer = player
                closestDd = dd
            end
        end
    end
    return closestPlayer
end

local ToolItems = {
    [tostring(tool_connect)] = obj_tool_connect,
    [tostring(tool_paint)] = obj_tool_paint,
    [tostring(tool_weld)] = obj_tool_weld,
    [tostring(tool_spudgun)] = obj_tool_spudgun,
    [tostring(tool_shotgun)] = obj_tool_frier,
    [tostring(tool_gatling)] = obj_tool_spudling,
    [tostring(tool_handbook)] = obj_tool_handbook,
    ["ed185725-ea12-43fc-9cd7-4295d0dbf88b"] = obj_tool_sledgehammer, --Creative sledgehammer
}
---@param toolUuid Uuid
---@return Uuid
function GetToolProxyItem(toolUuid)
    return ToolItems[tostring(toolUuid)]
end

---finds the first Interactable with the provided uuid in all bodies
---@param uuid string shape uuid as a string
---@return Interactable | nil
function FindFirstInteractable(uuid)
    local bodies = sm.body.getAllBodies()
    for _, body in ipairs(bodies) do
        for _, shape in ipairs(body:getShapes()) do
            if tostring(shape:getShapeUuid()) == uuid then
                return shape:getInteractable()
            end
        end
    end
end

---Finds first Interactable with the provided uuid in a cell
---@param uuid string shape uuid as a string
---@param x integer Cell X pos
---@param y integer Cell y pos
---@return Interactable | nil
function FindFirstInteractableWithinCell(uuid, x, y)
    local bodies = sm.body.getAllBodies()
    for _, body in ipairs(bodies) do
        for _, shape in ipairs(body:getShapes()) do
            if tostring(shape:getShapeUuid()) == uuid then
                local ix, iy = getCell(shape:getWorldPosition().x, shape:getWorldPosition().y)
                if ix == x and iy == y then
                    return shape:getInteractable()
                end
            end
        end
    end
end

---Finds all Interactables with provided uuid
---@param uuid string shape uuid as a string
---@param x integer Cell x pos
---@param y integer Cell y pos
---@return Interactable[]
function FindInteractablesWithinCell(uuid, x, y)
    local tbl = {}
    local bodies = sm.body.getAllBodies()
    for _, body in ipairs(bodies) do
        for _, shape in ipairs(body:getShapes()) do
            if tostring(shape:getShapeUuid()) == uuid then
                local ix, iy = getCell(shape:getWorldPosition().x, shape:getWorldPosition().y)
                if ix == x and iy == y then
                    table.insert(tbl, shape:getInteractable())
                end
            end
        end
    end
    return tbl
end

---@param constructionFilters ("terrainSurface" | "terrainAsset" | "body" | "joint")[]
---@alias bool boolean
---@return bool | boolean
---@return Vec3 | nil
---@return Vec3 | nil
function ConstructionRayCast(constructionFilters)
    local valid, result = sm.localPlayer.getRaycast(7.5)
    if valid then
        for _, filter in ipairs(constructionFilters) do
            if result.type == filter then
                local groundPointOffset = -(sm.construction.constants.subdivideRatio_2 - 0.04 + sm.construction.constants.shapeSpacing + 0.005)
                local pointLocal = result.pointLocal + result.normalLocal * groundPointOffset

                -- Compute grid pos
                local size = sm.vec3.new(3, 3, 1)
                local size_2 = sm.vec3.new(1, 1, 0)
                local a = pointLocal * sm.construction.constants.subdivisions
                local gridPos = sm.vec3.new(math.floor(a.x), math.floor(a.y), a.z) - size_2

                -- Compute world pos
                local worldPos = gridPos * sm.construction.constants.subdivideRatio +
                    (size * sm.construction.constants.subdivideRatio) * 0.5

                return valid, worldPos, result.normalWorld
            end
        end
    end
    return false, nil, nil
end

---@alias getWorldObj Character | Body | Harvestable | Player | Unit | Shape | Interactable | Joint | World


---Get the world of an objest provided
---@param userdataObject getWorldObj
---@return World | nil
local function getWorld(userdataObject)
    if not userdataObject or not isAnyOf(type(userdataObject), { "Character", "Body", "Harvestable", "Player", "Unit", "Shape", "Interactable", "Joint", "World" }) then
        sm.log.warning("Tried to get world for an unsupported type: " .. type(userdataObject))
        return nil
    end
    if sm.exists(userdataObject) then return nil end

    return (switch2(type(userdataObject)) {
        ["Character"] = userdataObject:getWorld(),
        ["Body"] = userdataObject:getWorld(),
        ["Harvestable"] = userdataObject:getWorld(),
        ["Player"] = function()
            if userdataObject.character then return userdataObject.character:getWorld() end
            return nil
        end,
        ["Unit"] = function()
            if userdataObject.character then return userdataObject.character:getWorld() end
            return nil
        end,
        ["Shape"] = function()
            if userdataObject.body then return userdataObject.body:getWorld() end
            return nil
        end,
        ["Interactable"] = function()
            if userdataObject.body then return userdataObject.body:getWorld() end
            return nil
        end,
        ["Joint"] = function()
            local hostShape = userdataObject:getShapeA()
            if hostShape and hostShape.body then
                return hostShape.body:getWorld()
            end
            return nil
        end,
        ["World"] = userdataObject
    })
end

---Checks if two objects are in the same world
---@param userdataObjectA getWorldObj
---@param userdataObjectB getWorldObj
---@return boolean
function InSameWorld(userdataObjectA, userdataObjectB)
    local worldA = getWorld(userdataObjectA)
    local worldB = getWorld(userdataObjectB)

    local result = (worldA ~= nil and worldB ~= nil and worldA == worldB)
    return result
end

---@param worldPosition Vec3
---@param radius number
---@param attackLevel integer
---@return Shape | nil
---@return Vec3 | nil
function FindAttackableShape(worldPosition, radius, attackLevel)
    local nearbyShapes = sm.shape.shapesInSphere(worldPosition, radius)
    local destructableNearbyShapes = {}
    for _, shape in ipairs(nearbyShapes) do
        local shapeQualityLevel = sm.item.getQualityLevel(shape.shapeUuid)
        if shape.destructable and attackLevel >= shapeQualityLevel and shapeQualityLevel > 0 then
            destructableNearbyShapes[#destructableNearbyShapes + 1] = shape
        end
    end
    if #destructableNearbyShapes > 0 then
        local targetShape = destructableNearbyShapes[math.random(1, #destructableNearbyShapes)]
        local targetPosition = targetShape.worldPosition
        if sm.item.isBlock(targetShape.shapeUuid) then
            local targetLocalPosition = targetShape:getClosestBlockLocalPosition(worldPosition)
            targetPosition = targetShape.body:transformPoint((targetLocalPosition + sm.vec3.new(0.5, 0.5, 0.5)) * 0.25)
        end
        return targetShape, targetPosition
    end
    return nil, nil
end

---@param array number[]
---@param targetValue number
---@return integer
function BinarySearchInterval(array, targetValue)
    local lowerBound = 1
    local upperBound = #array
    if targetValue < array[lowerBound] then
        return lowerBound -- Clamp to lower index
    elseif targetValue > array[upperBound] then
        return upperBound -- Clamp to upper index
    end

    while lowerBound <= upperBound do
        local middleIndex = math.floor((lowerBound + upperBound) * 0.5)
        if array[middleIndex] < targetValue then
            lowerBound = middleIndex + 1
        elseif array[middleIndex] > targetValue then
            upperBound = middleIndex - 1
        else
            return middleIndex -- Found exact value
        end
    end
    return upperBound -- No exact value, return the interval index
end

---@param vector Vec3
---@param xAxis Vec3
---@param zAxis Vec3
---@param inverse boolean
---@return Vec3
function RotateAxis(vector, xAxis, zAxis, inverse)
    local yAxis = zAxis:cross(xAxis)
    if inverse then
        -- Transpose rotation matrix
        return sm.vec3.new(
            vector.x * xAxis.x + vector.y * xAxis.y + vector.z * xAxis.z,
            vector.x * yAxis.x + vector.y * yAxis.y + vector.z * yAxis.z,
            vector.x * zAxis.x + vector.y * zAxis.y + vector.z * zAxis.z
        )
    end
    return sm.vec3.new(
        vector.x * xAxis.x + vector.y * yAxis.x + vector.z * zAxis.x,
        vector.x * xAxis.y + vector.y * yAxis.y + vector.z * zAxis.y,
        vector.x * xAxis.z + vector.y * yAxis.z + vector.z * zAxis.z
    )
end

---@param minSticky Vec3
---@param maxSticky Vec3
---@param xAxis Vec3
---@param zAxis Vec3
---@param inverse boolean
---@return Vec3
---@return Vec3
function RotateSticky(minSticky, maxSticky, xAxis, zAxis, inverse)
    local minFlags = RotateAxis(minSticky, xAxis, zAxis, inverse)
    local maxFlags = RotateAxis(maxSticky, xAxis, zAxis, inverse)

    local NX = (minFlags.x > 0 or maxFlags.x < 0) and 1 or 0
    local NY = (minFlags.y > 0 or maxFlags.y < 0) and 1 or 0
    local NZ = (minFlags.z > 0 or maxFlags.z < 0) and 1 or 0
    local PX = (maxFlags.x > 0 or minFlags.x < 0) and 1 or 0
    local PY = (maxFlags.y > 0 or minFlags.y < 0) and 1 or 0
    local PZ = (maxFlags.z > 0 or minFlags.z < 0) and 1 or 0

    local rotatedMinSticky = sm.vec3.new(NX, NY, NZ)
    local rotatedMaxSticky = sm.vec3.new(PX, PY, PZ)
    return rotatedMinSticky, rotatedMaxSticky
end

local EasyDifficultySettings =
{
    playerTakeDamageMultiplier = 0.5
}
local NormalDifficultySettings =
{
    playerTakeDamageMultiplier = 1.0
}

---@class DifficultySettings
---@field playerTakeDamageMultiplier number

---Gets the current selected difficulty settings
---@return DifficultySettings
function GetDifficultySettings()
    local difficulties = { EasyDifficultySettings, NormalDifficultySettings }
    local difficultyIndex = sm.game.getDifficulty()
    if difficultyIndex < 0 then
        difficultyIndex = 2                   -- Default to Normal difficulty
    else
        difficultyIndex = difficultyIndex + 1 -- Lua index
    end
    return difficulties[difficultyIndex]
end

---@param character Character
---@param bone string
---@param debrisEffect string
---@param offsetPos Vec3
---@param offsetRot Quat
function SpawnDebris(character, bone, debrisEffect, offsetPos, offsetRot)
    local bonePos = character:getTpBonePos(bone)
    local boneRot = character:getTpBoneRot(bone)

    local position = offsetPos and bonePos + boneRot * offsetPos or bonePos
    local rotation = offsetRot and boneRot * offsetRot or boneRot

    local relPos = position - character.worldPosition

    local velocity = relPos:safeNormalize(sm.vec3.new(0, 0, 1)) * (math.random() + 1) * 2 +
        sm.vec3.new(0, 0, math.random() + 2) + character.velocity
    local color = character:getColor()

    sm.effect.playEffect(debrisEffect, position, velocity, rotation, nil, { Color = color, startVelocity = velocity })
end
