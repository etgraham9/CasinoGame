-- main.lua
local blackjack = require("blackjack")
local roulette = require("roulette")
local poker = require("poker")

local function main()
    print("Welcome to the Casino! What game would you like to play?")
    print("1. Roulette" .. "\n" .. "2. Poker" .. "\n" .. "3. BlackJack")

    local choice = io.read
    if (choice == 1) then
        roulette.play()
    elseif (choice == 2) then
        poker.play()
    elseif (choice == 3) then
        blackjack.play()        
    end
    
end

main()
