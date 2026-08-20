MOVE = {UP = true, DOWN = false}
GANTRYINSTRUCT = "back"
GANTRYORDRILL = "bottom"
MOVEMENTINVERT = "top"
DRILL = false
GANTRY = true
STRINGTOBOOLEAN={["true"] = true, ["false"] = false}
	
function main()
	--Put our main code in a main function that runs
	--at the end. Allows to put our main body of code
	--before our functions are declared. Which is what
	--I was always taught to do.
	
	modem = peripheral.find("modem")
	modem.open(9)
	redstone.setOutput(GANTRYORDRILL, GANTRY)
	--These lines are to make sure we have wireless
	--stuff enabled. Hard to have a smart quarry
	--without any sensor data
	
	local completion = require "cc.completion"
	
	f = io.open("savedDrillSize.txt", "r")
	if f ~= nil then
		print("Drill size file found, would you like to use the saved size?")
		write("> ")
		answer = read(nil, {"n", "y"}, nil, "y")
		while answer ~= "y" and answer ~= "n" do
			print("Input not recognized. Please put y for yes and n for no.")
			write("> ")
			answer = read(nil, {"n", "y"}, nil, "y")
		end
		if answer == "y" then
			length = f:read("*line")
			width = f:read("*line")
			f:close()
		else
			print("What is the East-West size of the drill?")
			write("> ")
			length = tonumber(read(nil,nil,nil,nil))
			print("What is the North-South size of the drill?")
			write("> ")
			width = tonumber(read(nil,nil,nil,nil))
			print("Would you like to save these values? y/n")
			write("> ")
			answer = read(nil,{"n", "y"},nil, "y")
			while answer ~= "y" and answer ~= "n" do
				print("Input not recognized. Please put y for yes and n for no.")
				write("> ")
				answer = read(nil, {"n", "y"}, nil, "y")
			end
			if answer == "y" then
				f = io.open("savedDrillSize.txt", "w")
				if f ~= nil then
					f:write(length, "\n")
					f:write(width, "\n")
					f:close()
				else
					print("Drill size could not be saved...")
				end
			end
		end
	else
		print("What is the East-West size of the drill?")
		write("> ")
		length = tonumber(read(nil,nil,nil,nil))
		print("\nWhat is the North-South size of the drill?")
		write("> ")
		width = tonumber(read(nil,nil,nil,nil))
		print("\nWould you like to save these values? y/n")
		write("> ")
		answer = read(nil,{"n", "y"},nil, "y")
		while answer ~= "y" and answer ~= "n" do
			print("Input not recognized. Please put y for yes and n for no.")
			write("> ")
			answer = read(nil, {"n", "y"}, nil, "y")
		end
		if answer == "y" then
			f = io.open("savedDrillSize.txt", "w")
			if f ~= nil then
				f:write(length, "\n")
				f:write(width, "\n")
				f:close()
			else
				print("Drill size could not be saved...")
			end
		end
	end

	--Hard coded drill size. Already have the
	--replacement code written. Still testing quarry,
	--though, so not asking size is faster right now.
	
	local dir = io.open("savedDirections.txt", "r")
	direrr = false
	if dir then
		print("\nDirections file found, would you like to use the saved directions? (y/n)\n(This is to restart a quarry that may have prematurely stopped)")
		local history = {"n", "y"}
		local choices = nil
		write("> ")
		local answer = read(nil, history, nil, "y")
		print("\n")
		while answer ~= "y" and answer ~= "n" do
			print("Input not recognized. Please enter a y for yes or an n for no.")
			write("> ")
			answer = read(nil, history, nil, "y")
		end
		if answer == "y" then
			direction1 = STRINGTOBOOLEAN[dir:read("*line")]
			direction2 = STRINGTOBOOLEAN[dir:read("*line")]
			dir:close()
			print("Moving drill up...")
			modem.transmit(8,9,"top true")
			modem.transmit(8,9,"back true")
			redstone.setOutput(GANTRYORDRILL, DRILL)
			redstone.setOutput(MOVEMENTINVERT, MOVE.UP)
			print("Please wait to start until the drill is at the top.")
		else
			direction1 = getDirection1()
			direction2 = getDirection2()
			local dir = io.open("savedDirections.txt", "w")
			if dir == nil then
				print("Unable to save new directions.")
			else
				dir:write(tostring(direction1), "\n")
				dir:write(tostring(direction2), "\n")
				dir:close()
			end
		end
	else
		local dir = io.open("savedDirections.txt", "w")
		direction1 = getDirection1()
		direction2 = getDirection2()
		if dir == nil then
			print("Unable to save directions")
		else
			dir:write(tostring(direction1), "\n")
			dir:write(tostring(direction2), "\n")
			dir:close()
		end		
	end
	print("\n")

	print("Make sure you have enough chest space! \nThis doesn't stop until it's done.\n\nIf you're ready, press enter (and make sure the sensor and gantry turtles are on!).")
	read(nil,nil,nil,nil)
	--Inform user of current short-comings of this
	--quarry software. Also waits to start mining
	--until you start the sensor computer.

	state = {0,0}
	print("\nStarted quarry\n")
	--Initializes a variable, and informs user of
	--the quarry having received the start signal.

	while(true)
	--This is where the magic happens. The actual
	--mining is controlled in this loop, which breaks
	--when the quarry reaches the farthest corner.
	do
		state[1] = 0
		mine()
		moveForward(length)
		if(state[1] == 1) then
		--state[1] tells us if we have hit the end of
		--the direction2 movement.
			allBack()
			moveSide(width)
			--If so, we go back to the beginning of
			--the line, move to the side, and mine.
		end 
		if(state[2] == 1) then
			--mine() mines. state[2] tells us if we are
			--finished/have reached the furthest corner.
			print("Going back from whence we came...")
			toOrigin()
			break
			--If we have, go back to the closest
			--corner and exit the main loop.
		end
