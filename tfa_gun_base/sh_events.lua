local sp = game.SinglePlayer()
local l_CT = CurTime
SWEP.EventTimer = -1

--[[
Function Name:  ResetEvents
Syntax: self:ResetEvents()
Returns:  Nothing.
Purpose:  Cleans up events table.
]]--
function SWEP:ResetEvents()
	if not self:OwnerIsValid() then return end

	if sp and not CLIENT then
		self:CallOnClient("ResetEvents", "")
	end

	if IsFirstTimePredicted() or game.SinglePlayer() then
		self.EventTimer = l_CT()
		for k, v in pairs(self.EventTable) do
			for l, b in pairs(v) do
				b.called = false
			end
		end
	end
end

--[[
Function Name:  ProcessEvents
Syntax: self:ProcessEvents( ).
Returns:  Nothing.
Notes: Critical for the event table to function.
Purpose:  Main SWEP function
]]--

function SWEP:ProcessEvents()
	if not self:VMIV() then return end
	if self.EventTimer < 0 then
		self:ResetEvents()
	end
	if sp then
		self.LastAct = self:GetLastActivity()
	end
	local evtbl = self.EventTable[ self.LastAct or self:GetLastActivity() ]

	if not evtbl then return end
	for k, v in pairs(evtbl) do
		if v.called or l_CT() < self.EventTimer + v.time * self:GetAnimationRate( self.LastAct or self:GetLastActivity() ) then continue end
		v.called = true

		if v.client == nil then
			v.client = true
		end

		if v.type == "lua" then
			if v.server == nil then
				v.server = true
			end

			if (v.client and CLIENT and (not v.client_predictedonly or self:GetOwner() == LocalPlayer())) or (v.server and SERVER) and v.value then
				v.value(self, self.OwnerViewModel)
			end
		elseif v.type == "snd" or v.type == "sound" then
			if v.server == nil then
				v.server = false
			end

			if SERVER then
				if v.client then
					net.Start("tfaSoundEvent")
					net.WriteEntity(self)
					net.WriteString(v.value or "")

					if sp then
						net.Broadcast()
					else
						net.SendOmit(self:GetOwner())
					end
				elseif v.server and v.value and v.value ~= "" then
					self:EmitSound(v.value)
				end
			elseif v.client and self:GetOwner() == LocalPlayer() and ( not sp ) and v.value and v.value ~= "" then
				if v.time <= 0.01 then
					self:EmitSoundSafe(v.value)
				else
					self:EmitSound(v.value)
				end
			end
		end
	end
end

function SWEP:EmitSoundSafe(snd)
	timer.Simple(0,function()
		if IsValid(self) and snd then self:EmitSound(snd) end
	end)
end