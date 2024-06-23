local VoxBreaker = {}
VoxBreaker.__index = VoxBreaker












-----[ SETTINGS ]-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local TagName = "Destroyable" --Name of Attribute that module will check parts for
local RandomColors = false  -- Will make every part a random color. Set this to true if you want a visual representation of how the parts are being divided.
local Visualizer = false -- Will make hitboxes visible when set to true
local miniumCubeSize = 5 --Default Minimum possible size that divided cubes can be.
local voxelFolder = workspace --Where the voxels are stored. Workspace by default.
local AutoStartMoveable = false --Toggle this to true if you want your moveable hitboxes to activate automatically without having to use :Start()
local PartCacheEnabled = true --Enables PartCache. This significantly improves performance so I reccommend keeping it on. 


----[ RESOURCES ]------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local rs = game:GetService("RunService")

local cache
local PartFolder

if PartCacheEnabled then
	local PC = require(script.PartCache)

	PartFolder = Instance.new("Folder")
	PartFolder.Name = "PartCache"..tostring(math.random(1,5))
	PartFolder.Parent = workspace

	local TemplatePart = Instance.new("Part")
	TemplatePart.Anchored = true
	cache = PC.new(TemplatePart,10000,PartFolder)
	cache.ExpansionSize = 100
	TemplatePart:Destroy()	
end



-----[ LOCAL FUNCTIONS ]--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


local destructionSchedule = {} -- Keeps track of parts and their destruction timers

local function Destroy(part:Instance, timeToDestroy)

	-- If the part is already scheduled for destruction, cancel the previous timer
	if destructionSchedule[part] then
		task.cancel(destructionSchedule[part])
	end

	-- Schedule a new destruction timer
	destructionSchedule[part] = task.delay(timeToDestroy, function()
		if part and part.Parent then
			
			
			if PartCacheEnabled then
				if part:IsA("Model") then
					for i, v in pairs(part:GetChildren()) do
						if table.find(cache.InUse,v) then
							for i,child in pairs(v:GetChildren()) do
								child:Destroy()
							end
							cache:ReturnPart(v)
							v.Parent = PartFolder
						end
					end
				end
			end
			
			part:Destroy()
		end
		destructionSchedule[part] = nil -- Remove the part from the schedule once it's destroyed
	end)
end



local function partCanSubdivide(part : Part) --Checks if part is rectangular.

	local Threshold = 1.5  -- How much of a difference there can be between the largest axis and the smallest axis 

	local largest = math.max(part.Size.X, part.Size.Y, part.Size.Z) --Largest Axis
	local smallest = math.min(part.Size.X,part.Size.Y, part.Size.Z) -- Smallest Axis

	if smallest == part.Size.X then 
		smallest = math.min(part.Size.Y, part.Size.Z)
	elseif smallest == part.Size.Y then
		smallest = math.min(part.Size.X, part.Size.Z)
	elseif smallest == part.Size.Z then
		smallest = math.min(part.Size.X, part.Size.Y)
	end

	return largest >= Threshold * smallest 
	--Returns true if part is rectangular. 
	--Part is rectangular if the largest axis is at least 1.5x bigger than the smallest axis

end

local function getLargestAxis(part : Part)  --Returns Largest Axis of Part size
	return math.max(part.Size.X, part.Size.Y, part.Size.Z)
end

