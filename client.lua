local balls = {}
local triStart
local ballSize
local ballVelocities = {}
local ballCoords = {}
local leftBorder = 0
local rightBorder = 0
local topBorder = 0
local bottomBorder = 0
local collisionDecrease = 0.03
local camHandle = nil
local powerLevel = 0
local tableHash = GetHashKey("prop_pooltable_02")
local ballHashes = {GetHashKey("prop_poolball_1")}

-- Performance stuff
local sin = math.sin
local cos = math.cos
local atan2 = math.atan2
local abs = math.abs
local pi = math.pi

-- Cam stuff
local playerPed = PlayerPedId()
local playerCoords = nil



function pushBall()
    Citizen.CreateThread(function()
        local camCoords = GetCamCoord(camHandle)
        local camDifference = vector3(camCoords.x,camCoords.y,0)- GetEntityCoords(whiteBallHandle)
        ballVelocities[1] = (-norm(vector3(camDifference.x, camDifference.y, 0)))*(8*powerLevel)
        local isDone = false
        local previousTimer = GetGameTimer()
        local frameCounter = 0
        for i=1,#balls,1  do
            ballCoords[i] = GetEntityCoords(balls[i])
        end
        while not isDone do
            
            local currentTimer = GetGameTimer()
            local delta = currentTimer - previousTimer + frameCounter
           
            frameCounter = 0
            local deltaTimeInS = (20/1000)
            while(delta >= 20) do
                
                local counter = 0
                
                handleCollisions(deltaTimeInS)
                for i=1,#balls,1 do
                    ballVelocities[i] =  ballVelocities[i] * (1-collisionDecrease)
                    if(abs(ballVelocities[i].x) < 0.006 and abs(ballVelocities[i].y) < 0.006) then
                        ballVelocities[i] = vector3(0, 0, 0)
          
                        counter = counter + 1
                    end
                    local entityCoord = ballCoords[i]
                    local ballVelocitiesDelta = entityCoord + (ballVelocities[i]*deltaTimeInS)
                    checkWalls(i, ballVelocitiesDelta)
                    ballCoords[i] = entityCoord + (ballVelocities[i]*deltaTimeInS)
                    SetEntityCoords(balls[i], ballCoords[i].x, ballCoords[i].y, ballCoords[i].z)
                    SetEntityVelocity(balls[i], ballVelocities[i].x, ballVelocities[i].y, ballVelocities[i].z)
                end
                previousTimer = currentTimer
                if(counter == #balls) then
                    isDone = true
                end
                delta = delta - 20
            end
            frameCounter = frameCounter + delta
            Wait(0)
        end

      end) 
    
end


function spawnTable(debug)
    local ret = spawnModel(tableHash, false)
    tableLoc = ret[1]
    poolHandle = ret[2]
    
    local min, max = GetModelDimensions(tableHash)
    local tableSize = max - min 
    -- 0.82
    leftBorder = tableLoc.x-0.82
    -- 0.62
    rightBorder = tableLoc.x+0.68
    -- 1.20
    topBorder =  tableLoc.y-1.22
    -- 1.45
    bottomBorder = tableLoc.y+1.47
    if(debug) then
        Citizen.CreateThread(function()
            while true do
                DrawMarker(0, tableLoc.x-0.82, tableLoc.y-1.26, tableLoc.z + 0.9064026, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 255, 128, 0, 50, false, true, 2, nil, nil, false)
                DrawMarker(0, tableLoc.x-0.82, tableLoc.y+1.50, tableLoc.z + 0.9064026, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 255, 128, 0, 50, false, true, 2, nil, nil, false)
                DrawMarker(0, tableLoc.x+0.68, tableLoc.y-1.26, tableLoc.z + 0.9064026, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 255, 128, 0, 50, false, true, 2, nil, nil, false)
                DrawMarker(0, tableLoc.x+0.68, tableLoc.y+1.50, tableLoc.z + 0.9064026, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 255, 128, 0, 50, false, true, 2, nil, nil, false)
                DrawLine(leftBorder, tableLoc.y-1.11, tableLoc.z + 0.9064026, leftBorder, tableLoc.y+1.38, tableLoc.z + 0.9064026, 0, 255, 0, 0.2)
                DrawLine(rightBorder, tableLoc.y-1.11, tableLoc.z + 0.9064026, rightBorder, tableLoc.y+1.38, tableLoc.z + 0.9064026, 0, 0, 255, 0.2)
                DrawLine(tableLoc.x-0.72, tableLoc.y-1.22, tableLoc.z + 0.9064026, tableLoc.x+0.62, tableLoc.y-1.22, tableLoc.z + 0.9064026, 0, 255, 0, 0.2)
                DrawLine(tableLoc.x-0.72, tableLoc.y+1.47, tableLoc.z + 0.9064026, tableLoc.x+0.62, tableLoc.y+1.47, tableLoc.z + 0.9064026, 0, 0, 255, 0.2)
                Wait(1)
            end
        end)
    end
end
function spawnBall(hashKey, coords, isLoaded)
    local ret = spawnModel(hashKey, coords, isLoaded)
    return ret
end

function checkWalls(index, newPos) 
    if((newPos.x < leftBorder) or (newPos.x > rightBorder)) then
        ballVelocities[index] = vector3(-(ballVelocities[index]).x, ballVelocities[index].y, ballVelocities[index].z)*0.97
    end
    if((newPos.y < topBorder) or (newPos.y  > bottomBorder)) then
        ballVelocities[index] = vector3(ballVelocities[index].x, -(ballVelocities[index]).y, ballVelocities[index].z)*0.97
    end
end
function crossProduct(v1,v2) 
    return vector3(v1.y*v2.z-v1.z*v2.y, v1.z*v2.x-v1.x*v2.z,v1.x*v2.y-v1.y*v2.x)
end
function handleCollisions(delta) 
    for i=1,#balls,1 
    do 
        local firstBall = balls[i]
        
        for j=i+1,#balls,1 
        do 
            local firstBallCoords = ballCoords[i]
            local secondBall = balls[j]
            local secondBallCoords = ballCoords[j]
            local newOne = firstBallCoords + ballVelocities[i] * delta
            local newTwo = secondBallCoords + ballVelocities[j] * delta
            local n = newOne - newTwo
            local distance = #n
            
            --06861172
            --08861172
            --085
            if(distance <= 0.085 ) then
                local power = (abs(ballVelocities[i].x) + abs(ballVelocities[i].y)) + (abs(ballVelocities[j].x) + abs(ballVelocities[j].y)); 
                --power = power * 0.00482;
                power = power * 0.00682;
                local opposite = firstBallCoords.y - secondBallCoords.y;
                local adjacent = firstBallCoords.x - secondBallCoords.x;
                local rotation = atan2(opposite, adjacent);
                local velocity2 = vector3(90*cos(rotation + pi)*power,90*sin(rotation + pi)*power,0);
                ballVelocities[j] = (ballVelocities[j] + velocity2) * (1-collisionDecrease);
               
                local velocity1 = vector3(90*cos(rotation)*power,90*sin(rotation)*power, 0);
                ballVelocities[i] = (ballVelocities[i] + velocity1) * (1-collisionDecrease);
            end
        end
     
    end
end

local angleY = 0.0
local angleZ = 0.0
local start = nil

Citizen.CreateThread(function()
    local mainTimer = GetGameTimer()
    while true do
        local tempTimer = GetGameTimer()
        local deltaTimer =  GetGameTimer() - mainTimer
        
        if (start) then
            ProcessCamControls()
            if (IsControlPressed(0, 29)) then
                powerLevel = powerLevel + (0.1*(deltaTimer/1000))
                print(powerLevel)
                SendNUIMessage({
                    type = "power",
                    power = powerLevel
                })
            else
                if (IsControlPressed(0, 26)) then
                    powerLevel = powerLevel - (0.1*(deltaTimer/1000))
                    print(powerLevel)
                    SendNUIMessage({
                        type = "power",
                        power = powerLevel
                    })
                end
            end
            if(IsControlJustPressed(0, 23)) then
                pushBall()
            end
        end
        mainTimer = tempTimer
        Wait(1)
    end
end)

function ProcessCamControls()
    local newPos = ProcessNewPosition()

    -- focus cam area
    SetFocusArea(newPos.x, newPos.y, newPos.z, 0.0, 0.0, 0.0)
    
    -- set coords of cam 
    SetCamCoord(camHandle, newPos.x, newPos.y, newPos.z)

    -- set rotation
    PointCamAtCoord(camHandle, GetEntityCoords(whiteBallHandle))
end
function ProcessNewPosition()
    local mouseX = 0.0
    local mouseY = 0.0
    
    -- keyboard
    if (IsInputDisabled(0)) then
        -- rotation
        mouseX = GetDisabledControlNormal(1, 1) * 8.0
        mouseY = GetDisabledControlNormal(1, 2) * 8.0
        
    -- controller
    else
        -- rotation
        mouseX = GetDisabledControlNormal(1, 1) * 1.5
        mouseY = GetDisabledControlNormal(1, 2) * 1.5
    end

    angleZ = angleZ - mouseX -- around Z axis (left / right)
    angleY = angleY + mouseY -- up / down
    -- limit up / down angle to 90°
    if (angleY > 89.0) then angleY = 89.0 elseif (angleY < -89.0) then angleY = -89.0 end
    
    local pCoords = GetEntityCoords(whiteBallHandle)
    
    local behindCam = {
        x = pCoords.x + ((cos(angleZ * (pi / 180)) * cos(angleY* (pi / 180))) + (cos(angleY*(pi / 180)) * cos(angleZ*(pi / 180)))) / 2 * (1.5 + 0.5),
        y = pCoords.y + ((sin(angleZ* (pi / 180)) * cos(angleY* (pi / 180))) + (cos(angleY*(pi / 180)) * sin(angleZ*(pi / 180)))) / 2 * (1.5 + 0.5),
        z = pCoords.z + ((sin(angleY*(pi / 180)))) * (1.5 + 0.5)
    }

    local maxRadius = 1.5
    
    local offset = {
        x = ((cos(angleZ*(pi / 180)) * cos(angleY*(pi / 180))) + (cos(angleY*(pi / 180)) * cos(angleZ*(pi / 180)))) / 2 * maxRadius,
        y = ((sin(angleZ*(pi / 180)) * cos(angleY*(pi / 180))) + (cos(angleY*(pi / 180)) * sin(angleZ*(pi / 180)))) / 2 * maxRadius,
        z = ((sin(angleY*(pi / 180)))) * maxRadius
    }
    
    local pos = {
        x = pCoords.x + offset.x,
        y = pCoords.y + offset.y,
        z = pCoords.z + offset.z
    }
    return pos
end



tableLoc = nil
poolHandle = nil
whiteBallHandle = nil

function spawnModel(hashName, loc, isLoaded)
    local handle = nil
    if(not isLoaded) then
        RequestModel(hashName);
        while(not HasModelLoaded(hashName)) 
        do
            Wait(0)
        end
    end
    local v1 = nil
    if(loc) then
        v1 = loc
        handle = CreateObject(hashName, loc.x, loc.y, loc.z, true, true, false)
    else
        local hit = exports['raycast-test']:RaycastCam(1000)
        local coords = hit[2]
        v1 = vector3(coords[1], coords[2], coords[3])
        local modelName = modelName
        handle = CreateObject(hashName, v1.x, v1.y, v1.z, true, true, false)
    end
    return {v1, handle}
end

RegisterCommand("attachCam", function(source, args, rawCommand)
    camHandle = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    start = true
   
    if(whiteBallHandle) then
        playerCoords = GetEntityCoords(playerPed)
        SetCamCoord(camHandle, GetEntityCoords(whiteBallHandle)+vector3(0,-1,0.7))
       -- AttachCamToEntity(camHandle, whiteBallHandle, vector3(0,-1,0.7),true)
        SetCamRot(camHandle, vector3(-35, 0, 0.0), 2)
     
            RenderScriptCams(true, false, 0, 1, 0)
        
    end

end, false)
RegisterCommand("returnCam", function(source, args, rawCommand)
    start = false
    RenderScriptCams(false, false, 0, 1, 0)
end, false)

RegisterCommand("spawnTable", function(source, args, rawCommand)
    spawnTable(args[1], false)
end, false)
RegisterCommand("spawnModel", function(source, args, rawCommand)
    local retval = spawnModelCommand(args[1], false)
   
end, false)

RegisterCommand("spawnBalls", function(source, args, rawCommand)
    local ballMin, ballMax = GetModelDimensions(ballHashes[1])
    -- prop_golf_ball
    ballSize = ballMax - ballMin
    local ret = spawnBall(ballHashes[1], tableLoc - vector3(0.07446289, 0.551758, -0.9064026), false)
    whiteBallHandle = ret[2]
    
    for i=1, 16, 1 do
        ballVelocities[i] = vector3(0, 0, 0)
    end
    table.insert(balls, ret[2])
  
    triStart = tableLoc - vector3(0.07446289, -0.41833594, -0.9064026)
 
    ret = spawnBall(ballHashes[1], triStart, false)
    table.insert(balls, ret[2])
    
    ret = spawnBall(ballHashes[1], triStart + vector3(0.04,0.08,0), false)
    table.insert(balls, ret[2])
  
    ret = spawnBall(ballHashes[1], triStart + vector3(-0.04,0.08,0), false)
    table.insert(balls, ret[2])
 
    ret = spawnBall(ballHashes[1], triStart + 2*vector3(-0.04,0.08,0), false)
    table.insert(balls, ret[2])
   
    ret = spawnBall(ballHashes[1], triStart + 2*vector3(0,0.08,0), false)
    table.insert(balls, ret[2])
   
    ret = spawnBall(ballHashes[1], triStart + 2*vector3(0.04,0.08,0), false)
    table.insert(balls, ret[2])
    
    ret = spawnBall(ballHashes[1], triStart + 3*vector3(0.04,0.08,0), false)
    table.insert(balls, ret[2])
   
    ret = spawnBall(ballHashes[1], triStart + vector3(0.04,0.24,0), false)
    table.insert(balls, ret[2])
    
    ret = spawnBall(ballHashes[1], triStart +  vector3(-0.04,0.24,0), false)
    table.insert(balls, ret[2])
   
    ret = spawnBall(ballHashes[1], triStart + 3*vector3(-0.04,0.08,0), false)
    table.insert(balls, ret[2])
   
    ret = spawnBall(ballHashes[1], triStart + 4*vector3(0.04,0.08,0), false)
    table.insert(balls, ret[2])
    
    ret = spawnBall(ballHashes[1], triStart + vector3(0.08,0.32,0), false)
    table.insert(balls, ret[2])
    
    ret = spawnBall(ballHashes[1], triStart + vector3(0, 0.32,0), false)
    table.insert(balls, ret[2])

    ret = spawnBall(ballHashes[1], triStart + vector3(-0.08,0.32,0), false)
    table.insert(balls, ret[2])

    ret = spawnBall(ballHashes[1], triStart + 4*vector3(-0.04,0.08,0), false)
    table.insert(balls, ret[2])

    for i=1,#balls,1 
    do 
        local firstBall = balls[i]     
        
        for j=i+1,#balls,1 
        do 
            local secondBall = balls[j]
            SetEntityNoCollisionEntity(firstBall, secondBall, false)
        end
    end
end, false)

RegisterCommand("pushBall", pushBall, false)