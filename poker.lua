-- poker.lua
math.randomseed(os.time())

local suits = {"♠", "♥", "♦", "♣"}
local ranks = {"2","3","4","5","6","7","8","9","10","J","Q","K","A"}

-- Build deck
local function build_deck()
    local deck = {}
    for _,s in ipairs(suits) do
        for _,r in ipairs(ranks) do
            table.insert(deck, {rank=r, suit=s})
        end
    end
    return deck
end

-- Fisher-Yates shuffle
local function shuffle(deck)
    for i = #deck, 2, -1 do
        local j = math.random(1, i)
        deck[i], deck[j] = deck[j], deck[i]
    end
end

local function deal(deck, n)
    local hand = {}
    for i=1,n do
        table.insert(hand, table.remove(deck, 1))
    end
    return hand
end

local function show_hand(hand)
    for i,c in ipairs(hand) do
        io.write(string.format("[%d] %s%s  ", i, c.rank, c.suit))
    end
    io.write("\n")
end

local function rank_value(rank)
    local values = {["2"]=2,["3"]=3,["4"]=4,["5"]=5,["6"]=6,["7"]=7,["8"]=8,["9"]=9,
                    ["10"]=10,["J"]=11,["Q"]=12,["K"]=13,["A"]=14}
    return values[rank]
end

-- Helper: sort by rank ascending
local function sort_hand(hand)
    table.sort(hand, function(a,b)
        return rank_value(a.rank) < rank_value(b.rank)
    end)
end

-- Evaluate hand: returns rankValue (higher better), rankName, and tiebreaker list
local function evaluate(hand)
    sort_hand(hand)
    local values, suits = {}, {}
    for _,c in ipairs(hand) do
        table.insert(values, rank_value(c.rank))
        table.insert(suits, c.suit)
    end

    -- Count duplicates
    local counts = {}
    for _,v in ipairs(values) do counts[v] = (counts[v] or 0) + 1 end

    -- Detect flush
    local flush = true
    for i=2,#suits do
        if suits[i] ~= suits[1] then
            flush = false
            break
        end
    end

    -- Detect straight
    local straight = true
    for i=2,#values do
        if values[i] ~= values[i-1] + 1 then
            straight = false
            break
        end
    end
    -- Handle Ace-low straight (A,2,3,4,5)
    if not straight then
        -- check A,2,3,4,5 specifically
        local vs = {table.unpack(values)}
        table.sort(vs)
        if vs[1]==2 and vs[2]==3 and vs[3]==4 and vs[4]==5 and vs[5]==14 then
            straight = true
            -- treat Ace as value 1 for tiebreaker ordering
            values = {1,2,3,4,5}
            table.sort(values)
        end
    end

    -- Count distribution into grouped table {val, count}
    local grouped = {}
    for val,count in pairs(counts) do
        table.insert(grouped, {val=val, count=count})
    end
    table.sort(grouped, function(a,b)
        if a.count == b.count then
            return a.val > b.val
        else
            return a.count > b.count
        end
    end)

    local rankName
    local rankValue

    if straight and flush then
        rankValue, rankName = 9, "Straight Flush"
    elseif grouped[1].count == 4 then
        rankValue, rankName = 8, "Four of a Kind"
    elseif grouped[1].count == 3 and grouped[2] and grouped[2].count == 2 then
        rankValue, rankName = 7, "Full House"
    elseif flush then
        rankValue, rankName = 6, "Flush"
    elseif straight then
        rankValue, rankName = 5, "Straight"
    elseif grouped[1].count == 3 then
        rankValue, rankName = 4, "Three of a Kind"
    elseif grouped[1].count == 2 and grouped[2] and grouped[2].count == 2 then
        rankValue, rankName = 3, "Two Pair"
    elseif grouped[1].count == 2 then
        rankValue, rankName = 2, "One Pair"
    else
        rankValue, rankName = 1, "High Card"
    end

    -- Build tiebreakers: sort groups by count desc then val desc, expand values accordingly
    local tiebreakers = {}
    table.sort(grouped, function(a,b)
        if a.count == b.count then
            return a.val > b.val
        else
            return a.count > b.count
        end
    end)
    for _,g in ipairs(grouped) do
        for i=1,g.count do
            table.insert(tiebreakers, g.val)
        end
    end

    -- For situations where grouped doesn't include all singletons in order, append remaining high cards
    if #tiebreakers < 5 then
        -- collect remaining values not in tiebreakers
        local present = {}
        for _,v in ipairs(tiebreakers) do present[v] = (present[v] or 0) + 1 end
        -- add remaining values highest-first
        local remaining = {}
        for _,v in ipairs(values) do
            remaining[v] = (remaining[v] or 0) + 1
        end
        for val,count in pairs(present) do
            remaining[val] = (remaining[val] or 0) - count
            if remaining[val] <= 0 then remaining[val] = nil end
        end
        local remlist = {}
        for val,_ in pairs(remaining) do table.insert(remlist, val) end
        table.sort(remlist, function(a,b) return a > b end)
        for _,v in ipairs(remlist) do
            for i=1,(remaining[v] or 0) do
                table.insert(tiebreakers, v)
            end
        end
    end

    return rankValue, rankName, tiebreakers
