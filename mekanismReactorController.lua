local function bool2yesno(bool)
    if bool then
        return "yes"
    else
        return "no"
    end
end


local function defineSettings()
    settings.define("ReactorActivationSide", {
        description = "The side that is connected to the reactor logic adapter that is configured as 'Activation'",
        type = "string"
    })
    settings.define("ReactorHighTemperatureSide", {
        description = "The side that is connected to the reactor logic adapter that is configured as 'High Temperature'",
        type = "string"
    })
    settings.define("ReactorInsufficientFuelSide", {
        description = "The side that is connected to the reactor logic adapter that is configured as 'Insufficient Fuel'",
        type = "string"
    })
    settings.define("DamageCriticalSide", {
        description = "The side that is connected to the reactor logic adapter that is configured as 'Damage Critical'",
        type = "string"
    })
    settings.define("ExcessWasteSide", {
        description = "The side that is connected to the reactor logic adapter that is configured as 'Excess Waste'",
        type = "string"
    })
end


local function isReactorOn()
    return redstone.getOutput(settings.get("ReactorActivationSide"))
end

local function setReactorState(state)
    redstone.setOutput(settings.get("ReactorActivationSide"), state)
end

local function isTemperatureHigh()
    return redstone.getInput(settings.get("ReactorHighTemperatureSide"))
end

local function isFuelInsufficient()
    return redstone.getInput(settings.get("ReactorInsufficientFuelSide"))
end

local function hasExcessWaste()
    return redstone.getInput(settings.get("ExcessWasteSide"))
end

local function isDamageCritical()
    return redstone.getInput(settings.get("DamageCriticalSide"))
end


local function printSettings()
    term.write("Reactor Activation Side            ")
    term.write(settings.get("ReactorActivationSide"))
    print()

    term.write("Reactor High Temperature Side      ")
    term.write(settings.get("ReactorHighTemperatureSide"))
    print()

    term.write("Reactor Insufficient Fuel Side     ")
    term.write(settings.get("ReactorInsufficientFuelSide"))
    print()

    term.write("Reactor Excess Waste Side          ")
    term.write(settings.get("ExcessWasteSide"))
    print()

    term.write("Reactor Damage Critical Side       ")
    term.write(settings.get("DamageCriticalSide"))
    print()
end

local function printState()
    term.write("Reactor active                     ")
    term.write(bool2yesno(isReactorOn()))
    print()

    term.write("High temperature                   ")
    term.write(bool2yesno(isTemperatureHigh()))
    print()

    term.write("Insufficient fuel                  ")
    term.write(bool2yesno(isFuelInsufficient()))
    print()

    term.write("Excess waste                       ")
    term.write(bool2yesno(hasExcessWaste()))
    print()

    term.write("Critical Damage                    ")
    term.write(bool2yesno(isDamageCritical()))
    print()
end


-- Main entry point
defineSettings()
while true do
    term.clear()
    term.setCursorPos(1, 1)
    printSettings()
    print()
    print()
    printState()
    print()
    print()

    if isTemperatureHigh() or hasExcessWaste() or isDamageCritical() then
        print("Turning reactor off to prevent damage")
        setReactorState(false)
    else
        if isFuelInsufficient() then
            print("Turning reactor off because there is no fuel")
            setReactorState(false)
        else
            print("Turning reactor on")
            setReactorState(true)
        end
    end

    sleep(0.5)
end
