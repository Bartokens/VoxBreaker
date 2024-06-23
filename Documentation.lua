--Module by @Bartokens
--@Bartokens on discord and  @bartoken on tiktok
--Find information here: https://devforum.roblox.com/t/voxbreaker-an-oop-voxel-destruction-module/2935099



--[ DESCRIPTION ] ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 

-- VoxBreaker is an OOP module for all your voxel destruction needs, or map building needs depending on how you want to use it.


-----[ DOCUMENTATION ]---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

----------| HOW TO USE |
--
--				1. Firstly, for any parts you want the module to work on, give them the attribute "Destroyable" and set it to true. 
--					The attribute name can be changed in the module settings.

--					-Make sure your parts are anchored.

--				2. Then, place the module where you want. I recommend replicated storage, as the module works both on the client and on the server.
--				
--				3. On your script reference the module with: <local VoxBreaker = require(-wherever the module is stored-)>
--
--				4. Use the module however you want!


--	|FUNCTIONS|
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- The module currently has 4 functions, one of which is OOP based.

--		* VoxelizePart()
--			Repeatedly voxelizes a part until it meets the specified voxel size

--      		-Parameters: (Part : Part, MinimumVoxelSize : number, TimeToReset : number)
--					Part: Describes the part being voxelized
--					MinimumVoxelSize: Minimum possible size that Voxels can have. Module will try to match that size as accurately as possible. 5 by default.
--					TimeToReset: Time it takes in seconds to reset voxels back to normal. Will not reset if this is less than zero. 50 by default.

--				-Returns all voxels
--			

--			   -[EXAMPLE CODE] -- Prints all parts after voxelization
--				|	local VoxBreaker = require(game.ReplicatedStorage.VoxBreaker)						
--				|	local Part = workspace.Part
--				|	local Voxels = VoxBreaker:VoxelizePart(Part)
--				|	for i, v in pairs(Voxels) do
--				|		print(v)
--				|	end
--				|

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--		* CreateHitbox()
--			Creates one hitbox which divides any applicable parts that are touching it.


--      		-Parameters: (Size : Vector3, Cframe : CFrame , Shape : Enum.PartType , MinimumVoxelSize : number , TimeToReset : number,  Params : OverlapParams)
--					Size: Size of the hitbox. (1,1,1) By default
--					Cframe: CFrame of the hitbox. (0,0,0) By default
--					Shape: Shape of the hitbox. Block by default.
--					MinimumVoxelSize: Minimum possible size that Voxels can have. Module will try to match that size as accurately as possible. 5 by default.
--					TimeToReset: Time it takes in seconds to reset voxels back to normal. Will not reset if this is less than zero. 50 by default.

--				-Tip: the larger the hitbox is, the larger I reccommend setting the MinimumVoxelSize. This helps tremendously with performance.

--				-Returns all voxels touching the hitbox
--			

--			   -[EXAMPLE CODE] --Destroys all voxels in hitbox.
--				|	local VoxBreaker = require(game.ReplicatedStorage.VoxBreaker)						
--				|	local Size = Vector3.new(10,10,10)
--				| 	local Cframe = CFrame.new(5,5,5)
--				| 	local Shape = Enum.PartType.Ball
--				| 	local MinimumSize = 8
--				|	local Seconds = 20
--				|
--				|	local Voxels = VoxBreaker:CreateHitbox(Size,Cframe,Shape,MinimumSize,Seconds)
--				|	for i, v in pairs(Voxels) do
--				|		v:Destroy()
--				|	end
--				|
--			   -[EXAMPLE CODE] -- Unanchors all voxels in hitbox.
--				|	local VoxBreaker = require(game.ReplicatedStorage.VoxBreaker)						
--				|
--				|	local Voxels = VoxBreaker:CreateHitbox()
--				|	for i, v in pairs(Voxels) do
--				|		v.Anchored = false
--				|	end
--				|

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--		* CreateMoveableHitbox() --OOP BASED
--			Creates a moveable hitbox that can be controlled manually or welded to a specified part.

--      		-Parameters: (MinimumVoxelSize : number, TimeToReset : number, Size : Vector3, Cframe : CFrame , Shape : Enum.PartType, Params : OverlapParams )
--					MinimumVoxelSize: Minimum possible size that Voxels can have. Module will try to match that size as accurately as possible. 5 by default.
--					TimeToReset: Time it takes in seconds to reset voxels back to normal. Will not reset if this is less than zero. 50 by default.
--					Size: Size of the hitbox. (1,1,1) By default
--					Cframe: CFrame of the hitbox. (0,0,0) By default
--					Shape: Shape of the hitbox. Block by default.

				--Note, you can set the minimum voxel size to 'Relative', and the minimum size will change depending on the size of the hitbox.
				

--				-Returns hitbox object

--				-Events:
--					.Touched(Parts)
--						Fires on every frame that the hitbox is touching applicable parts.
--						The parts argument contains the parts being touched.
--				-Functions:
--					:Start()
--						Starts the moveable hitbox.
--					:Stop()
--						Stops the moveable hitbox.
--					:Destroy()
--						Destroys the moveable hitbox.
--					:GetTouchingParts()
--						returns all parts touching the hitbox.
--					:WeldTo(Part)
--						Welds the hitbox to a specified part.
--					:UnWeld()
--						Unwelds the hitbox


--			   -[EXAMPLE CODE] --Creates a hitbox that is welded to a part and prints whenever touched
--				|
--				|	local VoxBreaker = require(game.ReplicatedStorage.VoxBreaker)						
--				|	local Size = Vector3.new(10,10,10)
--				| 	local Cframe = CFrame.new(5,5,5)
--				| 	local Shape = Enum.PartType.Ball
--				| 	local MinimumSize = 8
--				|	local Seconds = 20
--				|	local Projectile = Instance.new("Part")
--				| 	Projectile.Parent = workspace
--				|	
--				|	local Hitbox = VoxBreaker.CreateMoveableHitbox(MinimumSize,Seconds,Size,Cframe,Shape)
--				|	Hitbox:Start()
--				|	Hitbox:WeldTo(Projectile)
--				|	Hitbox.Touched:Connect(function()
--				|		print("Touched")
--				|	end)
--				|
--				|
--			   -[EXAMPLE CODE] -- Creates a hitbox that can be moved manually, and stops after 5 seconds
--				|
--				|	local VoxBreaker = require(game.ReplicatedStorage.VoxBreaker)						
--				|	local Size = Vector3.new(10,10,10)
--				| 	local Cframe = CFrame.new(5,5,5)
--				| 	local Shape = Enum.PartType.Ball
--				| 	local MinimumSize = 8
--				|	local Seconds = 20
--				|	local Projectile = Instance.new("Part")
--				| 	Projectile.Parent = workspace
--				|
--				|	local Hitbox = VoxBreaker.CreateMoveableHitbox(nil,MinimumSize,Seconds,Size,Cframe,Shape)
--				|	Hitbox:Start()
--				|	Hitbox.Part.Position = Vector3.new(10,10,10)
--				|	task.wait(2)
--				|	print(Hitbox:GetTouchingParts())
--				|	task.wait(3)
--				|	
--				|	Hitbox:Stop()
--				|

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--		* CutInHalf() 
--			Cuts a specified part into two equal halves.

--      		-Parameters: (Part : Part)
--					Part: Part to cut.

--				-Returns halves

--			   -[EXAMPLE CODE] --Split a part in two
--				|
--				|	local VoxBreaker = require(game.ReplicatedStorage.VoxBreaker)	
--				|	local Part = workspace.Part
--				|	VoxBreaker:CutInHalf(Part)
--				|
--				|


