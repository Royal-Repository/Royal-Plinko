local QBCore = exports['qb-core']:GetCoreObject()

-- Store pending wins to prevent cheating (Server Authoritative)
local ActiveGames = {}

QBCore.Functions.CreateCallback('plinko:server:play', function(source, cb, data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    local betPerBall = tonumber(data.bet)
    local risk = data.risk
    local ballCount = tonumber(data.balls) or 1

    if not Player then return cb({status = false, msg = "Player not found"}) end
    if not betPerBall or betPerBall <= 0 then return cb({status = false, msg = "Invalid bet"}) end
    if ballCount < 1 or ballCount > Config.MaxBallCount then return cb({status = false, msg = "Invalid ball count"}) end
    
    local totalBet = betPerBall * ballCount
    if totalBet > Player.PlayerData.money.cash then return cb({status = false, msg = "Insufficient funds"}) end
    if not Config.Risk[risk] then return cb({status = false, msg = "Invalid risk level"}) end

    -- 1. Deduct Money IMMEDIATELY (Prevents betting money you don't have)
    Player.Functions.RemoveMoney('cash', totalBet, "Plinko Bet")

    -- 2. Calculate Results
    local results = {}
    local totalWinForBatch = 0
    local riskTable = Config.Probabilities[risk]
    local payoutTable = Config.Risk[risk].payouts
    
    local totalWeight = 0
    for _, weight in pairs(riskTable) do totalWeight = totalWeight + weight end

    for b = 1, ballCount do
        local randomVal = math.random(1, totalWeight)
        local currentWeight = 0
        local winningSlot = 9 -- Default Center

        for i, weight in ipairs(riskTable) do
            currentWeight = currentWeight + weight
            if randomVal <= currentWeight then
                winningSlot = i
                break
            end
        end

        local multiplier = payoutTable[winningSlot]
        local winAmount = math.floor(betPerBall * multiplier)
        
        totalWinForBatch = totalWinForBatch + winAmount
        
        table.insert(results, {
            slot = winningSlot,
            multiplier = multiplier,
            win = winAmount
        })
    end

    -- 3. Store the win, but DO NOT give it yet.
    -- We wait for the client to finish animation so the "Item Added" notification syncs with visuals.
    ActiveGames[src] = totalWinForBatch

    cb({
        status = true,
        results = results,
        -- Send current balance (minus bet) so UI updates correctly
        newBalance = Player.Functions.GetMoney('cash') 
    })
end)

-- Called by Client when balls finish dropping
RegisterNetEvent('plinko:server:payout', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    -- Security Check: Does the player have a pending game?
    if ActiveGames[src] then
        local winAmount = ActiveGames[src]
        
        if winAmount > 0 then
            Player.Functions.AddMoney('cash', winAmount, "Plinko Win")
        end
        
        -- Clear the game so they can't claim twice
        ActiveGames[src] = nil
    else
        -- Potential cheat attempt or lag
        print("Plinko: No active game found for player " .. src)
    end
end)