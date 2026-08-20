modem = peripheral.find("modem")
modem.open(8)
stringToBool = {["true"] = true, ["false"] = false}

function main()
  while true do
    e, s, c, rc, state = os.pullEvent("modem_message")
    side, toggle = split(state)
    redstone.setOutput(side, stringToBool[toggle])
    modem.transmit(9,8,"redstone")
  end
end

function split(str)
  first = ""
  second = ""
  done = false
  for i = 1, string.len(str) do
    if not done then
      if string.char(string.byte(str,i)) == " " then
        done = true
      else
        first = first .. string.char(string.byte(str,i))
      end
    else
      second = second .. string.char(string.byte(str,i))
    end
  end
  return first, second
end

main()
