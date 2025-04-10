local net = net
local ipairs = ipairs
local pairs = pairs
local RandomPairs = RandomPairs
local IsValid = IsValid
local isentity = isentity
local SimpleTimer = timer.Simple
local CreateTimer = timer.Create
local RemoveTimer = timer.Remove
local random = math.random
local randomseed = math.randomseed
local string_sub = string.sub
local string_find = string.find
local string_Explode = string.Explode
local Clamp = math.Clamp
local min = math.min
local abs = math.abs
local table_Empty = table.Empty
local table_Merge = table.Merge
local cvarFlag = ( FCVAR_ARCHIVE + FCVAR_REPLICATED )
local RealTime = RealTime
local os_time = os.time
local Rand = math.Rand
local band = bit.band
local PointContents = util.PointContents
local TraceLine = util.TraceLine
local IsValidProp = util.IsValidProp
local ents_GetAll = ents.GetAll
local FindByClass = ents.FindByClass
local GetHumans = player.GetHumans
local CurTime = CurTime
local Material = Material
local Color = Color
local GetScheduleID = ai.GetScheduleID
local GetLoudestSoundHint = sound.GetLoudestSoundHint
local ents_Create = ents.Create
local table_GetKeys = table.GetKeys
local table_insert = table.insert
local table_Copy = table.Copy
local table_Count = table.Count
local table_RemoveByValue = table.RemoveByValue
local FindInSphere = ents.FindInSphere
local IsSinglePlayer = game.SinglePlayer
local IsBasedOn = scripted_ents.IsBasedOn
local StoreEntityModifier = duplicator.StoreEntityModifier
local file_Exists = file.Exists
local file_Read = file.Read
local file_Write = file.Write
local file_Find = file.Find
local file_Delete = file.Delete
local JSONToTable = util.JSONToTable
local TableToJSON = util.TableToJSON
local string_StartsWith = string.StartsWith
local FindByModel = ents.FindByModel

local waterCheckTr = {}
local nextNPCSoundThink = 0
local aiDisabled = GetConVar( "ai_disabled" )
local ignorePlys = GetConVar( "ai_ignoreplayers" )

--

util.AddNetworkString( "npcsqueakers_playsound" )
util.AddNetworkString( "npcsqueakers_sndduration" )
util.AddNetworkString( "npcsqueakers_updatespawnmenu" )
util.AddNetworkString( "npcsqueakers_resetsettings" )
util.AddNetworkString( "npcsqueakers_writedata" )
util.AddNetworkString( "npcsqueakers_requestdata" )
util.AddNetworkString( "npcsqueakers_returndata" )
util.AddNetworkString( "npcsqueakers_getrenderbounds" )
util.AddNetworkString( "npcsqueakers_sendrenderbounds" )

--

NPCVC                   = NPCVC or {}
NPCVC.NickNames         = NPCVC.NickNames or {}
NPCVC.VoiceLines        = NPCVC.VoiceLines or {}
NPCVC.ProfilePictures   = NPCVC.ProfilePictures or {}
NPCVC.UserPFPs          = NPCVC.UserPFPs or {}
NPCVC.VoiceProfiles     = NPCVC.VoiceProfiles or {}
NPCVC.NPCVoiceProfiles  = NPCVC.NPCVoiceProfiles or {}
NPCVC.NPCBlacklist      = NPCVC.NPCBlacklist or {}
NPCVC.NPCWhitelist      = NPCVC.NPCWhitelist or {}
NPCVC.TalkingNPCs       = NPCVC.TalkingNPCs or {}
NPCVC.MapTransitionNPCs = NPCVC.MapTransitionNPCs or nil
NPCVC.CachedNPCPfps     = {}
NPCVC.LastUsedLines     = NPCVC.LastUsedLines or {}

file.CreateDir( "npcvoicechat" )

local vcEnabled                 = CreateConVar( "sv_npcvoicechat_enabled", "1", cvarFlag, "Allows to NPCs and nextbots to able to speak voicechat-like using voicelines", 0, 1 )
local vcAllowNPCs               = CreateConVar( "sv_npcvoicechat_allownpc", "1", cvarFlag, "If standard NPCs or the ones that are based on them like ANP are allowed to use voicechat", 0, 1 )
local vcAllowProps              = CreateConVar( "sv_npcvoicechat_allowprops", "0", cvarFlag, "If physics props should gain a voice chat", 0, 1 )
local vcAllowVJBase             = CreateConVar( "sv_npcvoicechat_allowvjbase", "1", cvarFlag, "If VJ Base SNPCs are allowed to use voicechat", 0, 1 )
local vcAllowDrGBase            = CreateConVar( "sv_npcvoicechat_allowdrgbase", "1", cvarFlag, "If DrGBase nextbots are allowed to use voicechat", 0, 1 )
local vcAllowSanics             = CreateConVar( "sv_npcvoicechat_allowsanic", "1", cvarFlag, "If 2D nextbots like Sanic or Obunga are allowed to use voicechat", 0, 1 )
local vcAllowSBNextbots         = CreateConVar( "sv_npcvoicechat_allowsbnextbots", "1", cvarFlag, "If SB Advanced Nextbots like the Terminator are allowed to use voicechat", 0, 1 )
local vcAllowTF2Bots            = CreateConVar( "sv_npcvoicechat_allowtf2bots", "1", cvarFlag, "If bots from Team Fortress 2 are allowed to use voicechat", 0, 1 )
local vcAllowGMDoom             = CreateConVar( "sv_npcvoicechat_allowgmdoom", "1", cvarFlag, "If NPCs from the GMDoom addon are allowed to use voicechat", 0, 1 )
local vcUseModelIcon            = CreateConVar( "sv_npcvoicechat_usemodelicons", "0", cvarFlag, "If NPC's profile pictures should first check for their model's spawnmenu icon to use as a one instead of the entity icon", 0, 1 )
local vcUseCustomPfps           = CreateConVar( "sv_npcvoicechat_usecustompfps", "0", cvarFlag, "If NPCs are allowed to use custom profile pictures instead of their spawnmenu icons", 0, 1 )
local vcUserPfpsOnly            = CreateConVar( "sv_npcvoicechat_userpfpsonly", "0", cvarFlag, "If NPCs are only allowed to use profile pictures that are placed by players", 0, 1 )
local vcIgnoreGagged            = CreateConVar( "sv_npcvoicechat_ignoregaggednpcs", "0", cvarFlag, "If NPCs that are gagged by the map or other means aren't allowed to play voicelines until ungagged", 0, 1 )
local vcSlightDelay             = CreateConVar( "sv_npcvoicechat_slightdelay", "1", cvarFlag, "If there should be a slight delay before NPC plays its voiceline to simulate its reaction time", 0, 1 )
local vcUseRealNames            = CreateConVar( "sv_npcvoicechat_userealnames", "1", cvarFlag, "If NPCs should use their actual names instead of picking random nicknames", 0, 1 )
local vcKillfeedNick            = CreateConVar( "sv_npcvoicechat_killfeednicks", "1", cvarFlag, "If NPC's killfeed name should be their voicechat nickname", 0, 1 )
local vcPitchMin                = CreateConVar( "sv_npcvoicechat_initvoicepitch_min", "85", cvarFlag, "The highest pitch a NPC's voice can get upon spawning", 0, 255 )
local vcPitchMax                = CreateConVar( "sv_npcvoicechat_initvoicepitch_max", "120", cvarFlag, "The lowest pitch a NPC's voice can get upon spawning", 0, 255 )
local vcHighPitchSmallNPCs      = CreateConVar( "sv_npcvoicechat_higherpitchforsmallnpcs", "0", cvarFlag, "If NPCs with smaller sizes should have a higher voice pitch", 0, 1 )
local vcCensorLines             = CreateConVar( "sv_npcvoicechat_censorcertainlines", "0", cvarFlag, "If enabled, makes certain offensive voicelines to not play", 0, 1 )
local vcSpeakLimit              = CreateConVar( "sv_npcvoicechat_speaklimit", "0", cvarFlag, "Controls the amount of NPCs that can use voicechat at once. Set to zero to disable", 0 )
local vcLimitAffectsDeath       = CreateConVar( "sv_npcvoicechat_speaklimit_dontaffectdeath", "1", cvarFlag, "If the speak limit shouldn't affect NPCs that are playing their death voiceline", 0, 1 )
local vcMinSpeechChance         = CreateConVar( "sv_npcvoicechat_minimumspeechchance", "15", cvarFlag, "The minimum value the NPC's random speech chance should be when spawning", 0, 100 )
local vcMaxSpeechChance         = CreateConVar( "sv_npcvoicechat_maximumspeechchance", "100", cvarFlag, "The maximum value the NPC's random speech chance should be when spawning", 0, 100 )
local vcVoiceChanceAffectDeath  = CreateConVar( "sv_npcvoicechat_speechchanceaffectsdeath", "1", cvarFlag, "If NPC's speech chance should also affect its playing of death voicelines", 0, 1 )
local vcSaveNPCDataOnMapChange  = CreateConVar( "sv_npcvoicechat_savenpcdataonmapchange", "0", cvarFlag, "If essential NPCs from Half-Life campaigns should save their voicechat data. This will for example prevent them from having a different name when appearing after map change and etc.", 0, 1 )
local vcUseSoundHintsForDangers = CreateConVar( "sv_npcvoicechat_usesoundhintsforspottingdanger", "1", cvarFlag, "If enabled, NPCs will use the sound hint system to detect dangers. Ex. This will allow for all NPCs to panic on being near a grenade and etc.", 0, 1 )

