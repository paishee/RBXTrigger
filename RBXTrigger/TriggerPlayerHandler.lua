-- script running on the client context for handling player refreshing and setup upon joining or dying


pcall(function()
	local event = game.ReplicatedStorage.TriggerEvents.PlayerHandler;
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
end)