local function CutPartinHalf(block : Part, TimeToReset : number) --Cuts part into two evenly shaped pieces.
	local partTable = {} --Table of parts to be returned
	local bipolarVectorSet = {} --Offset on where to place halves


	local X = block.Size.X
	local Y = block.Size.Y
	local Z = block.Size.Z

	if getLargestAxis(block) == X then --Changes offset vectors depending on what the largest axis is.
		X /= 2

		bipolarVectorSet = {
			Vector3.new(1,0,0),
			Vector3.new(-1,0,0),
		}

	elseif getLargestAxis(block) == Y then 
		Y/=2

		bipolarVectorSet = {
			Vector3.new(0,1,0),
			Vector3.new(0,-1,0),
		}

	elseif getLargestAxis(block) == Z then
		Z/=2

		bipolarVectorSet = {
			Vector3.new(0,0,1),
			Vector3.new(0,0,-1),
		}

	end

	local model 
	
	if block.Parent:IsA("Model") and block.Parent:GetAttribute("VoxelHolder") then
		model = block.Parent
	else
		model = Instance.new("Model")
		model.Name = "VoxelHolder"
		model.Parent = voxelFolder
		model:SetAttribute("VoxelHolder",true)
	end
	
	if TimeToReset and TimeToReset >= 0 then
		Destroy(model,TimeToReset)
	end


	local halfSize = Vector3.new(X,Y,Z)

	for _, offsetVector in pairs(bipolarVectorSet) do
		
		
		local clone
		if PartCacheEnabled then
			clone = cache:GetPart()
			CopyProperties(block,clone)
		else
			clone = block:Clone()
		end
		
		
		
		if RandomColors then
			clone.Color = Color3.fromRGB(math.random(1,255),math.random(1,255),math.random(1,255))
		end

		
		clone.Parent = model
		clone.Size = halfSize
		clone.CFrame += block.CFrame:VectorToWorldSpace((halfSize / 2.0) * offsetVector)
		table.insert(partTable,clone)
	end

	if not TimeToReset or TimeToReset < 0 then
		block:Destroy()
	else
		if block:GetAttribute("Transparency") == nil then
			block:SetAttribute("Transparency",block.Transparency)
			block:SetAttribute("Collide",block.CanCollide)
			block:SetAttribute("Query",block.CanQuery)
		end
		block.Transparency = 1
		block.CanCollide = false
		block.CanQuery = false
		block:SetAttribute(TagName,false)
		
		for i,v in block:GetChildren() do
			task.spawn(function()
				if v:IsA("SurfaceGui") then
					local enabled = v.Enabled
					v.Enabled = false
					repeat task.wait()

					until model.Parent == nil
					v.Enabled = enabled
				elseif v:IsA("Decal") then
					local transparency = v.Transparency
					v.Transparency = 1
					repeat task.wait()

					until model.Parent == nil
					v.Transparency = transparency
				elseif v:IsA("Texture") then
					local transparency = v.Transparency
					v.Transparency = 1
					repeat task.wait()

					until model.Parent == nil
					v.Transparency = transparency					
				end
			end)
		end

		task.spawn(function()
			repeat task.wait()

			until model.Parent == nil
			
			block.Transparency = block:GetAttribute("Transparency")
			block.CanQuery =  block:GetAttribute("Query")
			block.CanCollide = block:GetAttribute("Collide")
			block:SetAttribute(TagName,true)
		end)



	end
	

	if block.Parent:IsA("Model") and block.Parent:GetAttribute("VoxelHolder") then
		if PartCacheEnabled then
			for i,v in pairs(block:GetChildren()) do
				v:Destroy()
			end
			cache:ReturnPart(block)
			block.Parent = PartFolder
		else
			block:Destroy()
		end
	end

	return partTable -- Returns a table containing the two halves
end