end
print("\nFinished mining!")
--This runs after state[2] has been detected,
--breaking out of the loop. Informs the user we
--are done. And reminds them there's second
--computer to turn off. May attempt to make it
--turn off automatically after the program
--finishes.

end
--end of main() function

function mine()
--This function lowers the drill, then waits
--for the sensor on the drill to start sending
--a signal again, which will only happen when
--it is no longer an entity. Which means it hit
--bedrock and turned back into blocks. It then
--raises the drill until it hits the top and turns
--into blocks again.
	print("Drilling...")
	redstone.setOutput(GANTRYORDRILL, GANTRY)
	modem.transmit(8,9,"top true")
	modem.transmit(8,9,"back true")
	sleep(.01)
	redstone.setOutput(MOVEMENTINVERT, MOVE.DOWN)
	redstone.setOutput(GANTRYORDRILL, DRILL)
	--Changes to gantry mode, powers the
	--north-south gantry, powers the
	--east-west gantry, powers the gearshift,
	--changes to drill mode
	
	sleep(5)
	--Makes sure we have enough time for our drill
	--to start drilling before we check if it is
	--done drilling.
	
	getSensor()
	--Checks if the drill is solid. Shouldn't be
	--if it's drilling (so it'll return a 0)
	
	redstone.setOutput(MOVEMENTINVERT, MOVE.UP)
	print("Raising drill...")
	--Raising drill... stays in drill mode, just
	--stops powering the gearshift, changing the
	--direction of rotation.
	
	getSensor()
	redstone.setOutput(GANTRYORDRILL, GANTRY)
	sleep(0.2)
	--Changes into gantry mode
	
end
--end of mine() function

function moveForward(steps)
--MOVEs in the East-West direction towards unmined
--blocks.
	print("Moving forward...")
	modem.transmit(8,9,"back false")
	sleep(.01)
	redstone.setOutput(MOVEMENTINVERT, direction2)
	--Unpowers the second gantry, and either does
	--or doesn't power the gearshift depending on
	--the direction the quarry moves in.
	
	redstone.setOutput(GANTRYINSTRUCT, true)
	sleep(.1)
	redstone.setOutput(GANTRYINSTRUCT, false)
	local checkEdge = parallel.waitForAny(getSensor, function() sleep(0.7) end)
	if checkEdge == 2 then
		state[1] = 1
		return
	end
	
	for i = 1, steps-1, 1 do
		gantryStep()
		--Powers sequenced gearshift as much as we
		--need to to mine most efficiently. Mimics
		--a button press. Could probably be made
		--faster.
	end
	modem.transmit(8,9,"back true")
	sleep(.01)
	--Powers the second gantry.
end
--end of moveForward() function

function allBack()
--Called when hitting the end of your east-west
--quarry space. Goes back to the beginning of the
--line.
	print("Taking it back now yall!")
	modem.transmit(8,9,"back false")
	sleep(.01)
	--redstone.setOutput("right", false)
	redstone.setOutput(MOVEMENTINVERT, not direction2)
	redstone.setOutput(GANTRYORDRILL, DRILL)
	--unpowers second gantry (e-w), either powers
	--or doesn't power the gearshift to move back
	--to the start of the line, changes to drill
	--mode.
	
	sleep(0.1)
	--waits to allow enough time for the sequenced
	--gearshift to be exchanged with the shaft.
	
	getSensor()
	redstone.setOutput(GANTRYORDRILL, GANTRY)
	sleep(0.2)
	modem.transmit(8,9,"back true")
	--redstone.setOutput("right", true)
	--changes to gantry mode, powers e-w gantry
	
