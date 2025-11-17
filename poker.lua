-- Two-Player Poker (Five-Card Draw)
-- Now includes detailed tiebreaker logic
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

local function shuffle(deck)
    for i = #deck, 2, -1 do
        local j = math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
end

local function deal(deck, n)
    local hand = {}
    for i=1,n do
        table.insert(hand, table.remove(deck,1))
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

-- Helper: sort by rank
local function sort_hand(hand)
    table.sort(hand, function(a,b)
        return rank_value(a.rank) < rank_value(b.rank)
    end)
end

-- Evaluate hand: returns rank, name, tiebreaker list
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
    if values[1]==2 and values[2]==3 and values[3]==4 and values[4]==5 and values[5]==14 then
        straight = true
        values[5] = 5 -- Treat Ace as low
        table.sort(values)
    end

    -- Count distribution
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

    -- Create tiebreaker order list (sorted by group count then value)
    local tiebreakers = {}
    for _,g in ipairs(grouped) do
        for _=1,g.count do
            table.insert(tiebreakers, g.val)
        end
    end

    return rankValue, rankName, tiebreakers
end

-- Compare function (now considers tiebreakers)
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
            if (tb1[i] or 0) > (tb2[i] or 0) then
                return "You win! (Higher "..n1..")"
            elseif (tb1[i] or 0) < (tb2[i] or 0) then
                return "Computer wins! (Higher "..n2..")"
            end
        end
        return "It's a tie! ("..n1.." vs "..n2..")"
    end
end

-- Game start
local deck = build_deck()
shuffle(deck)

local player = deal(deck, 5)
local cpu = deal(deck, 5)

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
        player[n] = table.remove(deck,1)
    end
end

-- Computer discards 0–2 random cards
local cpuReplace = math.random(0,2)
for i=1,cpuReplace do
    local idx = math.random(1,#cpu)
    cpu[idx] = table.remove(deck,1)
end

print("\nFinal Hands:")
print("Your hand:")
show_hand(player)
print("Computer hand:")
show_hand(cpu)

print("\nResult: "..compare(player, cpu))