end

-- Compare two hands: returns a human-readable result string
local function compare(p1, p2)
    local v1, n1, tb1 = evaluate(p1)
    local v2, n2, tb2 = evaluate(p2)

    if v1 > v2 then
        return "You win! ("..n1.." beats "..n2..")"
    elseif v1 < v2 then
        return "Computer wins! ("..n2.." beats "..n1..")"
    else
        -- Same type, check tiebreakers
        for i=1, math.max(#tb1, #tb2) do
            local a = tb1[i] or 0
            local b = tb2[i] or 0
            if a > b then
                return "You win! (Higher "..n1..")"
            elseif a < b then
                return "Computer wins! (Higher "..n2..")"
            end
        end
        return "It's a tie! ("..n1.." vs "..n2..")"
    end
end

local poker = {}

function poker.play(balance)
    print("\n=== FIVE-CARD POKER ===")
    print("Balance: $" .. balance)

    io.write("Bet: ")
    local bet = tonumber(io.read())

    if not bet or bet <= 0 or bet > balance then
        print("Invalid bet.")
        return balance
    end

    balance = balance - bet

    -- Deal
    local deck = build_deck()
    shuffle(deck)

    local player = deal(deck,5)
    local cpu    = deal(deck,5)

    print("\nYour hand:")
    show_hand(player)

    io.write("\nEnter card numbers to replace (comma separated, or ENTER to keep all): ")
    local input = io.read()
    if input and input ~= "" then
        local nums = {}
        for n in string.gmatch(input, "%d+") do
            table.insert(nums, tonumber(n))
        end
        table.sort(nums, function(a,b) return a>b end)
        for _,n in ipairs(nums) do
            if n >=1 and n <=5 then
                player[n] = table.remove(deck,1)
            end
        end
    end

    -- Computer discards 0–2 random cards
    local cpuReplace = math.random(0,2)
    for i=1,cpuReplace do
        local idx = math.random(1,5)
        cpu[idx] = table.remove(deck,1)
    end

    print("\nFinal Hands:")
    print("Your hand:")
    show_hand(player)
    print("Computer hand:")
    show_hand(cpu)

    local result = compare(player, cpu)
    print("\nResult: " .. result)

    if result:find("You win") then
        balance = balance + bet * 2  -- win returns original stake + equal stake
        print("You won $" .. bet)
    elseif result:lower():find("tie") or result:find("It's a tie") then
        balance = balance + bet  -- push: return stake
        print("Push. Bet returned.")
    else
        print("You lost $" .. bet)
    end

    print("New balance: $" .. balance)
    return balance
end

return poker
