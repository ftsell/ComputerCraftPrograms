local function printUsage()
    local programName = fs.getName(shell.getRunningProgram())
    print("Usages:")
    print(programName .. " <width> <depth> <height>")
end

local tArgs = { ... }
if #tArgs ~= 3 then
    printUsage()
    return
end

if not turtle then
    printError("Requires a turtle")
    return
end

local roomWidth = tonumber(tArgs[1])
local roomDepth = tonumber(tArgs[2])
local roomHeight = tonumber(tArgs[3])

if roomWidth < 1 or roomDepth < 1 or roomHeight < 1 then
    printError("Room width, depth and height must be positive integers")
    return
end

local collected = 0

local function collect()
    collected = collected + 1
    if math.fmod(collected, 25) == 0 then
        print("Mined " .. collected .. " items")
    end
end

local function tryDig()
    -- dig for as long as there are blocks in front of us (in case things like gravel fill the just dug spot)
    while turtle.detect() do
        if turtle.dig() then
            collect()
            sleep(0.5)
        else
            return false
        end
    end
    return true
end

local function tryDigUp()
    -- dig for as long as there are blocks in front of us (in case things like gravel fill the just dug spot)
    while turtle.detectUp() do
        if turtle.digUp() then
            collect()
            sleep(0.5)
        else
            return false
        end
    end
    return true
end

local function tryDigDown()
    -- dig for as long as there are blocks in front of us (in case something fills the just dug spot)
    while turtle.detectDown() do
        if turtle.digDown() then
            collect()
            sleep(0.5)
        else
            return false
        end
    end
    return true
end

local function refuel()
    -- only refuel if we need to
    local fuelLevel = turtle.getFuelLevel()
    if fuelLevel == "unlimited" or fuelLevel > 0 then
        return
    end

    -- cycle through every inventory slot to find fuel
    local function tryRefuel()
        for n = 1, 16 do
            if turtle.getItemCount(n) > 0 then
                turtle.select(n)
                if turtle.refuel(1) then
                    turtle.select(1)
                    return true
                end
            end
        end
        turtle.select(1)
        return false
    end

    -- try to refuel and wait until something gets put into inventory if refueling is not yet possible
    if not tryRefuel() then
        print("Add more fuel to continue.")
        while not tryRefuel() do
            os.pullEvent("turtle_inventory")
        end
        print("Resuming Tunnel.")
    end
end

local function tryUp()
    refuel()
    while not turtle.up() do
        if turtle.detectUp() then
            if not tryDigUp() then
                return false
            end
        elseif turtle.attackUp() then
            collect()
        else
            sleep(0.5)
        end
    end
    return true
end

local function tryDown()
    refuel()
    while not turtle.down() do
        if turtle.detectDown() then
            if not tryDigDown() then
                return false
            end
        elseif turtle.attackDown() then
            collect()
        else
            sleep(0.5)
        end
    end
    return true
end

local function tryForward()
    refuel()
    while not turtle.forward() do
        if turtle.detect() then
            if not tryDig() then
                return false
            end
        elseif turtle.attack() then
            collect()
        else
            sleep(0.5)
        end
    end
    return true
end

print("Excavating...")

-- move to bottom-left-front edge of room
turtle.turnLeft()
for n = 1, roomWidth / 2 do
    tryForward()
end
turtle.turnRight()

-- excavate room
for z = 1, roomHeight do
    -- excavate one level
    for y = 1, roomDepth do
        -- excavate from left to right
        turtle.turnRight()
        for x = 2, roomWidth do
            tryForward()
        end
        turtle.turnLeft()

        -- move back
        turtle.turnLeft()
        for x = 2, roomWidth do
            tryForward()
        end
        turtle.turnRight()

        -- move to next row if another one is needed
        if y < roomDepth then
            tryForward()
        end
    end

    -- move back
    turtle.turnLeft()
    turtle.turnLeft()
    for y = 2, roomDepth do
        tryForward()
    end
    turtle.turnRight()
    turtle.turnRight()

    -- move to next level if another one is needed
    if z < roomHeight then
        tryUp()
    end
end

-- move back
for z = 2, roomHeight do
    tryDown()
end

print("Room complete")
print("Mined " .. collected .. " items total")
print("Room is " .. roomWidth * roomDepth * roomHeight .. " blocks large")