local vcUseLambdaVoicelines     = CreateConVar( "sv_npcvoicechat_uselambdavoicelines", "0", cvarFlag, "If NPCs should use voicelines from Lambda Players and its addons + modules instead" )
local vcUseLambdaPfpPics        = CreateConVar( "sv_npcvoicechat_uselambdapfppics", "0", cvarFlag, "If NPCs should use profile pictures from Lambda Players and its addons + modules instead" )
local vcUseLambdaNicknames      = CreateConVar( "sv_npcvoicechat_uselambdanames", "0", cvarFlag, "If NPCs should use nicknames from Lambda Players and its addons + modules instead" )
local vcVoiceProfile            = CreateConVar( "sv_npcvoicechat_spawnvoiceprofile", "", cvarFlag, "The Voice Profile the newly created NPC should be spawned with. Note: This will override every player's client option with this one" )
local vcVoiceProfileChance      = CreateConVar( "sv_npcvoicechat_randomvoiceprofilechance", "5", cvarFlag, "The chance the a NPC will use a random available Voice Profile as their voice profile after they spawn" )
local vcVoiceProfileFallback    = CreateConVar( "sv_npcvoicechat_voiceprofilefallbacks", "0", cvarFlag, "If NPC with a voice profile should fallback to default voicelines if its profile doesn't have a specified voice type in it" )

local vcAllowLines_Idle         = CreateConVar( "sv_npcvoicechat_allowlines_idle", "1", cvarFlag, "If NPCs are allowed to play voicelines  while they are not in-combat", 0, 1 )
local vcAllowLines_CombatIdle   = CreateConVar( "sv_npcvoicechat_allowlines_combatidle", "1", cvarFlag, "If NPCs are allowed to play voicelines while they are in-combat", 0, 1 )
local vcAllowLines_Death        = CreateConVar( "sv_npcvoicechat_allowlines_death", "1", cvarFlag, "If NPCs are allowed to play voicelines when they get killed", 0, 1 )
local vcAllowLines_SpotEnemy    = CreateConVar( "sv_npcvoicechat_allowlines_spotenemy", "1", cvarFlag, "If NPCs are allowed to play voicelines when they first spot their enemy", 0, 1 )
local vcAllowLines_KillEnemy    = CreateConVar( "sv_npcvoicechat_allowlines_killenemy", "1", cvarFlag, "If NPCs are allowed to play voicelines when kill their enemy", 0, 1 )
local vcAllowLines_WitnessDeath = CreateConVar( "sv_npcvoicechat_allowlines_witnessdeath", "1", cvarFlag, "If NPCs are allowed to play voicelines when they witness someone getting killed", 0, 1 )
local vcAllowLines_Assist       = CreateConVar( "sv_npcvoicechat_allowlines_assist", "1", cvarFlag, "If NPCs are allowed to play voicelines when they get assisted by someone in some way, like one of their allies kills their enemy", 0, 1 )
local vcAllowLines_SpotDanger   = CreateConVar( "sv_npcvoicechat_allowlines_spotdanger", "1", cvarFlag, "If NPCs are allowed to play voicelines when they spot a danger like grenade and etc.", 0, 1 )
local vcAllowLines_PanicCond    = CreateConVar( "sv_npcvoicechat_allowlines_panicconds", "1", cvarFlag, "If NPCs are allowed to play voicelines when they're currently in some panic inducing condition, like being on fire or being held by player's gravity gun.", 0, 1 )
local vcAllowLines_LowHealth    = CreateConVar( "sv_npcvoicechat_allowlines_lowhealth", "1", cvarFlag, "If NPCs are allowed to play voicelines when they are low on health.", 0, 1 )

local defVoiceTypeDirs = {
    [ "idle" ]      = "npcvoicechat/vo/idle",
    [ "witness" ]   = "npcvoicechat/vo/witness",
    [ "death" ]     = "npcvoicechat/vo/death",
    [ "panic" ]     = "npcvoicechat/vo/panic",
    [ "taunt" ]     = "npcvoicechat/vo/taunt",
    [ "kill" ]      = "npcvoicechat/vo/kill",
    [ "laugh" ]     = "npcvoicechat/vo/laugh",
    [ "assist" ]    = "npcvoicechat/vo/assist",
    [ "fall" ]      = "npcvoicechat/vo/fall"
}
local vcVoiceTypeDirs = {
    [ "idle" ]      = CreateConVar( "sv_npcvoicechat_snddir_idle", defVoiceTypeDirs[ "idle" ], cvarFlag, "" ),
    [ "death" ]     = CreateConVar( "sv_npcvoicechat_snddir_death", defVoiceTypeDirs[ "death" ], cvarFlag, "" ),
    [ "taunt" ]     = CreateConVar( "sv_npcvoicechat_snddir_taunt", defVoiceTypeDirs[ "taunt" ], cvarFlag, "" ),
    [ "witness" ]   = CreateConVar( "sv_npcvoicechat_snddir_witness", defVoiceTypeDirs[ "witness" ], cvarFlag, "" ),
    [ "laugh" ]     = CreateConVar( "sv_npcvoicechat_snddir_laugh", defVoiceTypeDirs[ "laugh" ], cvarFlag, "" ),
    [ "assist" ]    = CreateConVar( "sv_npcvoicechat_snddir_assist", defVoiceTypeDirs[ "assist" ], cvarFlag, "" ),
    [ "panic" ]     = CreateConVar( "sv_npcvoicechat_snddir_panic", defVoiceTypeDirs[ "panic" ], cvarFlag, "" ),
    [ "kill" ]      = CreateConVar( "sv_npcvoicechat_snddir_kill", defVoiceTypeDirs[ "kill" ], cvarFlag, "" )
}

local function AddVoiceProfile( path )
    local _, voicePfpDirs = file_Find( "sound/" .. path .. "/*", "GAME", "nameasc" )
    if !voicePfpDirs then return end
    
    for _, voicePfp in ipairs( voicePfpDirs ) do
        for voiceType, _ in pairs( defVoiceTypeDirs ) do 
            local voiceTypePath = path .. "/" .. voicePfp .. "/" .. voiceType
            local voicelines = file_Find( "sound/" .. voiceTypePath .. "/*", "GAME", "nameasc" )
            if !voicelines or #voicelines == 0 then continue end

            local typeName = voiceType
            if voiceType == "fall" then typeName = "panic" end

            NPCVC.VoiceProfiles[ voicePfp ] = ( NPCVC.VoiceProfiles[ voicePfp ] or {} )
            NPCVC.VoiceProfiles[ voicePfp ][ typeName ] = ( NPCVC.VoiceProfiles[ voicePfp ][ typeName ] or {} )

            for _, voiceline in ipairs( voicelines ) do
                table_insert( NPCVC.VoiceProfiles[ voicePfp ][ typeName ], voiceTypePath .. "/" .. voiceline )
            end
        end
    end
end