end
--end of allBack() function

function moveSide(steps)

  print("Slide to the side!")
	
	modem.transmit(8,9,"back false")
	modem.transmit(8,9,"top false")

	redstone.setOutput(MOVEMENTINVERT, direction1)
	--unpowers both first (n-s) and second (e-w)
	--gantrys, then either powers or doesn't power
	--the gearshift to allow for movement in the
	--correct direction.
	sleep(.5)
	
	redstone.setOutput(GANTRYINSTRUCT, true)
	sleep(.1)
	redstone.setOutput(GANTRYINSTRUCT, false)
	local checkEdge = parallel.waitForAny(getSensor, function() sleep(0.7) end)
	if checkEdge == 2 then
		state[2] = 1
		return
	end
	
	for i = 1, steps-1, 1 do
		gantryStep()
		--MOVEs either North or South as many steps
		--as is necessary to mine new blocks
		--without mining air or leaving unmined
		--blocks
	end
	
	modem.transmit(8,9,"top true")
	modem.transmit(8,9,"back true")
	--Powers both gantrys. Gantries? Gantrys?
end

function toOrigin()
	modem.transmit(8,9,"back false")
	modem.transmit(8,9,"top false")

	redstone.setOutput(MOVEMENTINVERT, not direction1)
	redstone.setOutput(GANTRYORDRILL, DRILL)
	--unpowers both gantrys, sets gearshift into
	--backwards mode, and turns into drill mode
	--(which simply allows for the drill to move
	--back to the origin without telling it to
	--move for every individual block.
	
	sleep(0.1)
	--Allows drill to change into drill mode
	
	getSensor()
	redstone.setOutput(GANTRYORDRILL, GANTRY)
	--Turns into gantry mode. Means the gantrys
	--won't continue spinning after finishing.
	--Which I think looks nicer. It's just looks.
	
	--fs.delete("savedDirections.txt")
	--fs.delete("savedDrillSize.txt")
end

function getSensor()
	e, s, c, rc, st = os.pullEvent("modem_message")
	return st
	--Receives the state variable from our sensor
	--computer. This array stores information on
	--whether or not our drill is currently solid,
	--whether or not we have hit the end of our
	--second gantry's length, and whether or not
	--we have hit the end of the mineable area.
	--I just ignore the s and p variables, which
	--should tell us the id of the computer who
	--sent the message, and the protocol used.
	--Which in this case is "quarry". The return
	--state part just shows which variable is
	--actually going to be used. Just readability. 
end

function gantryStep()
	redstone.setOutput(GANTRYINSTRUCT, true)
	sleep(.3)
	redstone.setOutput(GANTRYINSTRUCT, false)
	sleep(.3)
end

--Starting in a corner, find one of the directions
--away from the corner. This is done by trying
--to move and seeing if we a get a response from
--our sensor that it moved. If it didn't respond
--within a second, then it didn't move meaning
--we tried to move into the corner
function getDirection1()
	print("Getting direction1...")
	redstone.setOutput(MOVEMENTINVERT, true)
	redstone.setOutput(GANTRYORDRILL, GANTRY)
	redstone.setOutput(GANTRYINSTRUCT, true) --emulate a button press
	sleep(.1)
	redstone.setOutput(GANTRYINSTRUCT, false)  --turn off the button
	local dir = parallel.waitForAny(getSensor, function() sleep(1) end)
	if dir == 1 then
		redstone.setOutput(MOVEMENTINVERT, false)
		gantryStep()
		return true
	else
		return false
	end
end

--Same as the first getDirection function, but
--on a different axis.
function getDirection2()
	print("Getting direction2...")
	modem.transmit(8,9,"top true")
	redstone.setOutput(MOVEMENTINVERT, true)
	redstone.setOutput(GANTRYORDRILL, GANTRY)
	redstone.setOutput(GANTRYINSTRUCT, true)
	sleep(.1)
	redstone.setOutput(GANTRYINSTRUCT, false)
	local dir = parallel.waitForAny(getSensor, function() sleep(1) end)
	if dir == 1 then
		redstone.setOutput(MOVEMENTINVERT, false)
		gantryStep()
		return true
	else
		return false
	end
end

main()
--Actually runs the code. Prevents the issue of
--not having defined our functions by the time we
--call them.
