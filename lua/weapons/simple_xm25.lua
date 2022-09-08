AddCSLuaFile()

DEFINE_BASECLASS("simple_base")

SWEP.Base = "simple_base"

SWEP.PrintName = "XM25 CDTE"
SWEP.Category = "Simple Weapons: Customs"

SWEP.Slot = 4

SWEP.Spawnable = true

SWEP.UseHands = true

SWEP.ViewModelTargetFOV = 54

SWEP.ViewModel = Model("models/simple_weapons/weapons/c_xm25.mdl")
SWEP.WorldModel = Model("models/simple_weapons/weapons/w_xm25.mdl")

SWEP.HoldType = "ar2"
SWEP.LowerHoldType = "passive"

SWEP.Firemode = 0

SWEP.Primary = {
	Ammo = "SMG1_Grenade",

	ClipSize = 5,
	DefaultClip = 5,

	Damage = 120,
	Delay = 0.5,

	Recoil = {
		MinAng = Angle(1.8, -1, 0),
		MaxAng = Angle(2, 1, 0),
		Punch = 0.6,
		Ratio = 0.4
	},

	Sound = "Simple_XM25.Single"
}

SWEP.ViewOffset = Vector(0, -1, 0)

function SWEP:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:AddNetworkVar("Float", "FuseDistance")
	self:AddNetworkVar("Float", "AngleOfAttack")
end

function SWEP:FireWeapon()
	local ply = self:GetOwner()

	self:EmitFireSound()

	self:SendTranslatedWeaponAnim(ACT_VM_PRIMARYATTACK)

	ply:SetAnimation(PLAYER_ATTACK1)

	if SERVER then
		local ent = ents.Create("simple_ent_xm25_proj")

		local dir = self:GetShootDir()
		local ang = dir:Angle()

		ent:SetPos(ply:GetShootPos())
		ent:SetAngles(ang)

		ent:SetOwner(ply)

		ent:SetVelocity(dir * 3000)

		ent:Spawn()
		ent:Activate()
	end
end

local function TargetSolution(target, origin, velocity, gravity, high)
	local elevation = target.z - origin.z
	local distance = Vector(target.x, target.y, 0):Distance(Vector(origin.x, origin.y, 0))

	gravity = -(gravity).z

	if high then
		return math.atan(((velocity ^ 2) * (1 + math.sqrt(1 - (gravity * (gravity * (distance ^ 2) + 2 * (velocity ^ 2) * elevation)) / (velocity ^ 4)))) / (gravity * distance))
	else
		return math.atan(((velocity ^ 2) * (1 - math.sqrt(1 - (gravity * (gravity * (distance ^ 2) + 2 * (velocity ^ 2) * elevation)) / (velocity ^ 4)))) / (gravity * distance))
	end
end

local meters = (1 / 16) * 0.3048

function SWEP:AltFire()
	self.Primary.Automatic = false

	local ply = self:GetOwner()
	local dir = (ply:GetAimVector():Angle() + ply:GetViewPunchAngles()):Forward()

	local trace = util.TraceLine({
		start = ply:GetShootPos(),
		endpos = ply:GetShootPos() + dir * 56756,
		mask = MASK_SHOT,
		filter = ply
	})

	local oldDistance = self:GetFuseDistance()

	self:SetFuseDistance(0)
	self:SetAngleOfAttack(0)

	if not trace.Hit or trace.HitSky then -- Nothing to range against
		return
	end

	local distance = trace.StartPos:Distance(trace.HitPos)

	if math.Round(distance * meters) > 999 then -- Out of range
		return
	end

	local solve = TargetSolution(trace.HitPos, trace.StartPos, 3000, physenv.GetGravity() * 0.5, false)

	if solve != solve then -- No solution
		return
	end

	if math.Round(distance) == math.Round(oldDistance) then -- Clear range
		return
	end

	self:SetFuseDistance(distance)
	self:SetAngleOfAttack(-math.deg(solve))
