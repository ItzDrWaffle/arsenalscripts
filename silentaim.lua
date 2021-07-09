assert(game.PlaceId == 286090429, 'wrong place sir');

local Tween				= loadstring(game:HttpGet'https://raw.githubusercontent.com/kikito/tween.lua/master/tween.lua')();
local RunService		= game:GetService'RunService';
local Players			= game:GetService'Players';
local LocalPlayer		= Players.LocalPlayer;
local Mouse				= LocalPlayer:GetMouse();
local Camera			= workspace.CurrentCamera;
local Dot				= Vector3.new().Dot;
local UIS				= game:GetService'UserInputService';
local ReplicatedStorage	= game:GetService'ReplicatedStorage';
local RunService		= game:GetService'RunService';
local Events			= ReplicatedStorage:WaitForChild'Events';
local WK				= ReplicatedStorage:WaitForChild'wkspc';
local IgnoreList		= {};
local FOVIncrement		= 2.5;

assert(Tween, 'Tween Library unavailable');

local ZeroVector = Vector3.new();

local SilentAimSettings = {
	Active = false;
	FOV = 10;
};

local Camera = workspace.CurrentCamera;
shared.iDrawings = shared.iDrawings or {};

local Circle = shared.iDrawings.FOV_Circle or Drawing.new'Circle';
Circle.Radius = 50;
Circle.Visible = true;
Circle.Color = Color3.new(0, 1, 0);
Circle.Filled = true;
Circle.Thickness = 0;
Circle.NumSides = 75;
Circle.Transparency = 0.25;
Circle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2);

shared.iDrawings.FOV_Circle = Circle;

local Circle_Outline = shared.iDrawings.FOV_Circle_Outline or Drawing.new'Circle';
Circle_Outline.Radius = 50;
Circle_Outline.Visible = true;
Circle_Outline.Color = Color3.new(1, 1, 0);
Circle_Outline.Transparency = .25;
Circle_Outline.Filled = false;
Circle_Outline.Thickness = 2;
Circle_Outline.NumSides = 75;
Circle_Outline.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2);

shared.iDrawings.FOV_Circle_Outline = Circle_Outline;

local Line = shared.iDrawings.Tracer or Drawing.new'Line';
Line.Color = Color3.new(1, 1, 1);
Line.From = Vector2.new(50, 200);
Line.To = Vector2.new(500, 200);
Line.Thickness = 2;
Line.Visible = true;

shared.iDrawings.Tracer = Line;

local Text = shared.iDrawings.Info or Drawing.new'Text';
Text.Outline = true;
Text.Center = true;
Text.Visible = true;
Text.Size = 20;
Text.Text = '';
Text.Color = Color3.new(1, 1, 1);
Text.Position = Vector2.new((Line.From.X + Line.To.X) / 2, (Line.From.Y + Line.To.Y) / 2 - 25);
Text.Transparency = 1;

shared.iDrawings.Info = Text;

local TSize = {};

function CreateCircleTween()
	TSize.Circle = Tween.new(1 / 2, {
		Radius = shared.iDrawings.FOV_Circle.Radius;
	}, {
		Radius = 100;
	}, 'outBounce');
end

CreateCircleTween();

function SameTeam(P1, P2)
	if P1 == P2 then
		return false
	end
	if WK.gametype.Value == 'Free For All' then
		return false
	end
	if P1.Neutral and P2.Neutral then
		return false
	elseif P1.TeamColor == P2.TeamColor then
		return true
	end
	return false
end