local function DivideBlock(block : Part, MinimumVoxelSize : number, Parent : Instance, TimeToReset : number) --Divides part into evenly shaped cubes.
	--MinimumvVoxelSize Parameter is used to describe the minimum possible size that the parts can be divided. To avoid confusion, this is not the size that the parts will be divided into, but rather the minimum allowed
	--You CANNOT change the size of the resulting parts. They are dependent on the size of the original part.

	local partTable = {} -- Table of parts to be returned
	local minimum = MinimumVoxelSize or miniumCubeSize


	if block.Size.X > minimum or block.Size.Y > minimum or block.Size.Z > minimum then
		if partCanSubdivide(block) then --If part is rectangular then it is cut in half, otherwise it is divided into cubes.
			partTable = CutPartinHalf(block,TimeToReset)
			
		else
			local model 
			if block.Parent:IsA("Model") and block.Parent:GetAttribute("VoxelHolder") then
				model = block.Parent
			else
				model = Instance.new("Model")
				model.Name = "VoxelHolder"
				model.Parent = voxelFolder
				model:SetAttribute("VoxelHolder",true)
			end


			if TimeToReset and TimeToReset >= 0 then
				Destroy(model,TimeToReset)
			end



			local Threshold = 1.5  -- How much of a difference there can be between the largest axis and the smallest axis 

			local largest = math.max(block.Size.X, block.Size.Y, block.Size.Z) --Largest Axis
			local smallest = math.min(block.Size.X,block.Size.Y, block.Size.Z) -- Smallest Axis




			if smallest == block.Size.Y and smallest * Threshold <= largest then




				


				local bipolarVectorSet = {}

				local X = block.Size.X
				local Y = block.Size.Y
				local Z = block.Size.Z

				X /= 2
				Z /= 2
				bipolarVectorSet = { --Offset Vectors
					Vector3.new(-1,0,1),
					Vector3.new(1,0,-1),
					Vector3.new(1,0,1),
					Vector3.new(-1,0,-1),

				}


				local halfSize = Vector3.new(X,Y,Z)



				for _, offsetVector in pairs(bipolarVectorSet) do

					local clone
					if PartCacheEnabled then
						clone = cache:GetPart()
						CopyProperties(block,clone)
					else
						clone = block:Clone()
					end
					clone:SetAttribute("Voxel",true)
					if RandomColors then
						clone.Color = Color3.fromRGB(math.random(1,255),math.random(1,255),math.random(1,255))
					end

					clone.Parent = Parent or model
					clone.Size = halfSize
					clone.CFrame += block.CFrame:VectorToWorldSpace((halfSize / 2.0) * offsetVector)
					table.insert(partTable,clone)
				end




			elseif smallest == block.Size.X and smallest * Threshold <= largest then




		


				local bipolarVectorSet = {}

				local X = block.Size.X
				local Y = block.Size.Y
				local Z = block.Size.Z

				Y /= 2
				Z /= 2
				bipolarVectorSet = { --Offset Vectors
					Vector3.new(0,-1,1),
					Vector3.new(0,1,1),
					Vector3.new(0,-1,-1),
					Vector3.new(0,1,-1),

				}


				local halfSize = Vector3.new(X,Y,Z)



				for _, offsetVector in pairs(bipolarVectorSet) do

					local clone
					if PartCacheEnabled then
						clone = cache:GetPart()
						CopyProperties(block,clone)
					else
						clone = block:Clone()
					end
					clone:SetAttribute("Voxel",true)
					if RandomColors then
						clone.Color = Color3.fromRGB(math.random(1,255),math.random(1,255),math.random(1,255))
					end

					clone.Parent = Parent or model
					clone.Size = halfSize
					clone.CFrame += block.CFrame:VectorToWorldSpace((halfSize / 2.0) * offsetVector)
					table.insert(partTable,clone)



				end 
			elseif smallest == block.Size.Z and smallest * Threshold <= largest then




				



				local bipolarVectorSet = {}

				local X = block.Size.X
				local Y = block.Size.Y
				local Z = block.Size.Z

				X /= 2
				Y /= 2
				bipolarVectorSet = { --Offset Vectors
					Vector3.new(1,-1,0),
					Vector3.new(1,1,0),
					Vector3.new(-1,-1,0),
					Vector3.new(-1,1,0),

				}


				local halfSize = Vector3.new(X,Y,Z)



				for _, offsetVector in pairs(bipolarVectorSet) do

					local clone
					if PartCacheEnabled then
						clone = cache:GetPart()
						CopyProperties(block,clone)
					else
						clone = block:Clone()
					end
					clone:SetAttribute("Voxel",true)
					if RandomColors then
						clone.Color = Color3.fromRGB(math.random(1,255),math.random(1,255),math.random(1,255))
					end

					clone.Parent = Parent or model
					clone.Size = halfSize
					clone.CFrame += block.CFrame:VectorToWorldSpace((halfSize / 2.0) * offsetVector)
					table.insert(partTable,clone)
				end





			else




				local bipolarVectorSet = { --Offset Vectors
					Vector3.new(1,1,1),
					Vector3.new(1,1,-1),
					Vector3.new(1,-1,1),
					Vector3.new(1,-1,-1),
					Vector3.new(-1,1,1),
					Vector3.new(-1,1,-1),
					Vector3.new(-1,-1,1),
					Vector3.new(-1,-1,-1),
				}

				local halfSize = block.Size / 2.0

				for _, offsetVector in pairs(bipolarVectorSet) do

					local clone
					if PartCacheEnabled then
						clone = cache:GetPart()
						CopyProperties(block,clone)
					else
						clone = block:Clone()
					end
					if RandomColors then
						clone.Color = Color3.fromRGB(math.random(1,255),math.random(1,255),math.random(1,255))
					end

					clone.Parent = Parent or model
					clone.Size = halfSize
					clone.CFrame += block.CFrame:VectorToWorldSpace((halfSize / 2.0) * offsetVector)
					table.insert(partTable,clone)
				end




			end



			if block.Parent:IsA("Model") and block.Parent:GetAttribute("VoxelHolder") then
				if PartCacheEnabled then
					for i,v in pairs(block:GetChildren()) do
						v:Destroy()
					end
					cache:ReturnPart(block)
					block.Parent = PartFolder
				else
					block:Destroy()
				end
			end


			if not TimeToReset or TimeToReset < 0 then
				block:SetAttribute(TagName,false)
				block:Destroy()

			else


				if block:GetAttribute("Transparency") == nil then
					block:SetAttribute("Transparency",block.Transparency)
					block:SetAttribute("Collide",block.CanCollide)
					block:SetAttribute("Query",block.CanQuery)
				end



				block.Transparency = 1
				block.CanCollide = false
				block.CanQuery = false
				block:SetAttribute(TagName,false)

				for i,v in block:GetChildren() do
					task.spawn(function()
						if v:IsA("SurfaceGui") then
							local enabled = v.Enabled
							v.Enabled = false
							repeat task.wait()

							until model.Parent == nil
							v.Enabled = enabled
						elseif v:IsA("Decal") then
							local transparency = v.Transparency
							v.Transparency = 1
							repeat task.wait()

							until model.Parent == nil
							v.Transparency = transparency
						elseif v:IsA("Texture") then
							local transparency = v.Transparency
							v.Transparency = 1
							repeat task.wait()

							until model.Parent == nil
							v.Transparency = transparency					
						end
					end)
				end

				task.spawn(function()
					repeat task.wait()
					until model.Parent == nil





					block.Transparency = block:GetAttribute("Transparency")
					block.CanQuery =  block:GetAttribute("Query")
					block.CanCollide = block:GetAttribute("Collide")

					block:SetAttribute(TagName,true)
				end)



			end
		end


		
	elseif block.Parent:GetAttribute("VoxelHolder") == nil and block:GetAttribute("Voxel") == nil then

		if block:GetAttribute("Transparency") == nil then
			block:SetAttribute("Transparency",block.Transparency)
			block:SetAttribute("Collide",block.CanCollide)
			block:SetAttribute("Query",block.CanQuery)
		end
		local clone
		if PartCacheEnabled then
			clone = cache:GetPart()
			CopyProperties(block,clone)
		else
			clone = block:Clone()
		end
		clone.Parent = block.Parent	
		if TimeToReset and TimeToReset >= 0 then
			Destroy(clone,TimeToReset)
		end



		if not TimeToReset or TimeToReset < 0 then
			block:SetAttribute(TagName,false)
			
		block:Destroy()
			
		else







			block.Transparency = 1
			block.CanCollide = false
			block.CanQuery = false
			block:SetAttribute(TagName,false)
			
			
			for i,v in block:GetChildren() do
				task.spawn(function()
					if v:IsA("SurfaceGui") then
						local enabled = v.Enabled
						v.Enabled = false
						task.wait(TimeToReset)
						v.Enabled = enabled
					elseif v:IsA("Decal") then
						local transparency = v.Transparency
						v.Transparency = 1
						task.wait(TimeToReset)
						v.Transparency = transparency
					elseif v:IsA("Texture") then
						local transparency = v.Transparency
						v.Transparency = 1
						task.wait(TimeToReset)
						v.Transparency = transparency					
					end
				end)
			end
			

			task.spawn(function()
				task.wait(TimeToReset)


				block.Transparency = block:GetAttribute("Transparency")
				block.CanQuery =  block:GetAttribute("Query")
				block.CanCollide = block:GetAttribute("Collide")
				block:SetAttribute(TagName,true)
			end)



		end

	end




	return partTable --Returns resulting parts
