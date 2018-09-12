-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- Hide Status Bar
display.setStatusBar(display.HiddenStatusBar);

-- Physics Engine
local physics = require "physics";
physics.start();
physics.setGravity(0, 0);

-- Load Sounds
local BlockBreak = audio.loadSound("sounds/ow.mp3");

-- "Constants"
local _W = display.contentWidth / 2;
local _H = display.contentHeight / 2;

-- Variables
local blocks = display.newGroup();
local blockWidth = 50;
local blockHeight = 50;
local row;
local column;
local score = 0;
local currentLevel;
local velocityX = 3;
local velocityY = -3;
local gameEvent = "";

-- Menu Screen
local titleScreenGroup;
local titleScreen;
local playBtn;

-- Game Screen
local background;
local player;
local block;
local bullet;

-- Score/Level Text
local BlockBreakText;
local BlockBreakNum;
local levelText;
local levelNum;

-- textBoxGroup
local textBoxGroup;
local textBox;
local conditionDisplay;
local messageText;

-- Show the Title Screen
function showTitleScreen()	
	
	-- Place all title screen elements into 1 group
	titleScreenGroup = display.newGroup();

	-- Display background image
	titleScreen = display.newRect(_W, _H, 500, 300);
	
	-- Display play button image
	--playBtn = display.newText("Play", _W, _H + 50, "Arial", 24);

	playBtn = display.newText( "PLAY", _W, _H + 50, native.systemFont, 32 )
	playBtn:setFillColor( 1, 0, 0 )

	playBtn.name = "playbutton";

	-- Insert background and button into group
	titleScreenGroup:insert(titleScreen);
	titleScreenGroup:insert(playBtn);

	-- Make play button interactive
	playBtn:addEventListener("tap", loadGame);
end

function cleanupLevel()
	-- Clear old blocks 
	blocks:removeSelf();
	blocks.numChildren = 0;
	blocks = display.newGroup();

	-- Remove text Box
	textBox:removeEventListener("tap", restart);
	textBoxGroup:removeSelf();
	textBoxGroup = nil;
	
	-- Reset bullet and player position 
	bullet.x = _W;
	bullet.y = player.y - 30;
	player.x = _W;

	score = 0;
	BlockBreakNum.text = "0";
end

-- See if the player won or lost the level
function restart()
	-- If the player wins level 1, then go to level 2
	if gameEvent == "win" and currentLevel == 1 then
		currentLevel = currentLevel + 1;
		cleanupLevel();
		changeLevel2();
		levelNum.text = tostring("2");
	
	-- If the player wins level 2, tell them they won the game
	elseif gameEvent == "win" and currentLevel == 2 then	
		textBoxScreen("  You Survived!", "  Congratulations!");
		gameEvent = "completed";
	
	-- If the player loses level 1, then make them retry level 1 and reset score to 0
	elseif gameEvent == "lose" and currentLevel == 1 then
		cleanupLevel();
		changeLevel1();
	
	-- If the player loses level 2, then make them retry level 2 and reset score to 0
	elseif gameEvent == "lose" and currentLevel == 2 then
		cleanupLevel();
		changeLevel2();
		
	-- If the game has been completed, remove the listener of the text box to free up memory
	elseif gameEvent == "completed" then
		textBox:removeEventListener("tap", restart);
	end
end

function textBoxScreen(title, message)
	gameListeners("remove");
	
	-- Display text box with win or lose message
	textBox = display.newRoundedRect(240, 160, 200, 110, 20)
	textBox.strokeWidth = 3
	textBox:setFillColor( 0.5 )
	textBox:setStrokeColor( 1, 1, 1 )
	
	-- Win or Lose Text
	conditionDisplay = display.newText(title, 0, 0, "Arial", 38);
	conditionDisplay:setTextColor(255,255,255,255);
	conditionDisplay.xScale = 0.5;
	conditionDisplay.yScale = 0.5;
	--conditionDisplay:setReferencePoint(display.CenterReferencePoint);
	conditionDisplay.x = display.contentCenterX;
	conditionDisplay.y = display.contentCenterY - 15;
	
	--Try Again or Congrats Text
	messageText = display.newText(message, 0, 0, "Arial", 24);
	messageText:setTextColor(255,255,255,255);
	messageText.xScale = 0.5;
	messageText.yScale = 0.5;
	--messageText:setReferencePoint(display.CenterReferencePoint);
	messageText.x = display.contentCenterX;
	messageText.y = display.contentCenterY + 15;

	-- Add all elements into a new group
	textBoxGroup = display.newGroup();
	textBoxGroup:insert(textBox);
	textBoxGroup:insert(conditionDisplay);
	textBoxGroup:insert(messageText);
	
	-- Make text box interactive
	textBox:addEventListener("tap", restart);