end

if CLIENT then
	surface.CreateFont("xm25_lcd", {
		font = "Open 24 Display St",
		size = 24,
		weight = 0,
		additive = false,
		blursize = 1,
		antialias = true,
	})

	local color = Color(255, 0, 0)

	function SWEP:DrawHUDBackground()
		BaseClass.DrawHUDBackground(self)

		surface.SetFont("xm25_lcd")

		local centerX = ScrW() * 0.5
		local centerY = ScrH() * 0.5

		local offset = ScreenScale(8)

		local trace = self:GetOwner():GetEyeTrace()
		local distance = trace.StartPos:Distance(trace.HitPos)

		local range = math.Round(distance * meters)

		if range > 999 or trace.HitSky or not trace.Hit then
			range = "---"
		else
			range = string.format("%.3i", range)
		end

		local fuse = self:GetFuseDistance()
		local tgt = "---"

		if fuse > 0 then
			tgt = string.format("%.3i", math.Round(fuse * meters))

			local ang = self:GetAngleOfAttack()

			local forward = Angle(ang, EyeAngles().y, 0):Forward() * 10
			local screen = (EyePos() + forward):ToScreen()

			local height = 14

			draw.DrawText("<>", "xm25_lcd", centerX, screen.y - height, color, TEXT_ALIGN_CENTER)
		end

		draw.DrawText("TGT: " .. tgt, "xm25_lcd", centerX + offset, centerY + offset, color)
		draw.DrawText("RNG: " .. range, "xm25_lcd", centerX + offset, centerY + offset * 2, color)
	end

	function SWEP:DrawWorldModel()
		local ply = self:GetOwner()

		self:SetRenderOrigin(nil)
		self:SetRenderAngles(nil)

		if IsValid(ply) then
			ply:SetupBones()

			local bone = ply:LookupBone("ValveBiped.Bip01_R_Hand")

			if not bone then
				return
			end

			local matrix = ply:GetBoneMatrix(bone)

			if not matrix then
				return
			end

			local pos, ang = LocalToWorld(Vector(14, -1, -6), Angle(0, 90, 190), matrix:GetTranslation(), matrix:GetAngles())

			self:SetRenderOrigin(pos)
			self:SetRenderAngles(ang)
		end

		self:DrawModel()
	end
end

sound.Add({
	name = "Simple_XM25.Single",
	channel = CHAN_WEAPON,
	volume = 0.35,
	level = 140,
	pitch = {95, 110},
	sound = "simple_weapons/weapons/xm25/fire.wav"
})

sound.Add({
	name = "Simple_XM25.Draw",
	channel = CHAN_AUTO,
	volume = 0.35,
	level = 75,
	sound = "simple_weapons/weapons/xm25/draw.wav"
})

sound.Add({
	name = "Simple_XM25.Reload1",
	channel = CHAN_AUTO,
	volume = 0.35,
	level = 75,
	sound = "simple_weapons/weapons/xm25/lift.wav"
})

sound.Add({
	name = "Simple_XM25.Reload2",
	channel = CHAN_AUTO,
	volume = 0.35,
	level = 75,
	sound = "simple_weapons/weapons/xm25/magout.wav"
})

sound.Add({
	name = "Simple_XM25.Reload3",
	channel = CHAN_AUTO,
	volume = 0.35,
	level = 75,
	sound = "simple_weapons/weapons/xm25/magin.wav"
})

sound.Add({
	name = "Simple_XM25.Reload4",
	channel = CHAN_AUTO,
	volume = 0.35,
	level = 75,
	sound = "simple_weapons/weapons/xm25/hit.wav"
})

sound.Add({
	name = "Simple_XM25.Reload5",
	channel = CHAN_AUTO,
	volume = 0.35,
	level = 75,
	sound = "simple_weapons/weapons/xm25/bolt.wav"
})