end

local function GetTouchingParts(part : Part, Params : OverlapParams) --Used to get all the parts within a part.
	local results = {}
	local touching
	if Params then
		touching = workspace:GetPartsInPart(part,Params)
	else
		touching = workspace:GetPartsInPart(part)
	end
	
	for i,v in pairs(touching) do
		if v:IsA("Part") then
			if v:GetAttribute(TagName) == true then
				table.insert(results,v)
			end
		end
	end
	return results --Returns a table of all eligible parts touching the specified part
end

function CopyProperties(PartOne:Part,PartTwo:Part)
	PartTwo.Anchored = PartOne.Anchored
	PartTwo.Transparency = PartOne.Transparency
	PartTwo.CanCollide = PartOne.CanCollide
	PartTwo.CanQuery = PartOne.CanQuery
	PartTwo.CanTouch = PartOne.CanTouch
	PartTwo.CastShadow = PartOne.CastShadow
	PartTwo.CFrame = PartOne.CFrame
	PartTwo.Color = PartOne.Color
	PartTwo.Name = PartOne.Name
	PartTwo.Size = PartOne.Size
	PartTwo.Material = PartOne.Material
	PartTwo.Shape = PartOne.Shape
	PartTwo.CollisionGroup = PartOne.CollisionGroup

	PartTwo:SetAttribute(TagName,PartOne:GetAttribute(TagName))
	

	
	for i,v in PartOne:GetChildren() do
		local clone = v:Clone()
		clone.Parent = PartTwo
	end
	
		