end

-- Determines bullet movement by where it hits the player
function bounce()
	velocityY = -3
	if((bullet.x + bullet.width * 0.5) < player.x) then
		velocityX = -velocityX;
	elseif((bullet.x + bullet.width * 0.5) >= player.x) then
		velocityX = velocityX;
	end
end

-- Blocks are exterminated, remove them from screen
function blockDestroyed(event)
	
	-- Where did the bullet hit the block?
	if event.other.name == "block" and bullet.x + bullet.width * 0.5 < event.other.x + event.other.width * 0.5 then
		velocityX = -velocityX;
	elseif event.other.name == "block" and bullet.x + bullet.width * 0.5 >= event.other.x + event.other.width * 0.5 then
		velocityX = velocityX;
	end
	
	-- Ricochet the bullet off the block and remove them from the screen
	if event.other.name == "block" then
		-- Bounce the bullet
		velocityY = velocityY * -1;
		-- play "ow" when hit by a bullet
		audio.play(BlockBreak);
		-- Remove block instance
		event.other:removeSelf();
		event.other = nil;
		-- One less block
		blocks.numChildren = blocks.numChildren - 1;
		
		-- Score
		score = score + 1;
		BlockBreakNum.text = score;
		--Anchor not using
		--BlockBreakNum.anchorX = 0.5
		--BlockBreakNum.anchorY = 0
		BlockBreakNum.x = 150;
	end
	
	-- Check if all blocks are destroyed
	if blocks.numChildren < 0 then
		textBoxScreen("Lvl Passed", "Next City");
		gameEvent = "win";
	end
end

-- Player movement on user's drag
function movePlayer(event)
	if event.phase == "began" then
		moveX = event.x - player.x;
	elseif event.phase == "moved" then
		player.x = event.x - moveX;
	end

	if((player.x - player.width * 0.5) < 0) then
		player.x = player.width * 0.5;
	elseif((player.x + player.width * 0.5) > display.contentWidth) then
		player.x = display.contentWidth - player.width * 0.5;
	end
end

-- Listen for bullet and player collisions and user dragging player
function gameListeners(event)
	if event == "add" then
		Runtime:addEventListener("enterFrame", updatebullet);
		-- Bookmark A: You'll be adding some code here later
		player:addEventListener("touch", movePlayer);
		player:addEventListener("collision", bounce);
		bullet:addEventListener("collision", blockDestroyed);
	-- Remove listeners when not needed to free up memory
	elseif event == "remove" then
		Runtime:removeEventListener("enterFrame", updatebullet);
		-- Bookmark B: You'll be adding some code here later too
		player:removeEventListener("touch", movePlayer);
		player:removeEventListener("collision", bounce);
		bullet:removeEventListener("collision", blockDestroyed);
	end
end

-- When the game starts, add physics properties to player and bullet
function startGame()
	physics.addBody(player, "static", {density = 1, friction = 0, bounce = 0});
	physics.addBody(bullet, "dynamic", {density = 1, friction = 0, bounce = 0});
	player:removeEventListener("tap", startGame);
	gameListeners("add");
end

-- Bullet properties
function updatebullet()

	-- Movement
	bullet.x = bullet.x + velocityX;
	bullet.y = bullet.y + velocityY;
	
	-- If bullet hits the ceiling or left or right wall, bounce off of it
	if bullet.x < 0 or bullet.x + bullet.width > display.contentWidth then  
		velocityX = -velocityX;
	end
	
	if bullet.y < 0  then 
		velocityY = -velocityY;
	end
	
	-- If the bullet hits the bottom wall, the player has lost the game
	if bullet.y + bullet.height > player.y + player.height then 
		textBoxScreen("LOSE", "Try Again") gameEvent = "lose";
	end
