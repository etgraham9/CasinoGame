-- roulette.lua
math.randomseed(os.time())

local redSet = { [1]=true,[3]=true,[5]=true,[7]=true,[9]=true,[12]=true,[14]=true,[16]=true,
    [18]=true,[19]=true,[21]=true,[23]=true,[25]=true,[27]=true,[30]=true,
    [32]=true,[34]=true,[36]=true }

local function pocketColor(n)
    if n == 0 then return "green" end
    return redSet[n] and "red" or "black"
end

local function input(prompt)
    io.write(prompt)
    return io.read() or ""
end

local function spinWheel()
    local n = math.random(0,36)
    return n, pocketColor(n)
end

local multipliers = {
    number = 35, color = 1,
    evenodd = 1, dozen = 2,
    highlow = 1
}

local function evaluateBet(t, choice, n, col)
    if t == "number" then return tonumber(choice) == n end
    if t == "color" then return choice == col end
    if t == "odd" then return n ~= 0 and n % 2 == 1 end
    if t == "even" then return n ~= 0 and n % 2 == 0 end
    if t == "dozen" then
        if n == 0 then return false end
        if choice == "1" then return n <= 12 end
        if choice == "2" then return n >= 13 and n <= 24 end
        return n >= 25
    end
    if t == "highlow" then
        if n == 0 then return false end
        if choice == "low" then return n <= 18 end
        return n >= 19
    end
end

local roulette = {}

function roulette.play(balance)
    print("\n=== ROULETTE ===")
    print("Balance: $" .. balance)

    io.write("Bet type (number/color/odd/even/dozen/highlow): ")
    local betType = (io.read() or ""):lower()

    io.write("Choice: ")
    local choice = io.read()

    io.write("Bet amount: ")
    local amt = tonumber(io.read())

    if not amt or amt <= 0 or amt > balance then
        print("Invalid bet.")
        return balance
    end

    balance = balance - amt

    local num, col = spinWheel()
    print("Wheel landed on " .. num .. " (" .. col .. ")")

    local won = evaluateBet(betType, choice, num, col)
    if won then
        local payout = amt * (1 + (multipliers[betType] or 0))
        balance = balance + payout
        print("You WIN! Payout: $" .. payout)
    else
        print("You lose.")
    end

    print("New balance: $" .. balance)
    return balance
end

return roulette
