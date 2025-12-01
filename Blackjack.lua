math.randomseed(os.time())


local function build_deck()
    local ranks = {"A","2","3","4","5","6","7","8","9","10","J","Q","K"}
    local suits = {"♠","♥","♦","♣"}
    local deck = {}
    for _,s in ipairs(suits) do
        for _,r in ipairs(ranks) do
            table.insert(deck, {rank = r, suit = s})
        end
    end
    return deck
end


local function shuffle(deck)
    for i = #deck, 2, -1 do
        local j = math.random(1, i)
        deck[i], deck[j] = deck[j], deck[i]
    end
end

local function card_to_string(card)
    return card.rank .. card.suit
end


local function hand_value(hand)
    local total = 0
    local aces = 0
    for _,c in ipairs(hand) do
        local r = c.rank
        if r == "A" then
            aces = aces + 1
            total = total + 1 -- count as 1 for now
        elseif r == "J" or r == "Q" or r == "K" then
            total = total + 10
        else
            total = total + tonumber(r)
        end
    end

    for i = 1, aces do
        if total + 10 <= 21 then
            total = total + 10
        end
    end
    return total
end

local function is_blackjack(hand)
    return #hand == 2 and hand_value(hand) == 21
end

local function print_hand(prefix, hand, hide_first)
    local pieces = {}
    for i,card in ipairs(hand) do
        if hide_first and i == 1 then
            table.insert(pieces, "[hidden]")
        else
            table.insert(pieces, card_to_string(card))
        end
    end
    io.write(prefix .. table.concat(pieces, " ") .. "\n")
end


local function draw(deck)
    if #deck < 15 then

        deck = build_deck()
        shuffle(deck)
    end
    return table.remove(deck), deck
end


local function player_choice()
    while true do
        io.write("(H)it or (S)tand? ")
        local ans = io.read()
        if not ans then return "s" end
        ans = ans:lower():sub(1,1)
        if ans == "h" or ans == "s" then return ans end
        print("Please enter H or S.")
    end
end


local function play_round(bank)
    local deck = build_deck()
    shuffle(deck)
    local player = {}
    local dealer = {}


    for i=1,2 do
        local c
        c, deck = draw(deck)
        table.insert(player, c)
        c, deck = draw(deck)
        table.insert(dealer, c)
    end

    print("\n--- New Round ---")
    print_hand("Dealer: ", dealer, true)
    print_hand("You:    ", player)
    print("Your total:", hand_value(player))


    local playerBJ = is_blackjack(player)
    local dealerBJ = is_blackjack(dealer)

    if playerBJ or dealerBJ then
        print_hand("Dealer: ", dealer, false)
        if playerBJ and dealerBJ then
            print("Both have Blackjack! Push.")
            return bank, 0 
        elseif playerBJ then
            print("Blackjack! You win 1.5x your bet.")
            local profit = math.floor(1.5 * bank.bet + 0.5)
            return bank, bank.bet + profit 
        else
            print("Dealer has Blackjack. You lose.")
            return bank, -bank.bet
        end
    end

    -- player turn
    while true do
        local hv = hand_value(player)
        if hv > 21 then
            print_hand("You:    ", player)
            print("Bust! You have", hv)
            return bank, -bank.bet
        end
        local choice = player_choice()
        if choice == "h" then
            local c
            c, deck = draw(deck)
            table.insert(player, c)
            print("You draw:", card_to_string(c))
            print_hand("You:    ", player)
            print("Your total:", hand_value(player))
        else
            break
        end
    end

    -- dealer turn: reveal and hit until 17 or more (soft 17 stands)
    print_hand("Dealer: ", dealer, false)
    while hand_value(dealer) < 17 do
        local c
        c, deck = draw(deck)
        table.insert(dealer, c)
        print("Dealer draws:", card_to_string(c))
    end

    local pval = hand_value(player)
    local dval = hand_value(dealer)
    print("Final totals -> You:", pval, "Dealer:", dval)

    if dval > 21 then
        print("Dealer busts! You win.")
        return bank, bank.bet
    elseif pval > dval then
        print("You win!")
        return bank, bank.bet
    elseif pval < dval then
        print("You lose.")
        return bank, -bank.bet
    else
        print("Push (tie).")
        return bank, 0
    end
end

-- manage betting and main loop
local function main()
    print("Welcome to Lua Blackjack!")
    local balance = 100
    while true do
        print("\nBalance: $" .. balance)
        io.write("Enter bet amount (or Q to quit): ")
        local s = io.read()
        if not s then return end
        if s:lower():match("^q") then
            print("Thanks for playing! Final balance: $" .. balance)
            return
        end
        local bet = tonumber(s)
        if not bet or bet <= 0 then
            print("Invalid bet.")
        elseif bet > balance then
            print("You don't have enough money.")
        else
            local bank = { bet = bet }
            local _, delta = play_round(bank)
            if delta > 0 then
                if delta == bank.bet + math.floor(1.5*bank.bet + 0.5) then
                    balance = balance + math.floor(1.5*bank.bet + 0.5)
                else
                    balance = balance + delta
                end
            else
                balance = balance + delta
            end
            if balance <= 0 then
                print("You're out of money! Game over.")
                return
            end
        end
    end
end

local blackjack = {}



function blackjack.play()

    main()
end

return blackjack