end

function gameLevel1()
	
	currentLevel = 1;

	-- Place the blocks on the top layer
	blocks:toFront();
	
	-- Number of blocks on level 1
	local numOfRows = 2;
	local numOfColumns = 2;
	
	-- Block position on screen
	local blockPlacement = {x = (_W) - (blockWidth * numOfColumns ) / 2  + 20, y = 70};
	
	-- Create blocks based on the number of columns and rows we declared
	for row = 0, numOfRows - 1 do
		for column = 0, numOfColumns - 1 do
			local block = display.newRoundedRect(blockPlacement.x + (column * blockWidth), blockPlacement.y + (row * blockHeight), 50, 50, 2)
			block:setFillColor(math.random(0, 1), math.random(0, 1), math.random(0, 1))
			block.strokeWidth = 3
			--textBox:setFillColor( 0.5 )
			block:setStrokeColor( 1, 1, 1 )
			block.name = "block";
			
			-- Add physics properties to blocks
			physics.addBody(block, "static", {density = 1, friction = 0, bounce = 0});
			blocks.insert(blocks, block);
		end
	end
end

-- Level 2 blocks
function gameLevel2()

	currentLevel = 2;
	
	-- This code is the same to gameLevel1(), but you can change the number of blocks on screen.
	blocks:toFront();
	local numOfRows = 2;
	local numOfColumns = 8;
	
	-- Block position on screen
	local blockPlacement = {x = (_W) - (blockWidth * numOfColumns ) / 2  + 20, y = 100};
	
	-- Create blocks based on the number of columns and rows we declared
	for row = 0, numOfRows - 1 do
		for column = 0, numOfColumns - 1 do
			local block = display.newRoundedRect(blockPlacement.x + (column * blockWidth), blockPlacement.y + (row * blockHeight), 50, 50, 2)
			block:setFillColor(math.random(0, 1), math.random(0, 1), math.random(0, 1))
			block.strokeWidth = 3
			--textBox:setFillColor( 0.5 )
			block:setStrokeColor( 1, 1, 1 )
			block.name = "block";
			
			-- Add physics properties to blocks
			physics.addBody(block, "static", {density = 1, friction = 0, bounce = 0});
			blocks.insert(blocks, block);
		end
	end
end

function changeLevel1()
	-- Start
	player:addEventListener("tap", startGame)

	-- Reset blocks
	gameLevel1();
end

-- New York City (Level 2)
function changeLevel2()
	-- Reset blocks 
	gameLevel2();
	
	-- Start
	player:addEventListener("tap", startGame)
end

-- Set up the game space
function initializeGameScreen()
	-- Place the player on screen
	player = display.newRect(_W, _H + 150, 88, 24);
	player.name = "player";
	
	-- Place bullet on screen
	bullet = display.newCircle(_W, player.y - 30, 8)
	bullet:setFillColor(25, 0, 0)
	bullet.name = "bullet";
	
	-- Score text
	BlockBreakText = display.newText("Blocks destroyed: ", 45, 22, "Arial", 14);
	BlockBreakText:setTextColor(255, 255, 255, 255);
	BlockBreakNum = display.newText("0", 150, 22, "Arial", 14);
	BlockBreakNum:setTextColor(255, 255, 255, 255);
	
	-- Level text
	levelText = display.newText("Lvl:", 360, 22, "Arial", 14);
	levelText:setTextColor(255, 255, 255, 255);
	levelNum = display.newText("1", 380, 22, "Arial", 14);
	levelNum:setTextColor(255, 255, 255, 255);
	
	-- Run level 1 
	changeLevel1();
end

-- When play button is tapped, start the game
function loadGame(event)
	if event.target.name == "playbutton" then
		audio.setVolume(0.2)
		transition.to(titleScreenGroup,{time = 0, alpha=0, onComplete = initializeGameScreen});
		playBtn:removeEventListener("tap", loadGame);
	end
end

-- Main Function
function main()
	showTitleScreen();
end

-- Run the game
main();