local Trigger = {};
Trigger.__index = Trigger;


local Signal = require(script.Signal);
local sp = game:GetService("StarterPlayer");
local cs = game:GetService("CollectionService");
local rep = game:GetService("ReplicatedStorage");
local rs = game:GetService("RunService");



function genId(length)
	if (not length) then length = 10; end
	local id = {};
	
	for i=1, length do
		id[i] = math.random(0, 9);
	end
	
	return table.concat(id);
end


function split(inputstr, sep)
	if sep == nil then sep = "%s" end
	local t={}
	
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	
	return t
end


local function GetFullName(x)
	local t = {}
	while x ~= game do
		local name = x.Name:gsub('[\"]', '\\%0')
		table.insert(t, 1, name)
		x = x.Parent
	end
	return t
end



function Trigger.new(triggerPart, triggerSettings)
	local id = genId();
	local partId = genId();
	
	triggerPart.Name = triggerPart.Name.."?trigid="..partId;
	triggerPart.CanTouch = true;
	
	local Enabled = Instance.new("BoolValue", triggerPart);
	Enabled.Name = "TriggerEnabled";
	Enabled.Value = true;
	
	
	-- data stuff
	local self = setmetatable({

		-- basic stuff
		Id = id,
		PartId = partId,
		PartName = triggerPart.name,
		Part = triggerPart,
		Settings = triggerSettings,
		Enabled = Enabled,
		Running = false,

		-- events
		Entered = Signal.new(),
		Exited = Signal.new(),
		

	}, Trigger);
	
	triggerPart.Transparency = 1;
	
	
	if (triggerSettings) then
		if (triggerSettings.PartTransparency) then
			triggerPart.Transparency = triggerSettings.PartTransparency
		end
	end
	
	
	local scs = sp.StarterCharacterScripts;
	local TriggerScriptsFolders = nil;
	local TriggerPartsFolders = nil;
	local TriggerEventsFolders = nil;
	local TriggerPlayerHandler = nil;
	
	
	if (not scs:FindFirstChild("TriggerScripts")) then
		TriggerScriptsFolders = Instance.new("Folder", scs);
		TriggerScriptsFolders.Name = "TriggerScripts";
	else
		TriggerScriptsFolders = scs.TriggerScripts;
	end
	
	if (not rep:FindFirstChild("TriggerEvents")) then
		TriggerEventsFolders = Instance.new("Folder", rep);
		TriggerEventsFolders.Name = "TriggerEvents";
	else
		TriggerEventsFolders = rep.TriggerEvents;
	end
	
	if (not workspace:FindFirstChild("TriggerPlayerHandler")) then
		TriggerPlayerHandler = script.TriggerPlayerHandler:Clone();
		TriggerPlayerHandler.Parent = workspace;
	else
		TriggerPlayerHandler = workspace.TriggerPlayerHandler;
	end
		
		
	local TriggerScriptFolder = Instance.new("Folder", TriggerScriptsFolders);
	local TriggerEventFolder = Instance.new("Folder", TriggerEventsFolders);
	
	TriggerScriptFolder.Name = id;
	TriggerEventFolder.Name = id;
	
	local TriggerHandler = script.TriggerHandler:Clone();
	TriggerHandler.Parent = TriggerScriptFolder;
	
	
	local inEvent = Instance.new("RemoteEvent", TriggerEventFolder);
	inEvent.Name = "InEvent";	
	
	local outEvent = Instance.new("RemoteEvent", TriggerEventFolder);
	outEvent.Name = "OutEvent";
	
	local playerHandler = Instance.new("RemoteEvent", TriggerEventsFolders);
	playerHandler.Name = "PlayerHandler";


	self._inEvent = inEvent;
	self._outEvent = outEvent;
	self._playerHandler = playerHandler;

	
	return self;
end