end

-----[ MODULE FUNCTIONS ]----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function VoxBreaker:VoxelizePart(Part : Part, MinimumVoxelSize : number, TimeToReset : number) --Repeatedly voxelizes a part until it meets the specified voxel size
	local minimum = MinimumVoxelSize  or 5

	local parts = DivideBlock(Part,minimum,nil,TimeToReset)
	repeat

		for i, v in pairs(parts) do
			if v:IsDescendantOf(workspace) then
				local parts2 = DivideBlock(v,minimum)
				for _, p in  pairs(parts2) do
					table.insert(parts,p)
				end
			else
				table.remove(parts,i)
			end
		end

		local check = true
		for i, v in pairs(parts) do
			if math.floor(v.Size.X) > minimum or math.floor(v.Size.Y) > minimum or math.floor(v.Size.Z) > minimum then
				check = false
			end
		end
	until check == true
	return parts
end

function VoxBreaker:CreateHitbox(Size : Vector3 | string, Cframe : CFrame , Shape : Enum.PartType , MinimumVoxelSize : number , TimeToReset : number, Params : OverlapParams) --Creates one hitbox which divides any applicable parts that are touching it. 
	--If the TimeToReset parameter is less than 0, then the parts will not reset.


	local DefaultSize = Vector3.new(1,1,1) -- Default Hitbox Size
	local DefaultShape = Enum.PartType.Block -- Default Shape of hitbox
	local DefaultTimeToReset = 50 --Default time in seconds it takes for divided parts to reset	


	local size = Size or DefaultSize
	local shape = Shape or DefaultShape
	local minimum = MinimumVoxelSize or miniumCubeSize
	local timetoreset = TimeToReset or DefaultTimeToReset



	local partTable = {} --Table of parts to be returned

	local part = Instance.new("Part") --Creating the hitbox

	Destroy(part,0.5) --Destroys hitbox in 0.5 seconds

	part.Size = Size or DefaultSize 
	part.CFrame = Cframe or CFrame.new(0,0,0)
	part.Anchored = true
	part.Transparency = 0.6
	if Shape then
		part.Shape = Shape
	end
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(255, 0, 0)
	
	if MinimumVoxelSize == "Relative" then
		local ratio = 1/3
		local largest = getLargestAxis(part)
		minimum = largest * ratio
	end

	if Visualizer then
		part.Parent = game.Workspace
	end

	repeat
		local touching = GetTouchingParts(part,Params) --Initial check

		local check = true



		for i, v in pairs(touching) do
			if v:IsA("Part") and v:GetAttribute(TagName) then

				DivideBlock( v , minimum , nil , timetoreset)

			end
		end

		partTable = GetTouchingParts(part,Params)

		for i, v in pairs(partTable) do
			if v:IsA("Part") and v:GetAttribute(TagName) then			
				if math.floor(v.Size.X) > minimum or math.floor(v.Size.Y) > minimum or math.floor(v.Size.Z) > minimum then
					check = false
				end
			else
				table.remove(partTable,i)
			end
		end

	until check == true
	return partTable --Returns all parts touching the hitbox