local function UpdateData( ply )
    if isentity( ply ) and IsValid( ply ) and !ply:IsSuperAdmin() then return end

    local names = file_Read( "npcvoicechat/names.json", "DATA" )
    if !names then
        NPCVC.NickNames = NPCVC.DefaultNickNames
        file_Write( "npcvoicechat/names.json", TableToJSON( NPCVC.DefaultNickNames ) )
    else
        NPCVC.NickNames = JSONToTable( names )
    end

    local npcVPs = file_Read( "npcvoicechat/classvps.json", "DATA" )
    if !npcVPs then
        table_Empty( NPCVC.NPCVoiceProfiles )
        file_Write( "npcvoicechat/classvps.json", TableToJSON( NPCVC.NPCVoiceProfiles ) )
    else
        NPCVC.NPCVoiceProfiles = JSONToTable( npcVPs )
    end

    local npcBlacklist = file_Read( "npcvoicechat/npcblacklist.json", "DATA" )
    if !npcBlacklist then
        table_Empty( NPCVC.NPCBlacklist )
        file_Write( "npcvoicechat/npcblacklist.json", TableToJSON( NPCVC.NPCBlacklist ) )
    else
        NPCVC.NPCBlacklist = JSONToTable( npcBlacklist )
    end

    local npcWhitelist = file_Read( "npcvoicechat/npcwhitelist.json", "DATA" )
    if !npcWhitelist then
        table_Empty( NPCVC.NPCWhitelist )
        file_Write( "npcvoicechat/npcwhitelist.json", TableToJSON( NPCVC.NPCWhitelist ) )
    else
        NPCVC.NPCWhitelist = JSONToTable( npcWhitelist )
    end

    table_Empty( NPCVC.VoiceLines )
    for voiceType, voiceDir in pairs( vcVoiceTypeDirs ) do
        local sndDir = voiceDir:GetString() .. "/"
        local snds = file_Find( "sound/" .. sndDir .. "*", "GAME", "nameasc" )
        if !snds or #snds == 0 then continue end

        local lineTbl = {}
        for _, snd in ipairs( snds ) do lineTbl[ #lineTbl + 1 ] = sndDir .. snd end
        NPCVC.VoiceLines[ voiceType ] = lineTbl
    end

    table_Empty( NPCVC.ProfilePictures )
    local pfpPics = file_Find( "materials/npcvcdata/profilepics/*", "GAME", "nameasc" )
    if pfpPics and #pfpPics > 0 then
        for _, pfpPic in ipairs( pfpPics ) do
            NPCVC.ProfilePictures[ #NPCVC.ProfilePictures + 1 ] = "npcvcdata/profilepics/" .. pfpPic
        end
    end

    table_Empty( NPCVC.UserPFPs )
    pfpPics = file_Find( "materials/npcvcdata/custompfps/*", "GAME", "nameasc" )
    if pfpPics and #pfpPics > 0 then
        for _, pfpPic in ipairs( pfpPics ) do
            NPCVC.UserPFPs[ #NPCVC.UserPFPs + 1 ] = "npcvcdata/custompfps/" .. pfpPic
        end
    end

    table_Empty( NPCVC.VoiceProfiles )
    AddVoiceProfile( "npcvoicechat/voiceprofiles" )
    AddVoiceProfile( "lambdaplayers/voiceprofiles" )
    AddVoiceProfile( "zetaplayer/custom_vo" )

    table_Empty( NPCVC.CachedNPCPfps )

    net.Start( "npcsqueakers_updatespawnmenu" )
    net.Broadcast()
end

concommand.Add( "sv_npcvoicechat_updatedata", UpdateData, nil, "Updates and refreshes the nicknames, voicelines and other data required for NPC's proper voice chatting" )

net.Receive( "npcsqueakers_sndduration", function()
    local ent = net.ReadEntity()
    if IsValid( ent ) then ent.SpeechPlayTime = ( RealTime() + net.ReadFloat() ) end
end )

net.Receive( "npcsqueakers_resetsettings", function()
    local cvarCount = net.ReadUInt( 8 )
    for i = 1, cvarCount do
        local cvarName = net.ReadString()
        local convar = GetConVar( cvarName )
        convar:SetString( convar:GetDefault() )
    end
    UpdateData()
end )

net.Receive( "npcsqueakers_requestdata", function( len, ply )
    local content = file_Read( "npcvoicechat/" .. net.ReadString(), "DATA" )
    if !content then return end

    net.Start( "npcsqueakers_returndata" )
        net.WriteString( content )
    net.Send( ply )
end )

net.Receive( "npcsqueakers_writedata", function()
    local data = net.ReadString()
    if data then file_Write( "npcvoicechat/" .. net.ReadString(), data ) end
end )

local function SetNPCVoiceChatData( ply, npc, data, noDupe )
    npc.NPCVC_IsDuplicated = ( noDupe == nil and true or noDupe )
    npc.NPCVC_SpeechChance = data.SpeechChance
    npc.NPCVC_VoicePitch = data.VoicePitch
    npc.NPCVC_Nickname = data.NickName
    npc.NPCVC_UsesRealName = data.UsesRealName
    npc.NPCVC_ProfilePicture = data.ProfilePicture
    npc.NPCVC_VoiceProfile = data.VoiceProfile
    npc.NPCVC_StoredData = data
end
duplicator.RegisterEntityModifier( "NPC VoiceChat - NPC's Voice Data", SetNPCVoiceChatData )

local nextbotMETA = FindMetaTable( "NextBot" )
NPCVC.OldFunc_BecomeRagdoll = NPCVC.OldFunc_BecomeRagdoll or nextbotMETA.BecomeRagdoll

function nextbotMETA:BecomeRagdoll( dmginfo )
    local ragdoll = NPCVC.OldFunc_BecomeRagdoll( self, dmginfo )
    if self.IsDrGNextbot and self.NPCVC_Initialized and IsValid( ragdoll ) then
        local failTime = ( CurTime() + 1 )
        local timerName = "npcsqueakers_fuckyounextbots" .. self:EntIndex()
    
        CreateTimer( timerName, 0, 0, function()
            if !IsValid( self ) or !IsValid( ragdoll ) or CurTime() >= failTime then RemoveTimer( timerName ) return end  
    
            local sndEmitter = self:GetNW2Entity( "npcsqueakers_sndemitter" )
            if !IsValid( sndEmitter ) then return end
    
            sndEmitter:SetSoundSource( ragdoll )
            RemoveTimer( timerName )
        end )
    end
    return ragdoll
end

--

local callCount = 0
local function GetVoiceLine( ent, voiceType )
    local voiceTbl
    local voicePfp = NPCVC.VoiceProfiles[ ent.NPCVC_VoiceProfile ]
    if voicePfp then voiceTbl = voicePfp[ voiceType ] end

    if !voicePfp or ( !voiceTbl or #voiceTbl == 0 ) and vcVoiceProfileFallback:GetBool() then
        local voicelineTbl = ( ( LambdaVoiceLinesTable and vcUseLambdaVoicelines:GetBool() ) and LambdaVoiceLinesTable or NPCVC.VoiceLines ) 
        voiceTbl = voicelineTbl[ voiceType ]
    end
    if !voiceTbl or #voiceTbl == 0 then return end

    local realTime = CurTime()
    callCount = ( callCount + 1 )
    randomseed( ent:EntIndex() + ent:GetCreationID() + os_time() + realTime + callCount )

    local censorship = vcCensorLines:GetBool()
    for _, voiceLine in RandomPairs( voiceTbl ) do
        local pathTbl = string_Explode( "/", voiceLine, false )
        local voiceFile = pathTbl[ #pathTbl ]
        
        if censorship and NPCVC.CensoredLines[ voiceFile ] then
            -- print( voiceFile )
            continue
        end

        local useTime = NPCVC.LastUsedLines[ voiceFile ]
        if useTime then
            if realTime < useTime then continue end
            NPCVC.LastUsedLines[ voiceFile ] = nil
        else
            NPCVC.LastUsedLines[ voiceFile ] = ( realTime + 1800 )
        end

        return voiceLine
    end
    return voiceTbl[ random( #voiceTbl ) ]
end

local ignoreGagTypes = {
    [ "death" ] = true,
    [ "panic" ] = true,
    [ "laugh" ] = true,
    [ "witness" ] = true
}
function NPCVC:PlayVoiceLine( npc, voiceType, dontDeleteOnRemove, isInput )
    if !npc.NPCVC_Initialized or npc.NPCVC_IsKilled and voiceType != "death" then return end
    if voiceType != "laugh" and NPCVC:IsCurrentlySpeaking( npc, "laugh" ) then return end
    if npc.l_TranqGun_IsTranquilized and voiceType != "death" then return end
    if npc.LastPathingInfraction and !vcAllowSanics:GetBool() then return end
    if npc.SBAdvancedNextBot and !vcAllowSBNextbots:GetBool() then return end
    if npc.MNG_TF2Bot and !vcAllowTF2Bots:GetBool() then return end
    if npc.IsDoomNPC and !vcAllowGMDoom:GetBool() then return end
    if npc.IsDrGNextbot and ( npc:IsPossessed() or !vcAllowDrGBase:GetBool() ) then return end
    if npc.IsVJBaseSNPC then
        if npc.VJ_IsBeingControlled or npc:GetState() != 0 or !vcAllowVJBase:GetBool() then return end
    elseif npc:IsNPC() and !vcAllowNPCs:GetBool() then 
        return 
    end
    if !ignoreGagTypes[ voiceType ] and vcIgnoreGagged:GetBool() and npc:HasSpawnFlags( SF_NPC_GAG ) then return end

    local class = npc:GetClass()
    if NPCVC.NPCBlacklist[ class ] then return end

    local oldEmitter = npc:GetNW2Entity( "npcsqueakers_sndemitter" )
    if !NPCVC.TalkingNPCs[ oldEmitter ] and ( voiceType != "death" or !vcLimitAffectsDeath:GetBool() ) then
        local speakLimit = vcSpeakLimit:GetInt()
        if speakLimit > 0 and table_Count( NPCVC.TalkingNPCs ) >= speakLimit then return end
    end

    local sndName = defVoiceTypeDirs[ voiceType ]
    if sndName then 
        sndName = GetVoiceLine( npc, voiceType ) 
        if !sndName then return end
    else
        sndName = voiceType
    end

    local sndEmitter = ents_Create( "npc_vc_sndemitter" )
    if !IsValid( sndEmitter ) then return end

    sndEmitter:SetPos( npc:EyePos() )
    sndEmitter:SetOwner( npc )
    sndEmitter.DontRemoveEntity = dontDeleteOnRemove
    sndEmitter.VoiceType = voiceType
    sndEmitter:Spawn()

    local enemyPlyData = npc.NPCVC_EnemyPlayers
    for _, ply in ipairs( GetHumans() ) do
        if NPCVC:GetDispositionOfNPC( npc, ply ) != D_HT then continue end
        enemyPlyData[ ply ] = true
    end

    local addPlayOrig = npc.NPCVC_AdditionalPlay
    if addPlayOrig then 
        local origin = addPlayOrig.Pos
        if istable( origin ) then
            for k, v in ipairs( origin ) do
                if !isstring( v ) then continue end
                origin[ k ] = ents.FindByName( v )[ 1 ]
            end
        elseif isstring( origin ) then
            addPlayOrig.Pos = ents.FindByName( origin )[ 1 ]
        end
    end

    local vcData = {
        Emitter = sndEmitter,
        EntIndex = npc:GetCreationID(),
        Pitch = npc.NPCVC_VoicePitch,
        IconHeight = npc.NPCVC_VoiceIconHeight,
        VolumeMult = npc.NPCVC_VoiceVolumeScale,
        Nickname = npc.NPCVC_Nickname,
        UsesRealName = npc.NPCVC_UsesRealName,
        ProfilePicture = npc.NPCVC_ProfilePicture,
        EnemyPlayers = enemyPlyData,
        StartPos = npc:GetPos(),
        IsDormant = npc:IsDormant(),
        Classname = class,
        AddPlayOrigin = addPlayOrig
    }

    local delayT = 0
    if vcSlightDelay:GetBool() then
        delayT = Rand( 0, 0.75 )
    end

    SimpleTimer( ( ( IsSinglePlayer() and isInput != true ) and 0 or 0.1 ), function()
        net.Start( "npcsqueakers_playsound" )
            net.WriteString( sndName )
            net.WriteTable( vcData )
            net.WriteFloat( delayT )
        net.Broadcast()
    end )
    if IsValid( oldEmitter ) then oldEmitter:Remove() end

    npc.NPCVC_LastVoiceLine = voiceType
    npc:SetNW2Entity( "npcsqueakers_sndemitter", sndEmitter )
end

function NPCVC:StopCurrentSpeech( npc, voiceType )
    if voiceType and npc.NPCVC_LastVoiceLine != voiceType then return end
    local sndEmitter = npc:GetNW2Entity( "npcsqueakers_sndemitter" )
    if !IsValid( sndEmitter ) then return end
    sndEmitter:Remove()
    sndEmitter.SpeechPlayTime = 0
end

function NPCVC:IsCurrentlySpeaking( npc, ... )
    local args = { ... }
    if #args != 0 then
        local lastType = npc.NPCVC_LastVoiceLine
        local isSpeaking = false
        for _, voiceType in ipairs( args ) do
            if lastType != voiceType then continue end
            isSpeaking = true; break
        end
        if !isSpeaking then return false end
    end
    local sndEmitter = npc:GetNW2Entity( "npcsqueakers_sndemitter" )
    return ( IsValid( sndEmitter ) and RealTime() <= sndEmitter.SpeechPlayTime )
end

local function GetAvailableNickname()
    local nameListTbl = ( ( LambdaPlayerNames and vcUseLambdaNicknames:GetBool() ) and LambdaPlayerNames or NPCVC.NickNames )

    local nameListCopy = table_Copy( nameListTbl )
    for _, v in ipairs( ents_GetAll() ) do
        if !IsValid( v ) or !v.NPCVC_Initialized and !v.IsLambdaPlayer then continue end
        table_RemoveByValue( nameListCopy, ( v.IsLambdaPlayer and v:GetLambdaName() or v.NPCVC_Nickname ) )
    end

    local rndName = nameListCopy[ random( #nameListCopy ) ]
    return ( rndName and rndName or nameListTbl[ random( #nameListTbl ) ] )
end

function NPCVC:GetEnemyOfNPC( npc )
    if npc:GetClass() == "reckless_kleiner" then 
        local vehicle = npc:GetParent()
        return ( IsValid( vehicle ) and vehicle.enemy )
    end

    local getEneFunc = npc.GetEnemy
    if !getEneFunc then getEneFunc = npc.GetTarget end
    if getEneFunc then return getEneFunc( npc ) end

    return ( npc.CurrentTarget or npc.Enemy or npc.Target or NULL )
end

local tf2BotsDispTranslation = {
    [ "friend" ]    = D_LI,
    [ "neutral" ]   = D_NU,
    [ "foe" ]       = D_HT
}
function NPCVC:GetDispositionOfNPC( npc, target )
    if npc.MNG_TF2Bot then return ( tf2BotsDispTranslation[ npc:FriendOrFoe( target ) ] or D_NU ) end

    local dispFunc = npc.Disposition
    return ( dispFunc and dispFunc( npc, target ) or ( target:GetClass() == npc:GetClass() and D_LI or D_HT ) )
end

function NPCVC:IsPhysicsProp( ent )
    return ( NPCVC.PropClasses[ ent:GetClass() ] )
end

function NPCVC:GetNPCRealName( npc )
    local npcName = npc.NPCName

    if !npcName then
        local class = npc:GetClass()
        if class == "npc_citizen" then
            if npc:GetModel() == "models/odessa.mdl" then 
                return "npc_odessa"
            elseif npc:HasSpawnFlags( 131072 ) then
                return "Medic"
            else
                local citType = npc:GetInternalVariable( "citizentype" )
                if citType == 2 then
                    return "Refugee"
                elseif citType == 3 then
                    return "Rebel"
                end
            end
        elseif class == "npc_combine_s" then
            local mdl = npc:GetModel()
            if mdl == "models/combine_soldier_prisonguard.mdl" then 
                return ( npc:GetSkin() == 1 and "PrisonShotgunner" or "CombinePrison" )
            elseif mdl == "models/combine_super_soldier.mdl" then
                return "CombineElite"
            elseif mdl == "models/combine_soldier.mdl" and npc:GetSkin() == 1 then
                return "ShotgunSoldier"
            end
        elseif class == "npc_vortigaunt" then
            local mdl = npc:GetModel()
            if mdl == "models/vortigaunt_doctor.mdl" then
                return "VortigauntUriah"
            elseif mdl == "models/vortigaunt_slave.mdl" then
                return "VortigauntSlave"
            end
        elseif class == "npc_antlionguard" and npc:GetSkin() == 1 then
            return "npc_antlionguardian"
        end
    end

    return npcName
end

local function GetNPCSpawnIcon( npc, class )
    local iconName, iconMat
    local npcName = NPCVC:GetNPCRealName( npc )
    if npcName and class != npcName then
        iconName, iconMat = GetNPCSpawnIcon( npc, npcName )
        if !iconMat:IsError() then return iconName, iconMat end
    end

    iconName = "entities/" .. class .. ".png"
    iconMat = Material( iconName )

    if iconMat:IsError() then
        iconName = "entities/" .. class .. ".jpg"
        iconMat = Material( iconName )

        if iconMat:IsError() then
            iconName = "vgui/entities/" .. class
            iconMat = Material( iconName )
        end
    end

    return iconName, iconMat
end

local function GetNPCProfilePicture( npc )
    if vcUseCustomPfps:GetBool() then
        if vcUseLambdaPfpPics:GetBool() and Lambdaprofilepictures and #Lambdaprofilepictures != 0 then
            return Lambdaprofilepictures[ random( #Lambdaprofilepictures ) ]
        else
            local userPfps, pfpPics = NPCVC.UserPFPs, NPCVC.ProfilePictures
            if #userPfps != 0 then
                pfpPics = ( vcUserPfpsOnly:GetBool() and userPfps or table_Merge( pfpPics, userPfps ) )
            end
            if #pfpPics != 0 then 
                return pfpPics[ random( #pfpPics ) ] 
            end
        end
    end

    local npcName, npcClass, npcModel = NPCVC:GetNPCRealName( npc ), npc:GetClass(), npc:GetModel()
    local cacheType, profilePic = npcModel, NPCVC.CachedNPCPfps[ cacheType ]
    if !profilePic then
        cacheType = ( npcName or npcClass )
        profilePic = NPCVC.CachedNPCPfps[ cacheType ]
    end

    if profilePic == nil or profilePic != false then
        local iconName, iconMat = GetNPCSpawnIcon( npc, npcClass )
        if npcModel and #npcModel != 0 and ( vcUseModelIcon:GetBool() or iconMat:IsError() ) then
            iconName = "spawnicons/".. string_sub( npcModel, 1, #npcModel - 4 ).. ".png"
            iconMat = Material( iconName )
        end

        if !iconMat:IsError() then
            profilePic = iconName
            NPCVC.CachedNPCPfps[ cacheType ] = iconName
        elseif profilePic == nil then
            NPCVC.CachedNPCPfps[ cacheType ] = false
        end
    end

    return profilePic
end

local function CheckNearbyNPCOnDeath( ent, attacker )
    local entPos = ent:GetPos()
    local attackPos
    if IsValid( attacker ) and ( attacker:IsPlayer() or attacker:IsNPC() or attacker:IsNextBot() ) then
        attackPos = attacker:GetPos()
    end

    local killLines = vcAllowLines_KillEnemy:GetBool()
    local witnessLines = vcAllowLines_WitnessDeath:GetBool()
    local assistLines = vcAllowLines_Assist:GetBool()
    local isSingle = IsSinglePlayer()
    local isPlyAlly = ( isSingle and NPCVC.PermaAllyNPCs[ ent:GetClass() ] )

    for _, npc in ipairs( FindInSphere( entPos, 1500 ) ) do
        if npc == ent or !IsValid( npc ) or !npc.NPCVC_Initialized or npc:GetInternalVariable( "m_lifeState" ) != 0 or ( random( 1, 4 ) != 1 and NPCVC:IsCurrentlySpeaking( npc ) ) then continue end

        local locAttacker = attacker
        if npc:GetClass() == "reckless_kleiner" and attacker == npc:GetParent() then
            locAttacker = npc
        end

        if locAttacker == npc then
            if killLines and ( random( 1, 100 ) <= npc.NPCVC_SpeechChance or ent:IsPlayer() and ( isSingle or random( 1, 3 ) != 1 ) ) and npc.NPCVC_LastValidEnemy == ent and !NPCVC:IsCurrentlySpeaking( npc, "laugh", "kill", "taunt" ) then
                NPCVC:PlayVoiceLine( npc, ( random( 1, 5 ) == 1 and "laugh" or "kill" ) )
                continue
            end
        elseif attackPos and random( 1, 2 ) != 1 and random( 1, 100 ) <= npc.NPCVC_SpeechChance then
            if ( locAttacker == ent or locAttacker:IsWorld() or NPCVC:GetDispositionOfNPC( locAttacker, ent ) == D_LI ) and !NPCVC:IsCurrentlySpeaking( npc, "laugh" ) then
                NPCVC:PlayVoiceLine( npc, "laugh" )
                continue
            end

            local isEnemy = ( npc.NPCVC_LastValidEnemy == ent or isPlyAlly and NPCVC:GetDispositionOfNPC( ent, npc ) == D_HT )
            if !isEnemy and npc:IsNPC() then
                for _, knownEne in ipairs( npc:GetKnownEnemies() ) do
                    isEnemy = ( knownEne == ent )
                    if isEnemy then break end
                end
            end
            if isEnemy and assistLines and !NPCVC:IsCurrentlySpeaking( npc, "assist" ) and NPCVC:GetDispositionOfNPC( npc, locAttacker ) != D_HT and attackPos:DistToSqr( npc:GetPos() ) <= 589824 then
                NPCVC:PlayVoiceLine( npc, "assist" )
                continue
            end
            if ( isEnemy or NPCVC:GetDispositionOfNPC( npc, ent ) >= 3 ) and entPos:DistToSqr( npc:GetPos() ) <= ( !npc:Visible( ent ) and 40000 or 4000000 ) and !NPCVC:IsCurrentlySpeaking( npc, "panic", "witness" ) then
                NPCVC:PlayVoiceLine( npc, ( ( !isEnemy and random( 1, 3 ) == 1 ) and "panic" or "witness" ) )
                continue
            end
        end
    end
end

local function OnEntityCreated( npc )
    local mapSavedData = NPCVC.MapTransitionNPCs
    if !mapSavedData then 
        local mapSavedNPCs = file_Read( "npcvoicechat/mapsavednpcs.json", "DATA" )
        mapSavedData = ( mapSavedNPCs and JSONToTable( mapSavedNPCs ) or {} )
        NPCVC.MapTransitionNPCs = mapSavedData
    end
    if !vcSaveNPCDataOnMapChange:GetBool() then
        mapSavedData = nil
    end

    SimpleTimer( 0, function()
        if !IsValid( npc ) then return end
        
        npc.NPCVC_LastSeenEnemyTime = 0
        npc.NPCVC_NextIdleSpeak = ( CurTime() + random( 0, 15 ) )
        if npc.NPCVC_Initialized then return end

        local npcClass = npc:GetClass()
        local whitelistVoice = NPCVC.NPCWhitelist[ npcClass ]
        if !whitelistVoice then
            if !npc.IsGmodZombie and !npc.MNG_TF2Bot and !npc.SBAdvancedNextBot and !npc.IsDrGNextbot and !npc.IV04NextBot and !npc.LastPathingInfraction and ( !NPCVC:IsPhysicsProp( npc ) or !vcAllowProps:GetBool() ) and npcClass != "reckless_kleiner" and npcClass != "npc_antlion_grub" and ( !npc:IsNPC() or NPCVC.NonNPC_NPCs[ npcClass ] or string_find( npcClass, "bullseye" ) ) then return end
            if IsBasedOn( npcClass, "animprop_generic" ) or IsBasedOn( npcClass, "animprop_generic_physmodel" ) then return end
            if npc.Base == "npc_vj_tankg_base" then return end
        end

        npc.NPCVC_Initialized = true
        npc.NPCVC_IsKilled = false
        npc.NPCVC_LastEnemy = NULL
        npc.NPCVC_LastValidEnemy = NULL
        npc.NPCVC_IsLowHealth = false
        npc.NPCVC_InPanicState = false
        npc.NPCVC_LastState = -1
        npc.NPCVC_LastVoiceLine = ""
        npc.NPCVC_IdleVoiceType = ( whitelistVoice != true and whitelistVoice or "idle" )
        npc.NPCVC_NextPanicCheck = 0
        npc.NPCVC_EnemyPlayers = {}

        if npc.LastPathingInfraction then
            npc.NPCVC_VoiceIconHeight = 138
            npc.NPCVC_VoiceVolumeScale = 2
        else
            local scale = ( npc:GetModelScale() or 1 )
            local height = ( NPCVC.NPCIconHeights[ npcClass ] or ( ( npc:OBBMaxs().z + 10 ) * scale )  )
            local isTwo = istable( height )
            local isProp = NPCVC:IsPhysicsProp( npc )

            npc.NPCVC_VoiceIconHeight = ( isTwo and height[ 2 ] or height )

            local volScale = ( abs( isTwo and height[ 1 ] or height ) / ( isProp and 40 or 72 ) )
            if !isProp then volScale = Clamp( volScale, 0.66, 3.33 ) end
            npc.NPCVC_VoiceVolumeScale = volScale

            if !isTwo then
                local mins, maxs = npc:GetModelRenderBounds()

                if mins and maxs and ( !mins:IsZero() or !maxs:IsZero() ) then
                    local mdlHeight = ( ( abs( mins.z ) + maxs.z ) * scale )
                    if mdlHeight > height then
                        npc.NPCVC_VoiceIconHeight = ( NPCVC.NPCIconHeights[ npcClass ] or ( mdlHeight + 10 ) )
                        npc.NPCVC_VoiceVolumeScale = Clamp( ( abs( mdlHeight ) / 72 ), 0.66, 4.25 )
                    end
                else
                    net.Start( "npcsqueakers_getrenderbounds" )
                        net.WriteEntity( npc )
                    net.Broadcast()

                    net.Receive( "npcsqueakers_sendrenderbounds", function()
                        local mins, maxs = net.ReadVector(), net.ReadVector()
                        local mdlHeight = ( ( abs( mins.z ) + maxs.z ) * scale )
                        if mdlHeight <= height or !IsValid( npc ) then return end

                        npc.NPCVC_VoiceIconHeight = ( NPCVC.NPCIconHeights[ npcClass ] or ( mdlHeight + 10 ) )
                        npc.NPCVC_VoiceVolumeScale = Clamp( ( abs( mdlHeight ) / 72 ), 0.66, 3.33 )
                    end )
                end
            end
        end

        if !npc.NPCVC_IsDuplicated then
            local speechChance = random( vcMinSpeechChance:GetInt(), vcMaxSpeechChance:GetInt() )
            npc.NPCVC_SpeechChance = speechChance
            
            local maxPitch = vcPitchMax:GetInt()
            local voiceScale = min( npc.NPCVC_VoiceVolumeScale, 1 )
            local voicePitch = random( vcPitchMin:GetInt(), maxPitch )
            local sizePitch = min( ( 1 / voiceScale ) * voicePitch, maxPitch )
            -- print( voicePitch, voiceScale, sizePitch )

            if vcHighPitchSmallNPCs:GetBool() then
                voicePitch = sizePitch
            end
            npc.NPCVC_VoicePitch = voicePitch

            local nickName
            if vcUseRealNames:GetBool() then
                local gmName = GAMEMODE.GetDeathNoticeEntityName
                local locName = "#" .. npcClass

                if gmName then
                    nickName = gmName( GAMEMODE, npc )

                    if nickName == locName then
                        local realName = NPCVC:GetNPCRealName( npc )
                        if npc.NPCName != realName then 
                            local listName = list.Get( "NPC" )[ realName ]
                            if listName then nickName = listName.Name end
                        end
                    end
                else
                    nickName = locName
                end

                npc.NPCVC_UsesRealName = true
            else
                nickName = GetAvailableNickname()
            end
            npc.NPCVC_Nickname = nickName

            local profilePic = GetNPCProfilePicture( npc )
            npc.NPCVC_ProfilePicture = profilePic

            local voicePfp = NPCVC.NPCVoiceProfiles[ npcClass ]
            if !voicePfp then
                local cvarVoice = vcVoiceProfile:GetString()
                voicePfp = NPCVC.VoiceProfiles[ cvarVoice ]
                if !voicePfp then 
                    if random( 1, 100 ) <= vcVoiceProfileChance:GetInt() then
                        local voicePfps = table_GetKeys( NPCVC.VoiceProfiles ) 
                        voicePfp = voicePfps[ random( #voicePfps ) ]
                    end
                else
                    voicePfp = cvarVoice
                    npc.NPCVC_IsVoiceProfileServerside = true
                end    
            else
                npc.NPCVC_IsVoiceProfileServerside = true
            end
            npc.NPCVC_VoiceProfile = voicePfp

            npc.NPCVC_StoredData = {
                SpeechChance = speechChance,
                VoicePitch = voicePitch,
                NickName = nickName,
                ProfilePicture = profilePic,
                VoiceProfile = voicePfp
            }
            StoreEntityModifier( npc, "NPC VoiceChat - NPC's Voice Data", npc.NPCVC_StoredData )

            if mapSavedData and NPCVC.NPCsToTransition[ npcClass ] then
                SimpleTimer( 0.1, function()
                    if !IsValid( npc ) or npc.NPCVC_CreatedByPlayer or npc.NPCVC_IsDuplicated then return end

                    local saveData = mapSavedData[ npcClass ]
                    if !saveData then
                        NPCVC.MapTransitionNPCs[ npcClass ] = npc.NPCVC_StoredData
                    else
                        SetNPCVoiceChatData( nil, npc, saveData )
                    end
                end )
            end
        end

        if npc.IsVJBaseSNPC then
            local old_PlaySoundSystem = npc.PlaySoundSystem

            function npc:PlaySoundSystem( sdSet, customSd, sdType )
                if sdSet == "OnDangerSight" or sdSet == "OnGrenadeSight" then
                    if vcAllowLines_SpotDanger:GetBool() and !NPCVC:IsCurrentlySpeaking( npc, "panic" ) then
                        NPCVC:PlayVoiceLine( npc, "panic" )
                    end
                elseif random( 1, 100 ) <= npc.NPCVC_SpeechChance and !NPCVC:IsCurrentlySpeaking( npc ) then
                    if sdSet == "MedicReceiveHeal" and vcAllowLines_Assist:GetBool() then
                        NPCVC:PlayVoiceLine( npc, "assist" )
                    end
                end

                old_PlaySoundSystem( npc, sdSet, customSd, sdType )
            end
        end

        local mapData = NPCVC.SpecialMapOrigins[ game.GetMap() ]
        if !mapData then return end
            
        mapData = mapData[ npcClass ]
        if mapData then npc.NPCVC_AdditionalPlay = table_Copy( mapData ) end
    end )
end

local function OnPlayerSpawnedNPC( ply, npc )
    SimpleTimer( 0, function()
        if !IsValid( npc ) or !npc.NPCVC_Initialized or npc.NPCVC_IsDuplicated or npc.NPCVC_IsVoiceProfileServerside then return end
        npc.NPCVC_CreatedByPlayer = true

        local voicePfp = ply:GetInfo( "cl_npcvoicechat_spawnvoiceprofile" )
        if !voicePfp or #voicePfp == 0 then return end
        
        npc.NPCVC_VoiceProfile = voicePfp
        npc.NPCVC_StoredData.VoiceProfile = voicePfp
        StoreEntityModifier( npc, "NPC VoiceChat - NPC's Voice Data", npc.NPCVC_StoredData )
    end )
end

local function OnNPCKilled( npc, attacker, inflictor, isInput )
    if !npc.NPCVC_Initialized then return end
    npc.NPCVC_IsKilled = true

    if ( random( 1, 100 ) <= npc.NPCVC_SpeechChance or !vcVoiceChanceAffectDeath:GetBool() ) and vcAllowLines_Death:GetBool() then
        NPCVC:PlayVoiceLine( npc, "death", true, isInput )
    else
        NPCVC:StopCurrentSpeech( npc )
    end

    CheckNearbyNPCOnDeath( npc, attacker )
end

local function OnEntityRemoved( npc )
    if !npc.NPCVC_Initialized then return end

    local npcClass = npc:GetClass()
    if npcClass != "rpg_missile" and npcClass != "grenade_ar2" and npcClass != "npc_grenade_bugbait" and npcClass != "npc_grenade_frag" and npcClass != "grenade_helicopter" then return end

    OnNPCKilled( npc )
end

local function OnPlayerDeath( ply, inflictor, attacker )
    if ignorePlys:GetBool() then return end

    SimpleTimer( 0.1, function()
        CheckNearbyNPCOnDeath( ply, attacker )
    end )
end

local function OnCreateEntityRagdoll( owner, ragdoll )
    if !owner.NPCVC_Initialized then return end
    
    local failTime = ( CurTime() + 1 )
    local timerName = "npcsqueakers_fuckyouohwaitnvm" .. owner:EntIndex()

    CreateTimer( timerName, 0, 0, function()
        if !IsValid( owner ) or !IsValid( ragdoll ) or CurTime() >= failTime then RemoveTimer( timerName ) return end  

        local sndEmitter = owner:GetNW2Entity( "npcsqueakers_sndemitter" )
        if !IsValid( sndEmitter ) then return end

        sndEmitter:SetSoundSource( ragdoll )
        RemoveTimer( timerName )
    end )
end

local function OnServerThink()
    local curTime = CurTime()
    if curTime < nextNPCSoundThink then return end

    nextNPCSoundThink = ( curTime + 0.1 )
    if aiDisabled:GetBool() then return end

    for _, npc in ipairs( ents_GetAll() ) do
        if !IsValid( npc ) or !npc.NPCVC_Initialized or npc.l_TranqGun_IsTranquilized then continue end

        if npc.IsDoomNPC then 
            if npc:Health() <= 0 then 
                if !npc.NPCVC_IsKilled then OnNPCKilled( npc, nil, nil ) end
                continue
            elseif npc.NPCVC_IsKilled then
                npc.NPCVC_IsKilled = false
            end
        end

        local npcClass = npc:GetClass()
        if npcClass == "monster_leech" and npc:GetInternalVariable( "m_takedamage" ) == 0 then
            continue
        end

        if npcClass == "npc_turret_floor" then 
            local selfDestructing = npc:GetInternalVariable( "m_bSelfDestructing" )
            if !selfDestructing then 
                local curState = npc:GetNPCState()
                local lastState = npc.NPCVC_LastState
                if curState != lastState then
                    if lastState == NPC_STATE_DEAD and npc:IsPlayerHolding() and vcAllowLines_Assist:GetBool() then
                        NPCVC:PlayVoiceLine( npc, "assist" )
                    elseif curState == NPC_STATE_DEAD and vcAllowLines_SpotDanger:GetBool() then
                        NPCVC:PlayVoiceLine( npc, "panic" )
                    elseif curState == NPC_STATE_COMBAT and vcAllowLines_SpotEnemy:GetBool() and !NPCVC:IsCurrentlySpeaking( npc, "taunt" ) then
                        NPCVC:PlayVoiceLine( npc, "taunt" )
                    end
                end
                npc.NPCVC_LastState = curState

                local curEnemy = npc:GetEnemy()
                local lastEnemy = npc.NPCVC_LastEnemy
                if curEnemy != lastEnemy and IsValid( curEnemy ) and vcAllowLines_SpotEnemy:GetBool() then
                    NPCVC:PlayVoiceLine( npc, "taunt" )
                end
                npc.NPCVC_LastEnemy = curEnemy
            elseif !npc.NPCVC_InPanicState then
                npc.NPCVC_InPanicState = true

                if vcAllowLines_PanicCond:GetBool() then
                    SimpleTimer( Rand( 0.8, 1.25 ), function()
                        if !IsValid( npc ) then return end
                        NPCVC:PlayVoiceLine( npc, "panic" )
                    end )

                    SimpleTimer( Rand( 2, 3.5 ), function()
                        if !IsValid( npc ) then return end
                        OnNPCKilled( npc )
                    end )
                end
            end
        elseif npcClass == "npc_rollermine" and IsValid( npc:GetInternalVariable( "m_hVehicleStuckTo" ) ) and vcAllowLines_CombatIdle:GetBool() then
            if curTime >= npc.NPCVC_NextIdleSpeak then 
                if random( 1, 100 ) <= npc.NPCVC_SpeechChance and !NPCVC:IsCurrentlySpeaking( npc ) then
                    NPCVC:PlayVoiceLine( npc, "taunt" )
                end
            end
        elseif npcClass == "combine_mine" and npc:GetInternalVariable( "m_iMineState" ) == 4 and vcAllowLines_CombatIdle:GetBool() then
            if random( 1, 100 ) <= npc.NPCVC_SpeechChance and !NPCVC:IsCurrentlySpeaking( npc ) then
                NPCVC:PlayVoiceLine( npc, "taunt" )
            end
        elseif npcClass == "rpg_missile" or npcClass == "grenade_ar2" or npcClass == "crossbow_bolt" or npcClass == "hunter_flechette" or npcClass == "npc_grenade_bugbait" then 
            if npc:GetMoveType() == MOVETYPE_NONE then
                if !npc.NPCVC_IsKilled then
                    OnNPCKilled( npc, nil, nil )
                end
            elseif vcAllowLines_PanicCond:GetBool() and !NPCVC:IsCurrentlySpeaking( npc, "panic" ) then
                NPCVC:PlayVoiceLine( npc, "panic" )
            end
        elseif npcClass == "prop_combine_ball" then
            if npc:GetMoveType() == MOVETYPE_NONE then
                if !NPCVC:IsCurrentlySpeaking( npc, "death" ) and vcAllowLines_Death:GetBool() then
                    OnNPCKilled( npc, nil, nil )
                end
            else
                local bounceCount = npc:GetInternalVariable( "m_nBounceCount" )
                local lastCount = npc.NPCVC_LastState
                if bounceCount != lastCount and lastCount != -1 and !NPCVC:IsCurrentlySpeaking( npc, "panic" ) and vcAllowLines_PanicCond:GetBool() then
                    NPCVC:PlayVoiceLine( npc, "panic" )
                elseif curTime >= npc.NPCVC_NextIdleSpeak and !NPCVC:IsCurrentlySpeaking( npc ) and random( 1, 100 ) <= npc.NPCVC_SpeechChance and vcAllowLines_Idle:GetBool() then
                    NPCVC:PlayVoiceLine( npc, "idle" )
                end
                npc.NPCVC_LastState = bounceCount
            end
        elseif npcClass == "npc_antlion_grub" then
            local curState = npc:GetInternalVariable( "m_State" )

            if npc:GetInternalVariable( "m_takedamage" ) == 0 then
                if !npc.NPCVC_IsKilled then
                    OnNPCKilled( npc, nil, nil )
                end
            else
                local curState = npc:GetInternalVariable( "m_State" )
                if random( 1, 100 ) <= npc.NPCVC_SpeechChance and random( 1, 3 ) == 1 then
                    if curState == 1 and curState != npc.NPCVC_LastState then
                        NPCVC:PlayVoiceLine( npc, "taunt" )
                    elseif curTime >= npc.NPCVC_NextIdleSpeak and !NPCVC:IsCurrentlySpeaking( npc ) then
                        NPCVC:PlayVoiceLine( npc, ( curState == 1 and "taunt" or "idle" ) )
                    end
                end

                npc.NPCVC_LastState = curState
            end
        elseif npcClass == "npc_combine_camera" then
            if npc:GetInternalVariable( "m_takedamage" ) == 2 then
                local lookTarget = npc:GetInternalVariable( "m_hEnemyTarget" )
                local lastTarget = npc.NPCVC_LastEnemy
                local isAngry = npc:GetInternalVariable( "m_bAngry" )

                if lookTarget != lastTarget and IsValid( lookTarget ) or isAngry and isAngry != npc.NPCVC_LastState then 
                    if isAngry and vcAllowLines_CombatIdle:GetBool() then
                        NPCVC:PlayVoiceLine( npc, "taunt" )
                    elseif vcAllowLines_Idle:GetBool() then
                        NPCVC:PlayVoiceLine( npc, "idle" )
                    end
                end

                if npc:GetInternalVariable( "m_bActive" ) and IsValid( lookTarget ) and curTime >= npc.NPCVC_NextIdleSpeak and random( 1, 100 ) <= npc.NPCVC_SpeechChance and !NPCVC:IsCurrentlySpeaking( npc ) then
                    if IsValid( lookTarget ) and isAngry and vcAllowLines_CombatIdle:GetBool() then
                        NPCVC:PlayVoiceLine( npc, "taunt" )
                    elseif vcAllowLines_Idle:GetBool() then
                        NPCVC:PlayVoiceLine( npc, "idle" )
                    end
                end

                npc.NPCVC_LastEnemy = lookTarget
                npc.NPCVC_LastState = isAngry
            elseif npc.NPCVC_LastState != -1 then
                npc.NPCVC_LastState = -1
                if vcAllowLines_Death:GetBool() then
                    NPCVC:PlayVoiceLine( npc, "death" )
                end
            end
        else
            local curEnemy = NPCVC:GetEnemyOfNPC( npc )
            local rolledSpeech = ( random( 1, 100 ) <= npc.NPCVC_SpeechChance )

            if npc.LastPathingInfraction then
                local isVisible, lastSeenTime = false, npc.NPCVC_LastSeenEnemyTime
                if !IsValid( curEnemy ) then
                    npc.NPCVC_LastSeenEnemyTime = 0
                elseif npc:GetRangeSquaredTo( curEnemy ) <= 1000000 and npc:Visible( curEnemy ) then
                    isVisible = true
                    npc.NPCVC_LastSeenEnemyTime = curTime
                end

                if rolledSpeech then
                    if lastSeenTime == 0 and isVisible and vcAllowLines_SpotEnemy:GetBool() then
                        NPCVC:PlayVoiceLine( npc, "taunt" )
                    elseif curTime >= npc.NPCVC_NextIdleSpeak and !NPCVC:IsCurrentlySpeaking( npc ) then
                        if ( curTime - npc.NPCVC_LastSeenEnemyTime ) <= 5 and IsValid( curEnemy ) then
                            if vcAllowLines_CombatIdle:GetBool() then
                                NPCVC:PlayVoiceLine( npc, "taunt" )
                            end
                        elseif vcAllowLines_Idle:GetBool() then
                            NPCVC:PlayVoiceLine( npc, "idle" )
                        end
                    end
                end
            else
                local lifeState = npc:GetInternalVariable( "m_lifeState" )
                if lifeState != 0 and ( npcClass == "npc_combinegunship" or npcClass == "npc_helicopter" ) then
                    if !NPCVC:IsCurrentlySpeaking( npc, "death" ) and vcAllowLines_Death:GetBool() then
                        NPCVC:PlayVoiceLine( npc, "death", true )
                    end
                elseif lifeState == 0 then 
                    local isNPC = npc:IsNPC()
                    local barnacled = ( npc:IsEFlagSet( EFL_IS_BEING_LIFTED_BY_BARNACLE ) or isNPC and npc:GetNPCState() == NPC_STATE_PRONE )
                    local isPurelyPanic = vcAllowLines_PanicCond:GetBool()
                    local stopSpeech = ( rolledSpeech == true )

                    if isPurelyPanic then
                        isPurelyPanic = ( barnacled or npc:IsOnFire() or npc:IsPlayerHolding() and !npc:GetInternalVariable( "m_bHackedByAlyx" ) or isNPC and ( npc:GetInternalVariable( "m_nFlyMode" ) == 6 ) )

                        if !isPurelyPanic and isNPC then
                            local curSched = ( npc:GetCurrentSchedule() + 1000000000 )
                            isPurelyPanic = ( curSched == GetScheduleID( "SCHED_ANTLION_FLIP" ) or curSched == GetScheduleID( "SCHED_COMBINE_BUGBAIT_DISTRACTION" ) )

                            if !isPurelyPanic then 
                                local engineStallT = npc:GetInternalVariable( "m_flEngineStallTime" )
                                isPurelyPanic = ( engineStallT and engineStallT > 0.5 ) 
                            end

                            if !isPurelyPanic and NPCVC.DrownableNPCs[ npcClass ] then
                                waterCheckTr.start = npc:WorldSpaceCenter()
                                waterCheckTr.endpos = ( waterCheckTr.start + npc:GetVelocity() )
                                waterCheckTr.filter = npc
                                waterCheckTr.collisiongroup = npc:GetCollisionGroup()

                                isPurelyPanic = ( band( PointContents( TraceLine( waterCheckTr ).HitPos ), CONTENTS_WATER ) != 0 )
                            end
                        end

                        if !isPurelyPanic and npc:GetMoveType() == MOVETYPE_VPHYSICS then
                            local phys = npc:GetPhysicsObject()
                            if IsValid( phys ) and phys:GetVelocity():Length() >= 750 and IsValidProp( npc:GetModel() ) then
                                isPurelyPanic = true
                                stopSpeech = true
                            end
                        end
                    end

                    if isPurelyPanic then
                        if !NPCVC:IsCurrentlySpeaking( npc, "panic", "death" ) and CurTime() >= npc.NPCVC_NextPanicCheck then
                            npc.NPCVC_NextPanicCheck = ( CurTime() + 5 )
                            if rolledSpeech then NPCVC:PlayVoiceLine( npc, ( random( 10 ) == 1 and "death" or "panic" ) ) end
                        end

                        if barnacled and !NPCVC.HLS_NPCs[ npcClass ] then
                            SimpleTimer( 0.1, function()
                                if !IsValid( npc ) then return end

                                local npcMdl = npc:GetModel()
                                local sndEmitter = npc:GetNW2Entity( "npcsqueakers_sndemitter" )
                                if IsValid( sndEmitter ) and sndEmitter:GetSoundSource() == npc then
                                    for _, barn in ipairs( FindByClass( "npc_barnacle" ) ) do
                                        if !IsValid( barn ) or barn:GetInternalVariable( "m_lifeState" ) != 0 or barn:GetEnemy() != npc then continue end

                                        local ragdoll = barn:GetInternalVariable( "m_hRagdoll" )
                                        if !IsValid( ragdoll ) or ragdoll:GetModel() != npcMdl then continue end

                                        sndEmitter:SetSoundSource( ragdoll )
                                        break
                                    end
                                end
                            end )
                        end               
                    else
                        if stopSpeech and npc.NPCVC_InPanicState then
                            NPCVC:StopCurrentSpeech( npc, "panic" )

                            if IsValid( curEnemy ) and vcAllowLines_CombatIdle:GetBool() then
                                NPCVC:PlayVoiceLine( npc, "taunt" )
                            elseif vcAllowLines_Idle:GetBool() then
                                NPCVC:PlayVoiceLine( npc, "witness" )
                            end
                        end

                        local lowHP = npc.NPCVC_IsLowHealth
                        if lowHP and npc:Health() > ( npc:GetMaxHealth() * lowHP ) then
                            lowHP = false
                            npc.NPCVC_IsLowHealth = lowHP
                        end

                        local lastEnemy = npc.NPCVC_LastEnemy
                        local isPanicking = false
                        local combatLine = "taunt" 
                        
                        if IsValid( curEnemy ) then
                            isPanicking = ( curEnemy.LastPathingInfraction and !npc:IsNextBot() )
                            if !isPanicking and !npc.IsVJBaseSNPC and isNPC then
                                isPanicking = ( IsValid( curEnemy ) and ( NPCVC.NoWeaponNoFearNPCs[ npcClass ] and !IsValid( npc:GetActiveWeapon() ) or NPCVC:GetDispositionOfNPC( npc, curEnemy ) == D_FR and ( !NPCVC.DontFearNPCs[ curEnemy:GetClass() ] or npc:GetPos():DistToSqr( curEnemy:GetPos() ) <= 200 ) ) )
                            end
                            if !isPanicking then
                                isPanicking = ( npc.NoWeapon_UseScaredBehavior and !IsValid( npc:GetActiveWeapon() ) )
                            end

                            if curEnemy == lastEnemy and ( ( curTime - npc.NPCVC_LastSeenEnemyTime ) >= 30 or npc:GetPos():DistToSqr( curEnemy:GetPos() ) > 2250000 ) then
                                combatLine = "idle"
                            elseif isPanicking or lowHP and random( 1, ( 8 * ( ( npc:Health() / npc:GetMaxHealth() ) / lowHP ) ) ) == 1 then
                                if curEnemy.LastPathingInfraction or npc:GetPos():DistToSqr( curEnemy:GetPos() ) <= 250000 or npc:Visible( curEnemy ) then
                                    combatLine = "panic"
                                else 
                                    combatLine = "idle"
                                end
                            end
                        end

                        local isNearDanger = ( isNPC and ( npc:HasCondition( 50 ) or npc:HasCondition( 57 ) ) )
                        if !isNearDanger and vcUseSoundHintsForDangers:GetBool() then
                            local npcPos = npc:GetPos()
                            local hintDang = ( GetLoudestSoundHint( SOUND_DANGER, npcPos ) or GetLoudestSoundHint( SOUND_PHYSICS_DANGER, npcPos ) or GetLoudestSoundHint( SOUND_CONTEXT_DANGER_APPROACH, npcPos ) )

                            if hintDang then
                                local hintOwner = hintDang.owner
                                isNearDanger = ( hintDang.volume > ( npc:GetMaxHealth() * 1.5 ) and ( !IsValid( hintOwner ) and npc:VisibleVec( hintDang.origin ) or IsValid( hintOwner ) and hintOwner != npc and hintOwner:GetClass() != npcClass and npc:Visible( hintOwner ) ) )
                            end
                        end

                        if isNearDanger and vcAllowLines_SpotDanger:GetBool() and !NPCVC:IsCurrentlySpeaking( npc, "panic" ) and CurTime() >= npc.NPCVC_NextPanicCheck then
                            npc.NPCVC_NextPanicCheck = ( CurTime() + 5 )
                            if rolledSpeech then NPCVC:PlayVoiceLine( npc, "panic" ) end
                        elseif isNPC and !npc.IsVJBaseSNPC and !npc.IsDoomNPC and !NPCVC.HLS_NPCs[ npcClass ] and npcClass != "npc_barnacle" and npcClass != "reckless_kleiner" and ( !NPCVC.NoStateUsingNPCs[ npcClass ] or npcClass == "npc_turret_ceiling" and !npc:GetInternalVariable( "m_bActive" ) ) then
                            local curState = npc:GetNPCState()

                            if rolledSpeech then
                                if curState != npc.NPCVC_LastState then
                                    if curState == NPC_STATE_COMBAT and !IsValid( lastEnemy ) and vcAllowLines_SpotEnemy:GetBool() and !NPCVC:IsCurrentlySpeaking( npc ) then
                                        NPCVC:PlayVoiceLine( npc, combatLine )
                                    end
                                elseif curTime >= npc.NPCVC_NextIdleSpeak and !NPCVC:IsCurrentlySpeaking( npc ) then
                                    if curState == NPC_STATE_COMBAT and IsValid( curEnemy ) then
                                        if vcAllowLines_CombatIdle:GetBool() then
                                            NPCVC:PlayVoiceLine( npc, combatLine )
                                        end
                                    elseif ( curState == NPC_STATE_IDLE or curState == NPC_STATE_ALERT or curState == NPC_STATE_SCRIPT ) and vcAllowLines_Idle:GetBool() then
                                        NPCVC:PlayVoiceLine( npc, npc.NPCVC_IdleVoiceType )
                                    end
                                end
                            end

                            npc.NPCVC_LastState = curState
                        else
                            if npc.IsDrGNextbot and npc:IsDown() then 
                                if npc.NPCVC_LastState != 1 then
                                    OnNPCKilled( npc )
                                    npc.NPCVC_LastState = 1
                                end
                            elseif npc.NPCVC_LastState == 1 then
                                npc.NPCVC_LastState = -1
                                if rolledSpeech and IsValid( curEnemy ) then NPCVC:PlayVoiceLine( npc, "taunt" ) end
                            end

                            if rolledSpeech then
                                if curEnemy != lastEnemy then
                                    if IsValid( curEnemy ) and !IsValid( lastEnemy ) and vcAllowLines_SpotEnemy:GetBool() and !NPCVC:IsCurrentlySpeaking( npc ) then
                                        NPCVC:PlayVoiceLine( npc, combatLine )
                                    end
                                elseif curTime >= npc.NPCVC_NextIdleSpeak and !NPCVC:IsCurrentlySpeaking( npc ) then
                                    if IsValid( curEnemy ) then
                                        if vcAllowLines_CombatIdle:GetBool() then
                                            NPCVC:PlayVoiceLine( npc, combatLine )
                                        end
                                    elseif vcAllowLines_Idle:GetBool() then
                                        NPCVC:PlayVoiceLine( npc, npc.NPCVC_IdleVoiceType )
                                    end
                                end
                            end
                        end
                    end

                    npc.NPCVC_InPanicState = isPurelyPanic
                end
            end

            npc.NPCVC_LastEnemy = curEnemy
            if IsValid( curEnemy ) then 
                npc.NPCVC_LastValidEnemy = curEnemy
                
                if npc.NPCVC_LastSeenEnemyTime == 0 or npc:Visible( curEnemy ) then 
                    npc.NPCVC_LastSeenEnemyTime = curTime 
                end
            else
                npc.NPCVC_LastSeenEnemyTime = 0
            end
        end

        if curTime >= npc.NPCVC_NextIdleSpeak then
            npc.NPCVC_NextIdleSpeak = ( curTime + random( 0, 15 ) )
        end
    end
end

local function OnPostEntityTakeDamage( ent, dmginfo, tookDamage )
    if !tookDamage or !IsValid( ent ) or !ent.NPCVC_Initialized or ent:GetClass() == "npc_antlion_grub" then return end
    local playPanicSnd = false

    if !ent.NPCVC_IsLowHealth then
        local hpThreshold = Rand( 0.1, 0.4 )
        if ent:Health() <= ( ent:GetMaxHealth() * hpThreshold ) then
            playPanicSnd = true
            ent.NPCVC_IsLowHealth = hpThreshold
        end
    end

    if random( 1, 4 ) == 1 and !NPCVC:IsCurrentlySpeaking( ent, "panic" ) and IsValid( NPCVC:GetEnemyOfNPC( ent ) ) and dmginfo:GetDamage() >= ( ent:GetMaxHealth() / random( 2, 4 ) ) then
        playPanicSnd = true
    end

    if random( 1, 100 ) <= ent.NPCVC_SpeechChance then
        if playPanicSnd then 
            SimpleTimer( 0.1, function()
                if !IsValid( ent ) or ent:GetInternalVariable( "m_lifeState" ) != 0 then return end
                if !vcAllowLines_LowHealth:GetBool() then return end
                NPCVC:PlayVoiceLine( ent, "panic" )
            end )
        elseif random( 1, 2 ) == 1 and !NPCVC:IsCurrentlySpeaking( ent ) then
            local attacker = dmginfo:GetAttacker()
            if IsValid( attacker ) and NPCVC:GetDispositionOfNPC( ent, attacker ) == D_LI then
                NPCVC:PlayVoiceLine( ent, "witness" )
            end
        end
    end
end

local function OnAcceptInput( ent, input, activator, caller, value )
    if !IsValid( ent ) or !ent.NPCVC_Initialized or NPCVC:IsCurrentlySpeaking( ent, "death" ) then return end
    
    if input == "Use" and ( random( 1, 100 ) <= ent.NPCVC_SpeechChance ) and !NPCVC:IsCurrentlySpeaking( ent ) and IsValid( activator ) and activator:IsPlayer() and NPCVC:GetDispositionOfNPC( ent, activator ) == D_LI and !IsValid( ent:GetEnemy() ) then
        NPCVC:PlayVoiceLine( ent, ent.NPCVC_IdleVoiceType )
        ent.NPCVC_NextIdleSpeak = ( CurTime() + random( 0, 15 ) )
        return
    end

    if input == "BecomeRagdoll" then
        OnNPCKilled( ent, activator, caller, true )
        return
    end

    if input == "Kill" and NPCVC.HLS_NPCs[ ent:GetClass() ] then -- HL:S NPCs only >:(
        OnNPCKilled( ent, activator, caller )
    end
end

local function OnPropBreak( attacker, prop )
    if !IsValid( prop ) or !prop.NPCVC_Initialized or NPCVC:IsCurrentlySpeaking( prop, "death" ) then return end
    OnNPCKilled( prop, attacker )
end

-- No more mute combine snipers!
local function OnEntityEmitSound( data )
    if data.OriginalSoundName == "NPC_Sniper.Die" then
        local ent = data.Entity
        if IsValid( ent ) and ent:GetClass() == "npc_sniper" then
            NPCVC:PlayVoiceLine( ent, "death", true )
        end
    elseif string_StartsWith( data.SoundName, "soul_kicker/memes/meme" ) then -- Soul Kicker (i like it lol)
        local ent = data.Entity
        if IsValid( ent ) and ent:GetClass() == "prop_ragdoll" then
            for _, npc in ipairs( FindByModel( ent:GetModel() ) ) do
                if npc == ent or !npc.NPCVC_Initialized or !npc:IsMarkedForDeletion() then continue end
                OnNPCKilled( npc )

                local sndEmitter = npc:GetNW2Entity( "npcsqueakers_sndemitter" )
                if IsValid( sndEmitter ) then sndEmitter:SetSoundSource( ent ) end

                break
            end
        end
    end
end

local function OnServerShutDown()
    if !vcSaveNPCDataOnMapChange:GetBool() then
        local mapSavedNPCs = file_Read( "npcvoicechat/mapsavednpcs.json", "DATA" )
        if mapSavedNPCs then file_Delete( "npcvoicechat/mapsavednpcs.json" ) end
    elseif NPCVC.MapTransitionNPCs then
        file_Write( "npcvoicechat/mapsavednpcs.json", TableToJSON( NPCVC.MapTransitionNPCs ) )
    end

    local lineTbl = {}
    local osTime, realT = os_time(), CurTime()
    for snd, time in pairs( NPCVC.LastUsedLines ) do
        if realT >= time then continue end
        lineTbl[ snd ] = ( osTime + ( time - realT ) )
    end
    file_Write( "npcvoicechat/lastusedlines.json", TableToJSON( lineTbl ) )
end

local function OnMapInitialized()
    UpdateData()

    --

    local lineTbl = file_Read( "npcvoicechat/lastusedlines.json", "DATA" )
    if lineTbl then 
        local osTime = os_time()
        lineTbl = JSONToTable( lineTbl )

        for snd, time in pairs( lineTbl ) do
            local finTime = ( time - osTime )
            if finTime <= 0 then continue end

            NPCVC.LastUsedLines[ snd ] = finTime
        end
    end

    --

    NPCVC.OldFunc_GetDeathNoticeEntityName = ( NPCVC.OldFunc_GetDeathNoticeEntityName or GAMEMODE.GetDeathNoticeEntityName )
    if !NPCVC.OldFunc_GetDeathNoticeEntityName then return end
    
    function GAMEMODE:GetDeathNoticeEntityName( ent )
        local origReturn = NPCVC.OldFunc_GetDeathNoticeEntityName( self, ent )
        if vcKillfeedNick:GetBool() and !ent.NPCVC_UsesRealName then
            return ( ent.NPCVC_Nickname or origReturn ) 
        end
        return origReturn
    end
end

hook.Add( "OnEntityCreated", "NPCSqueakers_OnEntityCreated", OnEntityCreated )
hook.Add( "EntityRemoved", "NPCSqueakers_OnEntityRemoved", OnEntityRemoved )
hook.Add( "EntityEmitSound", "NPCSqueakers_OnEntityEmitSound", OnEntityEmitSound )
hook.Add( "PlayerSpawnedNPC", "NPCSqueakers_OnPlayerSpawnedNPC", OnPlayerSpawnedNPC )
hook.Add( "OnNPCKilled", "NPCSqueakers_OnNPCKilled", OnNPCKilled )
hook.Add( "PlayerDeath", "NPCSqueakers_OnPlayerDeath", OnPlayerDeath )
hook.Add( "CreateEntityRagdoll", "NPCSqueakers_OnCreateEntityRagdoll", OnCreateEntityRagdoll )
hook.Add( "Think", "NPCSqueakers_OnServerThink", OnServerThink )
hook.Add( "PostEntityTakeDamage", "NPCSqueakers_OnPostEntityTakeDamage", OnPostEntityTakeDamage )
hook.Add( "AcceptInput", "NPCSqueakers_OnAcceptInput", OnAcceptInput )
hook.Add( "PropBreak", "NPCSqueakers_OnPropBreak", OnPropBreak )
hook.Add( "ShutDown", "NPCSqueakers_OnServerShutDown", OnServerShutDown )
hook.Add( "InitPostEntity", "NPCSqueakers_OnMapInitialized", OnMapInitialized )