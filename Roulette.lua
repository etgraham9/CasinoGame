math.randomseed(os.time())

-- COLORS
local redSet = {
    [1]=true,[3]=true,[5]=true,[7]=true,[9]=true,[12]=true,[14]=true,[16]=true,
    [18]=true,[19]=true,[21]=true,[23]=true,[25]=true,[27]=true,[30]=true,
    [32]=true,[34]=true,[36]=true
}

local function pocketColor(n)
    if n == 0 then return "green" end
    if redSet[n] then return "red" end
    return "black"
end

local function input(prompt)
    io.write(prompt)
    io.flush()
    local line = io.read()
    if not line then return "" end
    return (line:gsub("^%s*(.-)%s*$", "%1"))
end

local function spinWheel()
    local n = math.random(0, 36)
    local c = pocketColor(n)
    return n, c
end

-- PAYOUT
local multipliers = {
    number = 35,
    color = 1,
    evenodd = 1,
    dozen = 2,
    highlow = 1
}

-- INFO
local function printBetHelp()
    print("Bet types:")
    print("  number    - bet on a single number 0-36 (pays 35:1)")
    print("  color     - bet 'red' or 'black' (pays 1:1)")
    print("  odd/even  - bet 'odd' or 'even' (pays 1:1). Note: 0 is neither.")
    print("  dozen     - bet '1' (1-12), '2' (13-24), or '3' (25-36) (pays 2:1)")
    print("  highlow   - bet 'high' (19-36) or 'low' (1-18) (pays 1:1). 0 loses.")
    print("Type 'quit' to leave the game.")
end

-- LOGIC
local function evaluateBet(betType, betChoice, spunNumber, spunColor)
    if betType == "number" then
        local n = tonumber(betChoice)
        return n ~= nil and n == spunNumber
    elseif betType == "color" then
        return betChoice == spunColor
    elseif betType == "odd" or betType == "even" or betType == "evenodd" then
        if spunNumber == 0 then return false end
        if betChoice == "odd" then return spunNumber % 2 == 1 end
        if betChoice == "even" then return spunNumber % 2 == 0 end
        return false
    elseif betType == "dozen" then
        if spunNumber == 0 then return false end
        if betChoice == "1" then return spunNumber >= 1 and spunNumber <= 12 end
        if betChoice == "2" then return spunNumber >= 13 and spunNumber <= 24 end
        if betChoice == "3" then return spunNumber >= 25 and spunNumber <= 36 end
        return false
    elseif betType == "highlow" then
        if spunNumber == 0 then return false end
        if betChoice == "high" then return spunNumber >= 19 and spunNumber <= 36 end
        if betChoice == "low" then return spunNumber >= 1 and spunNumber <= 18 end
        return false
    end
    return false
end

local function main()
    print("Welcome to Console Roulette!")
    local balance = 1000 -- starting money
    print("You start with $" .. balance)
    printBetHelp()

    while balance > 0 do
        local quitRequested = false
        repeat
            print("\nCurrent balance: $" .. balance)
            local betType = input("Enter bet type (number/color/odd/even/dozen/highlow) or 'quit': "):lower()
            if betType == "quit" or betType == "q" then
                print("Leaving the table. You cash out $" .. balance)
                quitRequested = true
                break
            end

            if betType == "evenodd" then betType = "evenodd" end

            local validTypes = {number=true, color=true, odd=true, even=true, evenodd=true, dozen=true, highlow=true}

            if not validTypes[betType] then
                print("Unknown bet type.")
                printBetHelp()
                break
            end

            local choice
            if betType == "number" then
                choice = input("Pick a number 0-36: ")
                local n = tonumber(choice)
                if not n or n < 0 or n > 36 then
                    print("Invalid number.")
                    break
                end
            elseif betType == "color" then
                choice = input("Pick color ('red' or 'black'): "):lower()
                if choice ~= "red" and choice ~= "black" then
                    print("Invalid color.")
                    break
                end
            elseif betType == "odd" or betType == "even" or betType == "evenodd" then
                if betType == "odd" or betType == "even" then
                    choice = betType
                else
                    choice = input("Pick 'odd' or 'even': "):lower()
                    if choice ~= "odd" and choice ~= "even" then
                        print("Invalid choice.")
                        break
                    end
                    betType = "evenodd"
                end
            elseif betType == "dozen" then
                choice = input("Pick '1' (1-12), '2' (13-24) or '3' (25-36): ")
                if choice ~= "1" and choice ~= "2" and choice ~= "3" then
                    print("Invalid dozen.")
                    break
                end
            elseif betType == "highlow" then
                choice = input("Pick 'high' (19-36) or 'low' (1-18): "):lower()
                if choice ~= "high" and choice ~= "low" then
                    print("Invalid choice.")
                    break
                end
            end

            local amtStr = input("Bet amount: $")
            local amt = tonumber(amtStr)
            if not amt or amt <= 0 or amt > balance then
                print("Invalid bet amount.")
                break
            end

            balance = balance - amt

            local spunNumber, spunColor = spinWheel()
            print(string.format("Wheel spins... landed on %d (%s)", spunNumber, spunColor))

            local won = evaluateBet(betType, choice, spunNumber, spunColor)
            local multiplier
            if betType == "number" then multiplier = multipliers.number
            elseif betType == "color" then multiplier = multipliers.color
            elseif betType == "evenodd" then multiplier = multipliers.evenodd
            elseif betType == "odd" or betType == "even" then multiplier = multipliers.evenodd
            elseif betType == "dozen" then multiplier = multipliers.dozen
            elseif betType == "highlow" then multiplier = multipliers.highlow
            else multiplier = 0 end

            if won then
                local payout = amt * (multiplier + 1)
                balance = balance + payout
                print("You WIN! Payout: $" .. payout .. " (including your stake).")
            else
                print("You lose. Lost stake: $" .. amt)
            end

            if balance <= 0 then
                print("You're out of money. Game over.")
                break
            end
        until true

        if quitRequested then break end
    end

    print("Thanks for playing!")
end

main()

local roulette = {}

function roulette.play()
    -- just call your existing main loop
    main()
end