end

function VoxBreaker.CreateMoveableHitbox(MinimumVoxelSize : number | string, TimeToReset : number, Size : Vector3, Cframe : CFrame , Shape : Enum.PartType, Params : OverlapParams) --Creates a hitbox that can be moved or moves along with a specified part
	local self = {}

	--If WeldTo is specified, hitbox will move with specified part

	self.TouchEvent = Instance.new("BindableEvent") 
	self.Touched = self.TouchEvent.Event


	local DefaultSize = Vector3.new(1,1,1) -- Default Hitbox Size
	local DefaultShape = Enum.PartType.Block -- Default Shape of hitbox
	local DefaultTimeToReset = 50 --Default time in seconds it takes for divided parts to reset	



	local size = Size or DefaultSize
	local shape = Shape or  DefaultShape
	local minimum = MinimumVoxelSize or miniumCubeSize
	local timetoreset = TimeToReset or DefaultTimeToReset


	local part = Instance.new("Part") --Creating the hitbox
	if AutoStartMoveable then
		part:SetAttribute("Active",true)
	else
		part:SetAttribute("Active",false)		
	end

	self.Part = part


	part.Size = Size or DefaultSize 
	part.CFrame = Cframe or CFrame.new(0,0,0)
	part.Anchored = true
	part.Transparency = 0.6
	if Shape then
		part.Shape = Shape
	end
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(255, 0, 0)

	if Visualizer then
		part.Parent = game.Workspace
	end

	task.spawn(function()
		if rs:IsClient() then --If running on client, then runservice is used
			local lastTouching = {}
			local connection = rs.RenderStepped:Connect(function()
				if MinimumVoxelSize == "Relative" then
					local ratio = 1/3
					local largest = getLargestAxis(part)
					minimum = largest * ratio
				end
				if part:GetAttribute("Active") == true then
					local touching =  GetTouchingParts(part,Params)
					if touching[1] ~= nil then

						local partTable = {}
						repeat
							local touching = GetTouchingParts(part,Params) --Initial check

							local check = true



							for i, v in pairs(touching) do

								if v:IsA("Part") and v:GetAttribute(TagName) then

									DivideBlock( v , minimum , nil , timetoreset)

								end
							end

							partTable = GetTouchingParts(part,Params)


							for i,v in pairs(lastTouching) do
								if table.find(partTable,v)  then
									table.remove(partTable,table.find(partTable,v))
								else
									table.remove(lastTouching,table.find(lastTouching,v))
								end
							end

							for i, v in pairs(partTable) do
								if v:IsA("Part") and v:GetAttribute(TagName) then			
									if math.floor(v.Size.X) > minimum or math.floor(v.Size.Y) > minimum or math.floor(v.Size.Z) > minimum then
										check = false
									end
								else
									table.remove(partTable,i)
								end
							end


						until check == true

						for i,v in partTable do
							if table.find(lastTouching,v) == nil then
								table.insert(lastTouching,v)
							else
								table.remove(partTable,table.find(partTable,v))
							end
						end



                        
						if #partTable >= 1 then
							self.TouchEvent:Fire(partTable)
						end

					end					
				end
			end)
			local connection2 
			connection2 = part.AttributeChanged:Connect(function(attribute)
				if part:GetAttribute("Active") == false and part.Parent == nil then
					connection:Disconnect()
					connection2:Disconnect()
				end
			end)	
		else --If running on server, than a while loop is used.
			local connection = true
			local lastTouching = {}
			while connection do
				if MinimumVoxelSize == "Relative" then
					local ratio = 1/3
					local largest = getLargestAxis(part)
					minimum = largest * ratio
				end
				if part:GetAttribute("Active") == true then
					local touching =  GetTouchingParts(part,Params)
					if touching[1] ~= nil then

						local partTable = {}
						repeat
							local touching = GetTouchingParts(part,Params) --Initial check

							local check = true



							for i, v in pairs(touching) do

								if v:IsA("Part") and v:GetAttribute(TagName) then

									DivideBlock( v , minimum , nil , timetoreset)

								end
							end

							partTable = GetTouchingParts(part,Params)


							for i,v in pairs(lastTouching) do
								if table.find(partTable,v)  then
									table.remove(partTable,table.find(partTable,v))
								else
									table.remove(lastTouching,table.find(lastTouching,v))
								end
							end

							for i, v in pairs(partTable) do
								if v:IsA("Part") and v:GetAttribute(TagName) then			
									if math.floor(v.Size.X) > minimum or math.floor(v.Size.Y) > minimum or math.floor(v.Size.Z) > minimum then
										check = false
									end
								else
									table.remove(partTable,i)
								end
							end


						until check == true

						for i,v in partTable do
							if table.find(lastTouching,v) == nil then
								table.insert(lastTouching,v)
							else
								table.remove(partTable,table.find(partTable,v))
							end
						end




						if #partTable >= 1 then
							self.TouchEvent:Fire(partTable)
						end

					end
				end
				task.wait()
			end
			local connection2 
			connection2 = part.AttributeChanged:Connect(function(attribute)
				if part:GetAttribute("Active") == false and part.Parent == nil then
					connection = false
					connection2:Disconnect()
				end
			end)
			
		end				
	end)

	return setmetatable(self,VoxBreaker)
