AddCSLuaFile()

ENT.Base = "base_anim"
ENT.Type = "anim"

local vcIgnorePVS = CreateConVar( "sv_npcvoicechat_ignorepvs", "1", ( FCVAR_ARCHIVE + FCVAR_REPLICATED ), "If NPCs that are currently not processed in the client realm should still be able to use the voice chat.", 0, 1 )
local vcPVSNoIdle = CreateConVar( "sv_npcvoicechat_ignorepvs_noidle", "1", ( FCVAR_ARCHIVE + FCVAR_REPLICATED ), "If enabled, the 'Ignore PVS' setting will not affect idle voicelines.", 0, 1 )

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
        NPCVC.TalkingNPCs[ self ] = true

        local owner = self:GetOwner()
        if IsValid( owner ) then
            self:SetSoundSource( owner )
            self:SetRemoveOnNoSource( !self.DontRemoveEntity )

            local mins, maxs = owner:GetCollisionBounds()
            self:SetCollisionBounds( mins, maxs )
        end
    end

    function ENT:UpdateTransmitState()
        return ( ( vcIgnorePVS:GetBool() and ( self.VoiceType != "idle" or !vcPVSNoIdle:GetBool() ) ) and TRANSMIT_ALWAYS or TRANSMIT_PVS )
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
        NPCVC.TalkingNPCs[ self ] = nil
    end

end