function Trigger:Activate()
	if (not self.Running) then
		task.wait(1);
		self.Running = true;
		
		
		local function ActivateServer()

			self._outEvent.OnServerEvent:Connect(function(player, outType)
				if (outType == 1) then
					self.Entered:Fire(workspace[player.Name], player);
				else
					self.Exited:Fire(workspace[player.Name], player);
				end
			end)


			local dir = GetFullName(self.Part);


			self._playerHandler.OnServerEvent:Connect(function()
				self._inEvent:FireAllClients(dir, self.Id, self.Settings);
			end)

			self._inEvent:FireAllClients(dir, self.Id, self.Settings);
		end
		
		
		local function ActivateClient()
			repeat task.wait() until game:IsLoaded();
			local players = game.Players;
			local touchBoolean = false;
			
			local player = players.LocalPlayer;
			local character = player.Character;
			
			local TouchPart = nil;
			local id = self.Id;
			local triggerSettings = self.Settings;


			if (not character:FindFirstChild("TriggerHitbox?trigid="..id)) then
				TouchPart = Instance.new("Part", character);
				TouchPart.Name = "TriggerHitbox?trigid="..id;
				TouchPart.Anchored = true;
				TouchPart.CanCollide = false;
				TouchPart.Size = Vector3.new(1, 1, 1);
				TouchPart.Transparency = 1;


				local offset = Instance.new("Vector3Value", TouchPart);
				offset.Name = "Offset";


				local TouchConnection = TouchPart.Touched:Connect(function() end);


				if (triggerSettings) then
					if (triggerSettings.Hitbox) then
						for name, setting in ipairs(triggerSettings.Hitbox) do
							TouchPart[name] = setting;
						end
					end

					if (triggerSettings.Offset) then
						offset.Value = triggerSettings.Offset;
					end

					if (triggerSettings.Size) then
						TouchPart.Size = triggerSettings.Size;
					end
				end
			else
				TouchPart = character["TriggerHitbox?trigid="..id]
			end


			rs.RenderStepped:Connect(function()
				local triggerPart = self.Part;


				local function GetParts()
					local HumanoidRootPart = character:FindFirstChild("HumanoidRootPart");

					if HumanoidRootPart then
						TouchPart.CFrame = HumanoidRootPart.CFrame + TouchPart.Offset.Value;
						return TouchPart:GetTouchingParts();
					end
					
					return {};
				end



				local function IsTouching(part)
					for _, touchedPart in ipairs(GetParts()) do
						if (touchedPart.name == part.name) then return true end
					end

					return false;
				end


				if (IsTouching(triggerPart) and not touchBoolean and triggerPart.TriggerEnabled.Value) then

					touchBoolean = true;
					self.Entered:Fire(character, player);

				elseif (not IsTouching(triggerPart)) then

					if (touchBoolean) then self.Exited:Fire(character, player); end
					touchBoolean = false;
				end
			end);

			
			local dir = GetFullName(self.Part);
			
			player.CharacterAdded:Connect(function()
				ActivateClient();
			end)
		end
		
		
		if (not pcall(ActivateServer)) then
			ActivateClient()
		end
	else
		self.Enabled.Value = true;
	end
end


function Trigger:Deactivate()
	self.Enabled.Value = false;
end


function Trigger:Visualize(transparency)
	if (not transparency) then transparency = 0.5 end
	
	local sides = { "Front", "Back", "Right", "Left", "Top", "Bottom" };
	self.Textures = {};

	for _, side in ipairs(sides) do
		local texture = Instance.new("Texture", self.Part);
		
		if (self.Settings) then
			if (self.Settings.TextureTransparency) then
				transparency = self.Settings.TextureTransparency;
			end
			
			if (self.Settings.Texture) then
				texture = self.Settings.Texture
			end
		end
		
		texture.Texture = "http://www.roblox.com/asset/?id=16742889088";
		texture.Transparency = transparency;
		texture.Face = Enum.NormalId[side];
		self.Textures[side] = texture;
	end
end


function Trigger:VisualizeAll(transparency)
	if (not transparency) then transparency = 0.5 end
	
	for _, child in workspace:GetChildren() do
		if (string.find(child.Name, "?trigid=") ~= nil) then
			
			local sides = { "Front", "Back", "Right", "Left", "Top", "Bottom" };

			for _, side in ipairs(sides) do
				local texture = Instance.new("Texture", self.Part);

				if (self.Settings) then
					if (self.Settings.TextureTransparency) then
						texture.Transparency = self.Settings.TextureTransparency;
					end

					if (self.Settings.Texture) then
						texture = self.Settings.Texture
					end
				end

				texture.Texture = "http://www.roblox.com/asset/?id=16742889088";
				texture.Transparency = transparency;
				texture.Face = Enum.NormalId[side];
			end
		end
	end
end



return Trigger;
