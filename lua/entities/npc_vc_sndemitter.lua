AddCSLuaFile()

ENT.Base = "base_anim"
ENT.Type = "anim"

function ENT:SetupDataTables()
	self:NetworkVar( "Entity", 0, "SoundSource" )
	
    self:NetworkVar( "Bool", 0, "RemoveOnNoSource" )
end

if ( SERVER ) then

    local IsValid = IsValid
    local CurTime = CurTime

    function ENT:Initialize()
        self:SetRenderMode( RENDERMODE_NONE )
        self:DrawShadow( false )
        self:SetNotSolid( false )
        self:SetMoveType( MOVETYPE_FLYGRAVITY )
        self.SpeechPlayTime = ( RealTime() + 5 )

        local owner = self:GetOwner()
        if IsValid( owner ) then
            self:SetSoundSource( owner )
            self:SetRemoveOnNoSource( !self.DontRemoveEntity )

            local mins, maxs = owner:GetCollisionBounds()
            self:SetCollisionBounds( mins, maxs )
        end
    end

    function ENT:Think()
        if RealTime() > self.SpeechPlayTime then self:Remove() return end

        local srcEnt = self:GetSoundSource()
        if srcEnt != self and IsValid( srcEnt ) then 
            self:SetPos( srcEnt:GetPos() )
        end

        self:NextThink( CurTime() + 0.1 )
        return true
    end

end