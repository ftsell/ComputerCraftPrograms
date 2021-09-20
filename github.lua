local completion = require("cc.shell.completion")

shell.setCompletionFunction(fs.getName(shell.getRunningProgram()), completion.build(
        { completion.choice, { "get", "run" } },
        nil,
        nil,
        nil,
        completion.file
))

local function printUsage()
    local programName = arg[0] or fs.getName(shell.getRunningProgram())
    print("Usages:")
    print(programName .. " get <Github user> <Github repo> <path in repo>")
    print(programName .. " get <Github user> <Github repo> <path in repo> <local name>")
    print(programName .. " run <Github user> <Github repo> <path in repo>")
    print(programName .. " run <Github user> <Github repo> <path in repo> <program arguments> ...")
end

local tArgs = { ... }

if #tArgs < 2 then
    printUsage()
    return
end

if not http then
    printError("github requires the http API")
    printError("Set htt.enabled to true in CC:Tweaked's config")
    return
end

local function get(user, repo, pathInRepo)
    write("Connecting to github.com...")
    local cacheBuster = ("%x"):format(math.random(0, 2 ^ 30))
    local response, err = http.get("https://raw.github.com/"
            .. textutils.urlEncode(user)
            .. "/"
            .. textutils.urlEncode(repo)
            .. "/main/"
            .. textutils.urlEncode(pathInRepo)
            .. "?cb=" .. cacheBuster)

    if not response then
        io.stderr.write("Failed\n")
        print(err)
        return
    end

    local headers = response.getResponseHeaders()
    if not headers["Content-Type"] or not headers["Content-Type"]:find("^text/plain") then
        io.stderr.write("Failed\n")
        print("Github did not return text/plain content type")
        return
    end

    print("Success")

    local sResponse = response.readAll()
    response.close()
    return sResponse
end

local function writeProgram(path, content)
    if fs.exists(path) then
        fs.delete(path)
    end

    local file = fs.open(path, "w")
    file.write(content)
    file.close()
end

if tArgs[1] == "get" then
    -- Download a file from github.com
    if #tArgs ~= 5 and #tArgs ~= 6 then
        printUsage()
        return
    end

    -- Get program content
    local githubUser = tArgs[2]
    local githubRepo = tArgs[3]
    local fileInRepo = tArgs[4]
    local localFile = shell.resolve(tArgs[5] or fileInRepo)
    local response = get(githubUser, githubRepo, fileInRepo)

    -- Save downloaded program
    if response then
        writeProgram(localFile, response)
        print("Downloaded as " .. localFile)
    end

elseif tArgs[1] == "run" then
    -- Directly run a file from github.com
    if #tArgs ~= 5 then
        printUsage()
        return
    end

    -- Get program content
    local githubUser = tArgs[2]
    local githubRepo = tArgs[3]
    local fileInRepo = tArgs[4]
    local response = get(githubUser, githubRepo, fileInRepo)

    -- Execute downloaded program
    if response then
        local func, err = load(res, fileInRepo, "t", _ENV)
        if not func then
            printError(err)
            return
        end

        local success, msg = pcall(func, select(4, ...))
        if not success then
            printError(msg)
        end
    end
else
    -- print usage
    printUsage()
    return
end
