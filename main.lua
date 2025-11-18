-- main.lua
local blackjack = require("blackjack")
local roulette  = require("roulette")
local poker     = require("poker")

local balance = 1000  -- CENTRAL MONEY STORAGE

local function main()
    while true do
        print("\n===== LUA CASINO =====")
        print("Balance: $" .. balance)
        print("Choose a game:")
        print("1. Roulette")
        print("2. Poker")
        print("3. Blackjack")
        print("Q. Quit")

        io.write("> ")
        local choice = io.read()
        if not choice then return end
        choice = choice:lower()

        if choice == "1" then
            balance = roulette.play(balance)   -- return updated balance
        elseif choice == "2" then
            balance = poker.play(balance)
        elseif choice == "3" then
            balance = blackjack.play(balance)
        elseif choice == "q" then
            print("Thanks for visiting the Casino! Final balance: $" .. balance)
            return
        else
            print("Invalid choice.")
        end

        if balance <= 0 then
            print("You are out of money! Casino ejects you.")
            return
        end
    end
end

main()