end

function VoxBreaker:Start() -- Use to start moveable hitbox.
	self.Part:SetAttribute("Active",true)
end

function VoxBreaker:Stop() -- Use to stop moveable hitbox
	self.Part:SetAttribute("Active",false)
end

function VoxBreaker:Destroy() -- Use to destroy moveable hitbox
	self.Part:SetAttribute("Active",false)
	self.Part:Destroy()
end

function VoxBreaker:WeldTo(Part : Part) --welds the hitbox to a specified part
	task.spawn(function()
		if rs:IsClient() then
			local connection = rs.RenderStepped:Connect(function()
				if Part then
					self.Part.CFrame = Part.CFrame
				end

			end)
			local connection2 
			connection2 = self.Part.AttributeChanged:Connect(function(attribute)
				if self.Part:GetAttribute("Active") == false then
					connection:Disconnect()
					connection2:Disconnect()
				elseif self.Part:GetAttribute("Unweld") == true then
					connection:Disconnect()
					connection2:Disconnect()
				end
			end)	
		else

			local canRun = true
			
			local connection
			connection = self.Part.AttributeChanged:Connect(function(attribute)
				if self.Part:GetAttribute("Active") == false then
					canRun = false
					connection:Disconnect()
				elseif self.Part:GetAttribute("Unweld") == true then
					canRun = false
					connection:Disconnect()
				end
			end)
			
			while canRun do
				if Part then
					self.Part.CFrame = Part.CFrame
				end
				task.wait()
			end
			
		end
		
	end)
end

function VoxBreaker:UnWeld() -- Unwelds the hitbox
	self.Part:SetAttribute("Unweld",true)
	task.spawn(function()
		task.wait(0.1)
		self.Part:SetAttribute("Unweld",nil)
	end)

end

function VoxBreaker:GetTouchingParts(part : Part) -- Returns all parts touching moveable hitbox OR specified part
	if part then
		return GetTouchingParts(part)
	else
		return GetTouchingParts(self.Part)
	end
end

function VoxBreaker:CutInHalf(Part : Part, TimeToReset : number) -- Cuts a specified part into two pieces. Include parent if you want to change the parent of the parts.
	return CutPartinHalf(Part,TimeToReset) -- Returns halves
end

function VoxBreaker:Divide(part:Part,minimumVoxelSize:number,parent:Instance,timeToReset:number) -- Divides a part down once, into four pieces. Will not divide past minimum.
	return DivideBlock(part,minimumVoxelSize,parent,timeToReset)
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return VoxBreaker
