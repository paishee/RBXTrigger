repeat task.wait() until game:IsLoaded();

local events = game.ReplicatedStorage:WaitForChild("TriggerEvents");

local event = events.PlayerHandler;
local players = game.Players;


players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		event:FireServer();
	end)
end)

for _, player in ipairs(players:GetChildren()) do
	player.CharacterAdded:Connect(function()
		event:FireServer();
	end)
end
