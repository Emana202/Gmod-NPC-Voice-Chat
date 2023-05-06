AddCSLuaFile()

ENT.Base = "base_anim"
ENT.Type = "anim"

function ENT:SetupDataTables()
	self:NetworkVar( "Entity", 0, "SoundSource" )
    self:NetworkVar( "Bool", 0, "RemoveOnNoSource" )

    -- Deranged idea that came into my head
    if ( SERVER ) then
        self:NetworkVarNotify( "SoundSource", function( self, name, old, new )
            if old == new then return end
            self:SetNW2Entity( "npcsqueakers_soundsrc", new )
        end )
    end
end

if ( SERVER ) then

    local IsValid = IsValid
    local CurTime = CurTime
    local RealTime = RealTime
    local max = math.max

    function ENT:Initialize()
        self:SetRenderMode( RENDERMODE_NONE )
        self:DrawShadow( false )
        self:SetNotSolid( false )
        self:SetMoveType( MOVETYPE_FLYGRAVITY )

        self.SpeechPlayTime = ( RealTime() + 5 )
        NPCVC_TalkingNPCs[ self ] = true

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
        if IsValid( srcEnt ) then 
            self:SetPos( srcEnt:GetPos() )
        elseif self:GetRemoveOnNoSource() then
            self:Remove()
            return
        end

        self:NextThink( CurTime() + 0.1 )
        return true
    end

    function ENT:OnRemove()
        NPCVC_TalkingNPCs[ self ] = nil
    end

end