function CheckRay(Player, Distance, Position, Unit)
	local Pass = true;

	if Distance > 999 then return false; end

	local _Ray = Ray.new(Position, Unit * Distance);
	
	local List = {LocalPlayer.Character, Camera, Mouse.TargetFilter};

	for i,v in pairs(IgnoreList) do table.insert(List, v); end;

	local Hit = workspace:FindPartOnRayWithIgnoreList(_Ray, List);

	if Hit and not Hit:IsDescendantOf(Player.Character) then
		Pass = false;
		if Hit.Transparency >= 0.3 or not Hit.CanCollide and Hit.ClassName ~= Terrain then -- Detect invisible walls
			IgnoreList[#IgnoreList + 1] = Hit;
		end
	end

	return Pass;
end

function GetPlayerClosestToMouse()
	local Highest = {0, nil};

	for i, v in pairs(Players:GetPlayers()) do
		local Player = v;
		local Character = Player.Character;
		if Player ~= LocalPlayer and not SameTeam(Player, LocalPlayer) and Character then
			local Head = Character:FindFirstChild'Head';

			if Head and Head.Position.X ~= 0 and Head.Position.Z ~= 0 then
				local Distance = (Camera.CFrame.p - Head.Position).magnitude;
				local Direction = Camera.CFrame.lookVector.unit;
				local Relative = Player.Character.Head.Position - Camera.CFrame.p;
				local Unit = Relative.unit;

				local Visible = CheckRay(Player, Distance, Camera.CFrame.p, Unit);
				local DP = Direction:Dot(Unit);

				if Visible and DP > Highest[1] then
					Highest = {DP, Player, Head, Relative, Distance};
				end
			end
		end
	end

	return Highest;
end

UIS.InputEnded:connect(function(Input, Processed)
	if Processed then return end

	if Input.UserInputType.Name == 'Keyboard' then
		if Input.KeyCode == Enum.KeyCode.F4 then
			SilentAimSettings.Active = not SilentAimSettings.Active;
		elseif Input.KeyCode == Enum.KeyCode.P then
			TestingPoint = Mouse.Hit.p;
		elseif Input.KeyCode == Enum.KeyCode.F2 and SilentAimSettings.FOV > 5 then
			SilentAimSettings.FOV = SilentAimSettings.FOV - FOVIncrement;
			CreateCircleTween();
		elseif Input.KeyCode == Enum.KeyCode.F3 and SilentAimSettings.FOV < 90 then
			SilentAimSettings.FOV = SilentAimSettings.FOV + FOVIncrement;
			CreateCircleTween();
		elseif Input.KeyCode == Enum.KeyCode.F5 then
			
		end
	elseif Input.UserInputType.Name == 'MouseButton1' then
		SilentAimSettings.Active = true;
		delay(1 / 16, function() SilentAimSettings.Active = false; end);
	end
end)

local LastCheck = 0;
local LockedPlayer;
local PData;

function GetMagnitude(Vector)
	return math.sqrt(Vector.x * Vector.x + Vector.y * Vector.y + Vector.z * Vector.z);
end

function Normalize(Vector)
	return Vector / GetMagnitude(Vector);
end

function Round(Num, DecimalPlaces)
	local Multiplier = 10 ^ (DecimalPlaces or 0);
	return math.floor(Num * Multiplier + 0.5) / Multiplier;
end

function GetAngle(Point, Direction, From)
	local Normal = Normalize(Point - From);
	local Cross = Normal:Cross(Direction);
	local Magnitude = GetMagnitude(Cross);
	local DP = Normal:Dot(Direction);
	local Angle = math.atan2(Magnitude, DP) * (180 / math.pi);

	return Angle;
end

function GetDifference(Num, SNum)
	return math.abs(Num - SNum);
end

local CachedRadius = setmetatable({}, {
	__index = function(t, i)
		return rawget(t, i) or {
			Radius = 0;
			Angle = 0;
			Difference = 1e9;
		};
	end
});

local CI = 0;
local LT = tick();

RunService:UnbindFromRenderStep'CBRO-SL';

RunService:BindToRenderStep('CBRO-SL', 1, function()
	local DT = tick() - LT;
	LT = tick();

	local Color = Color3.fromHSV(tick() * 48 % 255/255, 1, 1);
	shared.iDrawings.FOV_Circle.Color = Color;
	shared.iDrawings.FOV_Circle_Outline.Color = Color;
	shared.iDrawings.Info.Color = Color3.new(1, 1, 1);
	shared.iDrawings.Tracer.Color = Color;

	if (tick() - LastCheck) > 1 / 20 then
		PData = GetPlayerClosestToMouse();
		LockedPlayer = PData[2];
	end
	
	local Center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2);

	local Line = shared.iDrawings.Tracer;
	local Info = shared.iDrawings.Info;
	local FOVC = shared.iDrawings.FOV_Circle;
	local FOVCO = shared.iDrawings.FOV_Circle_Outline;

	FOVC.Position = Center;
	FOVCO.Position = Center;

	local FOV = SilentAimSettings.FOV;
	local BestRadius = 0;

	local AimPosition = ZeroVector;
	local ScreenPosition, V = ZeroVector, false;

	if LockedPlayer and LockedPlayer.Character and LockedPlayer.Character:FindFirstChild'Head' then
		AimPosition = LockedPlayer.Character.Head.Position;
		ScreenPosition, V = Camera:WorldToViewportPoint(AimPosition);
	end

	local CF = Camera.CFrame * CFrame.Angles(0, math.rad(CI), 0) * CFrame.new(0, 0, -100);
	CF = CF.p;
	local Angle = Round(GetAngle(CF, Camera.CFrame.lookVector.unit, Camera.CFrame.p), 2);
	local CAng = Round(Angle, 1);

	CI = CI + 0.25;
	if (CI > 90) then CI = -90 end

	local TempPos, X = Camera:WorldToViewportPoint(CF);

	local Point	= TempPos; -- Center + Vector2.new(FOV, FOV);
	local Radius = math.sqrt((Point.X - Center.X)^2 + (Point.Y - Center.Y)^2);
	
	local CS = CachedRadius[CAng];
	local Difference = GetDifference(Angle, CS.Angle);

	if CAng % FOVIncrement == 0 and (Difference < CS.Difference or Difference < 0.15) then
		CachedRadius[CAng] = {
			Radius = Radius;
			Angle = Angle;
			Difference = GetDifference(Angle, CachedRadius[FOV].Angle);
		};
	end

	Angle = Round(GetAngle(AimPosition, Camera.CFrame.lookVector.unit, Camera.CFrame.p), 2);

	if CachedRadius[FOV].Radius == 0 then
		BestRadius = Radius;
	else
		BestRadius = CachedRadius[FOV].Radius;
	end

	TSize.Circle.target = {Radius = BestRadius};
	TSize.Circle:update(DT);

	FOVC.Radius = TSize.Circle.subject.Radius;
	FOVCO.Radius = TSize.Circle.subject.Radius;

	local NewText = ('%s\n%s | %s | %s\n%s\nFOV: %d'):format(tostring(AimPosition), Angle, CAng, BestRadius, tostring(Point), FOV);
	Info.Text = NewText;

	if ScreenPosition.Z > 0 then
		Line.Visible = true;
		Info.Visible = true;
		Line.From = Vector2.new(Center.x, Center.y);
		Line.To = Vector2.new(ScreenPosition.x, ScreenPosition.y);
	else
		Line.Visible = false;
		-- Info.Visible = false;
	end

	Info.Position = ScreenPosition.Z > 0 and Vector2.new((Line.From.X + Line.To.X) / 2, (Line.From.Y + Line.To.Y) / 2 - 75) or Center + Vector2.new(0, 25);

	if SilentAimSettings.Active and LockedPlayer and Angle < SilentAimSettings.FOV and LockedPlayer.Character and LockedPlayer.Character:FindFirstChild'Humanoid' and LockedPlayer.Character.Humanoid.Health > 1 and LockedPlayer.Character:FindFirstChild'Head' then
		local GunName = LocalPlayer.Character:FindFirstChild'EquippedTool';
		if GunName then
			local Gun = ReplicatedStorage.Weapons:FindFirstChild(GunName.Value);
			if Gun then
				local Distance = (LocalPlayer.Character.Head.Position - LockedPlayer.Character.Head.Position).magnitude
				local Backstab = Gun:FindFirstChild'Melee' and true or false;
				local Continue = false;

				if Backstab and Distance > 20 then
					Continue = false;
				else
					Continue = true;
				end

				if Continue then
					local Crit = math.random() > .6 and true or false;
					Events.HitPart:FireServer(LockedPlayer.Character.Head, -- Hit Part
						LockedPlayer.Character.Head.Position + Vector3.new(math.random(), math.random(), math.random()), -- Hit Position
						Gun.Name, -- Gun Name
						Crit and 2 or 1, -- Headshot
						Distance, -- Distance
						Backstab, -- Backstab
						Crit, -- Crit boost
						false, -- mcrit
						1, -- penetrated
						false, -- mgfalloff
						Gun.FireRate.Value,
						Gun.ReloadTime.Value,
						Gun.Ammo.Value,
						Gun.StoredAmmo.Value,
						Gun.Bullets.Value,
						Gun.EquipTime.Value,
						Gun.RecoilControl.Value,
						Gun.Auto.Value,
						Gun['Speed%'].Value,
						WK.DistributedTime.Value);
				end
			end
		end
	end
end)
