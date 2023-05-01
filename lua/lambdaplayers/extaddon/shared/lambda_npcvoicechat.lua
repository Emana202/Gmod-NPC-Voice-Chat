local net = net
local ipairs = ipairs
local IsValid = IsValid
local SimpleTimer = timer.Simple
local random = math.random
local string_sub = string.sub
local Clamp = math.Clamp

local vcEnabled = CreateLambdaConvar( "lambdaplayers_npcvoicechat_enabled", 1, true, false, false, "Allows to NPCs and nextbots to able to speak voicechat-like using Lambda Players' voicelines", 0, 1, { type = "Bool", name = "Enable NPC Voice Chat", category = "NPC Voice Chat" } )

local vcAllowNPCs = CreateLambdaConvar( "lambdaplayers_npcvoicechat_allownpc", 1, true, false, false, "If standart NPCs or the ones that are based on them like ANP are allowed to use voicechat", 0, 1, { type = "Bool", name = "Allow Standart NPCs", category = "NPC Voice Chat" } )
local vcAllowVJBase = CreateLambdaConvar( "lambdaplayers_npcvoicechat_allowvjbase", 1, true, false, false, "If VJ Base SNPCs are allowed to use voicechat", 0, 1, { type = "Bool", name = "Allow VJ Base SNPCs", category = "NPC Voice Chat" } )
local vcAllowDrGBase = CreateLambdaConvar( "lambdaplayers_npcvoicechat_allowdrgbase", 1, true, false, false, "If DrGBase nextbots are allowed to use voicechat", 0, 1, { type = "Bool", name = "Allow DrGBase Nextbots", category = "NPC Voice Chat" } )
local vcAllowSanics = CreateLambdaConvar( "lambdaplayers_npcvoicechat_allowsanic", 1, true, false, false, "If 2D nextbots like Sanic or Obunga are allowed to use voicechat", 0, 1, { type = "Bool", name = "Allow 2D Nextbots", category = "NPC Voice Chat" } )

local vcIgnoreGagged = CreateLambdaConvar( "lambdaplayers_npcvoicechat_ignoregagged", 1, true, false, false, "If NPCs that are gagged aren't allowed to play voicelines until ungagged", 0, 1, { type = "Bool", name = "Ignore Gagged NPCs", category = "NPC Voice Chat" } )

local vcPitchMin = CreateLambdaConvar( "lambdaplayers_npcvoicechat_voicepitch_min", 100, true, false, false, "The highest pitch a NPC's voice can get upon spawning", 10, 100, { type = "Slider", decimals = 0, name = "Min Voice Pitch", category = "NPC Voice Chat" } )
local vcPitchMax = CreateLambdaConvar( "lambdaplayers_npcvoicechat_voicepitch_max", 100, true, false, false, "The lowest pitch a NPC's voice can get upon spawning", 100, 255, { type = "Slider", decimals = 0, name = "Max Voice Pitch", category = "NPC Voice Chat" } )
local vcProfileChance = CreateLambdaConvar( "lambdaplayers_npcvoicechat_voiceprofilechance", 0, true, false, false, "The chance the a NPC will use a random existing Lambda Voice Profile as their voice", 0, 100, { type = "Slider", decimals = 0, name = "Voice Profile Chance", category = "NPC Voice Chat" } )

local vcUseLambdaPfps = CreateLambdaConvar( "lambdaplayers_npcvoicechat_uselambdapfps", 1, true, false, false, "If NPCs should use Lambda Profile Pictures instead of their model's spawnmenu icon. Note: If NPC's model doesn't have a icon, it will fallback to Lambda Profiles instead", 0, 1, { type = "Bool", name = "Use Lambda Profile Pictures", category = "NPC Voice Chat" } )

local voicePfpList = { [ "None" ] = "" }
vcForceProfile = CreateLambdaConvar( "lambdaplayers_npcvoicechat_voiceprofile", "", true, false, false, "The Voice Profile every newly spawned NPC should spawn with. Note: This will override every player's client option with this one", 0, 1, { type = "Combo", options = voicePfpList, name = "Force Voice Profile", category = "NPC Voice Chat" } )
CreateLambdaConvar( "lambdaplayers_npcvoicechat_voiceprofile_client", "", true, true, true, "The Voice Profile your newly spawned NPC should spawn with. Note: This will only work if there's no voice profile specified serverside", 0, 1, { type = "Combo", options = voicePfpList, name = "Force Voice Profile", category = "NPC Voice Chat" } )

local vcGlobalVC = CreateLambdaConvar( "lambdaplayers_npcvoicechat_globalvoicechat", 0, true, true, false, "If the NPC voices can be heard globally", 0, 1, { type = "Bool", name = "Global Voice Chat", category = "NPC Voice Chat" } )
local vcPlayVol = CreateLambdaConvar( "lambdaplayers_npcvoicechat_playvolume", 1, true, true, false, "The sound volume of NPC voices", 0, 3, { type = "Slider", decimals = 2, name = "Sound Volume", category = "NPC Voice Chat" } )
local vcPlayDist = CreateLambdaConvar( "lambdaplayers_npcvoicechat_playdistance", 300, true, true, false, "Controls how far the NPC voices can be clearly heard from. Requires global voicechat to be disabled", 0, 2000, { type = "Slider", decimals = 0, name = "Sound Distance", category = "NPC Voice Chat" } )
local vcShowIcon = CreateLambdaConvar( "lambdaplayers_npcvoicechat_showvoiceicon", 1, true, true, false, "If a voice icon should appear above NPC while they're speaking?", 0, 1, { type = "Bool", name = "Show Voice Icon", category = "NPC Voice Chat" } )

local vcShowPopups = CreateLambdaConvar( "lambdaplayers_npcvoicechat_showpopups", 0, true, true, false, "Allows to draw and display a voicechat popup when NPCs are currently speaking", 0, 1, { type = "Bool", name = "Show Voice Popups", category = "NPC Voice Chat" } )
local vcPopupDist = CreateLambdaConvar( "lambdaplayers_npcvoicechat_popupdisplaydist", 0, true, true, false, "How close should the NPC be for its voice popup to show up? Set to zero to show up regardless of distance", 0, 2000, { type = "Slider", decimals = 0, name = "Popup Display Range", category = "NPC Voice Chat" } )
local vcPopupFadeTime = CreateLambdaConvar( "lambdaplayers_npcvoicechat_popupfadetime", 2, true, true, false, "Time in seconds needed for popup to fadeout after stopping playing or being out of range", 0, 5, { type = "Slider", decimals = 1, name = "Popup Fadeout Time", category = "NPC Voice Chat" } )

local vcAllowLines_Idle = CreateLambdaConvar( "lambdaplayers_npcvoicechat_allowlines_idle", 1, true, false, false, "If NPCs are allowed to play voicelines  while they are not in-combat", 0, 1, { type = "Bool", name = "Allow Idle Voicelines", category = "NPC Voice Chat" } )
local vcAllowLines_CombatIdle = CreateLambdaConvar( "lambdaplayers_npcvoicechat_allowlines_combatidle", 1, true, false, false, "If NPCs are allowed to play voicelines while they are in-combat", 0, 1, { type = "Bool", name = "Allow Combat Idle Voicelines", category = "NPC Voice Chat" } )
local vcAllowLines_Death = CreateLambdaConvar( "lambdaplayers_npcvoicechat_allowlines_death", 1, true, false, false, "If NPCs are allowed to play voicelines when they get killed", 0, 1, { type = "Bool", name = "Allow Death Voicelines", category = "NPC Voice Chat" } )
local vcAllowLines_SpotEnemy = CreateLambdaConvar( "lambdaplayers_npcvoicechat_allowlines_spotenemy", 1, true, false, false, "If NPCs are allowed to play voicelines when they first spot their enemy", 0, 1, { type = "Bool", name = "Allow Spot Enemy Voicelines", category = "NPC Voice Chat" } )
local vcAllowLines_KillEnemy = CreateLambdaConvar( "lambdaplayers_npcvoicechat_allowlines_killenemy", 1, true, false, false, "If NPCs are allowed to play voicelines when kill their enemy", 0, 1, { type = "Bool", name = "Allow Kill Enemy Voicelines", category = "NPC Voice Chat" } )
local vcAllowLines_AllyDeath = CreateLambdaConvar( "lambdaplayers_npcvoicechat_allowlines_allydeath", 1, true, false, false, "If NPCs are allowed to play voicelines when one of their allies gets killed", 0, 1, { type = "Bool", name = "Allow Ally Death Voicelines", category = "NPC Voice Chat" } )
local vcAllowLines_Assist = CreateLambdaConvar( "lambdaplayers_npcvoicechat_allowlines_assist", 1, true, false, false, "If NPCs are allowed to play voicelines when they get assisted by someone in some way, like one of their allies kills their enemy", 0, 1, { type = "Bool", name = "Allow Assist Voicelines", category = "NPC Voice Chat" } )
local vcAllowLines_SpotDanger = CreateLambdaConvar( "lambdaplayers_npcvoicechat_allowlines_spotdanger", 1, true, false, false, "If NPCs are allowed to play voicelines when they spot a danger like grenade and etc.", 0, 1, { type = "Bool", name = "Allow Spot Danger Voicelines", category = "NPC Voice Chat" } )
local vcAllowLines_CatchOnFire = CreateLambdaConvar( "lambdaplayers_npcvoicechat_allowlines_catchonfire", 1, true, false, false, "If NPCs are allowed to play voicelines when they catch on fire.", 0, 1, { type = "Bool", name = "Allow Catch On Fire Voicelines", category = "NPC Voice Chat" } )
local vcAllowLines_LowHealth = CreateLambdaConvar( "lambdaplayers_npcvoicechat_allowlines_lowhealth", 1, true, false, false, "If NPCs are allowed to play voicelines when they are low on health.", 0, 1, { type = "Bool", name = "Allow Low Health Voicelines", category = "NPC Voice Chat" } )

if ( CLIENT ) then
    local PlayFile = sound.PlayFile
    local EyeAngles = EyeAngles
    local RealTime = RealTime
    local LocalPlayer = LocalPlayer
    local cam = cam
    local surface = surface
    local table_remove = table.remove
    local table_Empty = table.Empty
    local max = math.max
    local RoundedBox = draw.RoundedBox
    local DrawText = draw.DrawText
    local SortedPairsByMemberValue = SortedPairsByMemberValue
    local Lerp = Lerp
    local RealTime = RealTime
    local ScrW = ScrW
    local ScrH = ScrH
    local Start3D2D = cam.Start3D2D
    local surface_SetDrawColor = surface.SetDrawColor
    local surface_SetMaterial = surface.SetMaterial
    local surface_DrawTexturedRect = surface.DrawTexturedRect
    local End3D2D = cam.End3D2D

    local voiceIconMat = Material( "voice/icntlk_pl" )
    local popup_BaseClr = Color( 255, 255, 255, 255 )
    local popup_BoxClr = Color( 0, 255, 0, 240 )
    local stereoWarn = GetConVar( "lambdaplayers_voice_warnvoicestereo" )
    local lambdaPopups = GetConVar( "lambdaplayers_voice_voicepopups" )
    local lambdaGmodPopups = GetConVar( "lambdaplayers_voice_usegmodvoicepopups" )

    NPCVC_SoundEmitters = {}
    NPCVC_VoicePopups = {}

    SimpleTimer( 0, function()
        for _, option in ipairs( _LAMBDAConVarSettings ) do
            if option.name != "Force Voice Profile" then continue end

            for pfpName, _ in pairs( LambdaVoiceProfiles ) do
                option.options[ pfpName ] = pfpName
            end
        end
    end )

    local function PlaySoundFile( sndDir, vcData, is3D )
        PlayFile( "sound/" .. sndDir, ( is3D and "3d" or "" ), function( snd, errorId, errorName )
            if errorId == 21 then
                if stereoWarn:GetBool() then 
                    print( "Lambda Players NPC Voice Chat Warning: Sound file " .. sndDir .. " has a stereo track and won't be played in 3D. Sound will continue to play. You can disable these warnings in Lambda Player>Utilities" ) 
                end

                PlaySoundFile( sndDir, vcData, false )
                return
            elseif !IsValid( snd ) then
                print( "Lambda Players NPC Voice Chat Error: Sound file " .. sndDir .. " failed to open!" )
                return
            end

            local ent = vcData.Emitter
            local sndLength = snd:GetLength()
            if sndLength <= 0 or !IsValid( ent ) then
                snd:Stop()
                snd = nil
                return
            end

            local playPos = ent:GetPos()
            snd:SetPos( playPos )

            local playRate = ( vcData.Pitch / 100 )
            snd:SetPlaybackRate( playRate )

            local volMult = vcData.VolumeMult
            snd:SetVolume( vcPlayVol:GetFloat() * volMult )
            snd:Set3DFadeDistance( vcPlayDist:GetInt() * max( volMult * 0.75, 1 ), 0 )

            NPCVC_SoundEmitters[ #NPCVC_SoundEmitters + 1 ] = {
                Entity = ent,
                Sound = snd,
                LastPlayPos = playPos,
                IconHeight = vcData.IconHeight,
                VolumeMult = volMult,
                Is3D = is3D,
                VoiceVolume = 0
            }

            local entIndex = vcData.EntIndex
            local voicePopup = NPCVC_VoicePopups[ entIndex ]
            if voicePopup then 
                voicePopup.Sound = snd
            else
                NPCVC_VoicePopups[ entIndex ] = {
                    Nick = vcData.Nickname,
                    Entity = ent,
                    Sound = snd,
                    LastPlayPos = playPos,
                    ProfilePicture = Material( vcData.ProfilePicture ),
                    VoiceVolume = 0,
                    AlphaRatio = 0,
                    LastPlayTime = 0,
                    FirstDisplayTime = 0
                }
            end

            net.Start( "npcsqueakers_sndduration" )
                net.WriteEntity( ent )
                net.WriteFloat( sndLength / playRate )
            net.SendToServer()
        end )
    end

    net.Receive( "npcsqueakers_playsound", function()
        local ent = net.ReadEntity()
        if !IsValid( ent ) then return end

        PlaySoundFile( net.ReadString(), {
            Emitter = ent,
            EntIndex = net.ReadUInt( 32 ),
            Pitch = net.ReadUInt( 8 ),
            IconHeight = net.ReadUInt( 12 ),
            VolumeMult = net.ReadFloat(),
            Nickname = net.ReadString(),
            ProfilePicture = net.ReadString()
        }, true )
    end )

    local function UpdateSounds()
        if #NPCVC_SoundEmitters == 0 then return end

        local enabled = vcEnabled:GetBool()
        local volume = vcPlayVol:GetFloat()
        local fadeDist = vcPlayDist:GetInt()
        local isGlobal = vcGlobalVC:GetBool()
        local plyPos = LocalPlayer():GetPos()

        for index, sndData in ipairs( NPCVC_SoundEmitters ) do
            local ent = sndData.Entity
            local snd = sndData.Sound

            if !IsValid( ent ) then
                if IsValid( snd ) then snd:Stop() end
                table_remove( NPCVC_SoundEmitters, index )
                continue
            end

            local removeEnt = ent:GetRemoveEntity()
            if !IsValid( snd ) or snd:GetState() == GMOD_CHANNEL_STOPPED or removeEnt != ent and !IsValid( removeEnt ) then
                net.Start( "npcsqueakers_removeent" )
                    net.WriteEntity( ent )
                net.SendToServer()

                if IsValid( snd ) then snd:Stop() end
                table_remove( NPCVC_SoundEmitters, index )
                continue
            end

            if enabled then
                local leftChan, rightChan = snd:GetLevel()
                sndData.VoiceVolume = ( ( leftChan + rightChan ) * 0.5 )

                local srcEnt = ent:GetSoundSource()
                local lastPos = sndData.LastPlayPos
                if IsValid( srcEnt ) then
                    lastPos = srcEnt:GetPos()
                    sndData.LastPlayPos = lastPos
                end

                if isGlobal then
                    snd:SetVolume( volume )
                    snd:Set3DEnabled( false )
                else
                    local volMult = sndData.VolumeMult
                    local sndVol = ( volume * volMult )

                    local is3D = sndData.Is3D
                    if is3D then
                        snd:Set3DEnabled( true )
                        snd:Set3DFadeDistance( fadeDist * max( volMult * 0.75, 1 ), 0 )
                        snd:SetPos( lastPos )
                    else
                        snd:Set3DEnabled( false )
                        sndVol = Clamp( sndVol / ( plyPos:DistToSqr( lastPos ) / ( fadeDist * fadeDist ) ), 0, 1 )
                    end

                    snd:SetVolume( sndVol )
                end
            else
                snd:SetVolume( 0 )
            end
        end
    end

    local function DrawVoiceIcons()
        if !vcEnabled:GetBool() or !vcShowIcon:GetBool() then return end

        for _, sndData in ipairs( NPCVC_SoundEmitters ) do
            local ang = EyeAngles()
            ang:RotateAroundAxis( ang:Up(), -90 )
            ang:RotateAroundAxis( ang:Forward(), 90 )

            local sndVol = sndData.VoiceVolume
            local pos = ( sndData.LastPlayPos + vector_up * sndData.IconHeight )
			
            Start3D2D( pos, ang, 1 )
                surface_SetDrawColor( 255, 255, 255 )
                surface_SetMaterial( voiceIconMat )
                surface_DrawTexturedRect( -8, -8, 16, 16 )
            End3D2D()
        end
    end

    local drawPopupIndexes = {}
    local function DrawVoiceChat()
        if !vcShowPopups:GetBool() or !vcEnabled:GetBool() then return end

        local plyPos = LocalPlayer():GetPos()
        local fadeoutTime = vcPopupFadeTime:GetFloat()
        local displayDist = vcPopupDist:GetInt()
        displayDist = ( displayDist * displayDist )

        local realTime = RealTime()
        table_Empty( drawPopupIndexes )
        for index, vcData in SortedPairsByMemberValue( NPCVC_VoicePopups, "FirstDisplayTime" ) do
            local ent = vcData.Entity
            local lastPos = vcData.LastPlayPos
            if IsValid( ent ) then 
                local srcEnt = ent:GetSoundSource()
                if IsValid( srcEnt ) then
                    lastPos = srcEnt:GetPos()
                    vcData.LastPlayPos = lastPos
                end
            end

            local sndVol = 0
            local snd = vcData.Sound
            if IsValid( snd ) then
                local leftChan, rightChan = snd:GetLevel()
                sndVol = ( ( leftChan + rightChan ) * 0.5 )

                if displayDist != 0 and plyPos:DistToSqr( lastPos ) > displayDist then
                    vcData.FirstDisplayTime = 0
                else
                    vcData.LastPlayTime = realTime

                    if vcData.FirstDisplayTime == 0 then
                        vcData.FirstDisplayTime = realTime
                    end 
                end
            end
            vcData.VoiceVolume = sndVol

            local drawAlpha = max( 0, 1 - ( ( realTime - vcData.LastPlayTime ) / fadeoutTime ) )
            if IsValid( snd ) and drawAlpha != 0 then
                drawAlpha = Lerp( 0.5, vcData.AlphaRatio, drawAlpha )
            end
            if !IsValid( snd ) and drawAlpha == 0 then
                NPCVC_VoicePopups[ index ] = nil
                continue
            end

            vcData.AlphaRatio = drawAlpha
            if drawAlpha == 0 then continue end

            drawPopupIndexes[ index ] = vcData
        end

        local playerPopups = #g_VoicePanelList:GetChildren()
        if lambdaPopups:GetBool() and !lambdaGmodPopups:GetBool() then 
            playerPopups = ( playerPopups + #_LAMBDAPLAYERS_Voicechannels ) 
        end
        local drawX, drawY = ( ScrW() - 298 ), ( ScrH() - 142 )
        drawY = ( drawY - ( 44 * playerPopups ) )

        for _, vcData in SortedPairsByMemberValue( drawPopupIndexes, "FirstDisplayTime" ) do
            local drawAlpha = vcData.AlphaRatio
            popup_BaseClr.a = ( drawAlpha * 255 )
            popup_BoxClr.a = ( drawAlpha * 240 )
            
            local vol = ( vcData.VoiceVolume * drawAlpha )
            popup_BoxClr.g = ( vol * 255 )

            RoundedBox( 4, drawX, drawY, 246, 40, popup_BoxClr )
            surface_SetDrawColor( popup_BaseClr )
            surface_SetMaterial( vcData.ProfilePicture )
            surface_DrawTexturedRect( drawX + 4, drawY + 4, 32, 32 )

            local nickname = vcData.Nick
            if #nickname > 23 then 
                nickname = string_sub( nickname, 0, 20 ) .. "..." 
            end
            DrawText( nickname, "GModNotify", drawX + 43.5, drawY + 9, popup_BaseClr, TEXT_ALIGN_LEFT )

            drawY = ( drawY - 44 )
        end
    end

    local function OnCreateClientsideRagdoll( owner, ragdoll )
        SimpleTimer( 0.1, function()
            if !IsValid( owner ) or !IsValid( ragdoll ) then return end

            local sndEmitter = owner:GetNW2Entity( "npcsqueakers_sndemitter" )
            if !IsValid( sndEmitter ) then return end

            sndEmitter:SetSoundSource( ragdoll )
            sndEmitter:SetRemoveEntity( ragdoll )
        end )
    end

    hook.Add( "Tick", "NPCSqueakers_UpdateSounds", UpdateSounds )
    hook.Add( "PreDrawEffects", "NPCSqueakers_DrawVoiceIcons", DrawVoiceIcons )
    hook.Add( "HUDPaint", "NPCSqueakers_DrawVoiceChat", DrawVoiceChat )
    hook.Add( "CreateClientsideRagdoll", "NPCSqueakers_OnCreateClientsideRagdoll", OnCreateClientsideRagdoll )
end

if ( SERVER ) then
    local Rand = math.Rand
    local ents_GetAll = ents.GetAll
    local CurTime = CurTime
	local ents_Create = ents.Create
    local table_GetKeys = table.GetKeys
    local table_Copy = table.Copy
    local table_RemoveByValue = table.RemoveByValue
    local FindInSphere = ents.FindInSphere
    local IsSinglePlayer = game.SinglePlayer

    local nextNPCSoundThink = 0
    local noWepFearNPCs = {
        [ "npc_alyx" ]    = true,
        [ "npc_barney" ]  = true,
        [ "npc_citizen" ] = true,
        [ "npc_dog" ]     = true,
        [ "npc_kleiner" ] = true,
        [ "npc_mossman" ] = true,
        [ "npc_eli" ]     = true,
        [ "npc_monk" ]    = true,
    }
    local nonNPCNPCs = {
        [ "npc_bullseye" ] = true,
        [ "npc_enemyfinder" ] = true
    }
    local drownNPCs = {
        [ "npc_headcrab" ] = true,
        [ "npc_headcrab_black" ] = true,
        [ "npc_headcrab_fast" ] = true,
        [ "npc_antlion" ] = true
    }
    local aiDisabled = GetConVar( "ai_disabled" )
    local ignorePlys = GetConVar( "ai_ignoreplayers" )

	local nextbotMETA = FindMetaTable("NextBot")
    NPCVC_OldFunc_BecomeRagdoll = NPCVC_OldFunc_BecomeRagdoll or nextbotMETA.BecomeRagdoll

    function nextbotMETA:BecomeRagdoll( dmginfo )
        local ragdoll = NPCVC_OldFunc_BecomeRagdoll( self, dmginfo )
        if self.IsDrGNextbot and IsValid( ragdoll ) then
            local sndEmitter = self:GetNW2Entity( "npcsqueakers_sndemitter" )
            if IsValid( sndEmitter ) then
                sndEmitter:SetSoundSource( ragdoll )
                sndEmitter:SetRemoveEntity( ragdoll )
            end
        end
        return ragdoll
    end

    util.AddNetworkString( "npcsqueakers_playsound" )
    util.AddNetworkString( "npcsqueakers_sndduration" )

    net.Receive( "npcsqueakers_sndduration", function()
        local ent = net.ReadEntity()
        if !IsValid( ent ) then return end

        local npc = ent:GetOwner()
        if !IsValid( npc ) then return end
        npc.l_NPCVC_SpeechPlayTime = ( CurTime() + net.ReadFloat() )
    end )

    duplicator.RegisterEntityModifier( "Lambda NPC VoiceChat - NPC's Voice Data", function( ply, ent, data )
        ent.l_NPCVC_IsDuplicated = true
        ent.l_NPCVC_SpeechChance = data.SpeechChance
        ent.l_NPCVC_VoicePitch = data.VoicePitch
        ent.l_NPCVC_Nickname = data.NickName
        ent.l_NPCVC_VoiceProfile = data.VoiceProfile
        ent.l_NPCVC_ProfilePicture = data.ProfilePicture
    end )

    local function GetVoiceLine( ent, voiceType )
        local voicePfp = LambdaVoiceProfiles[ ent.l_NPCVC_VoiceProfile ]
        if voicePfp then
            local voiceTbl = voicePfp[ voiceType ]
            if voiceTbl and #voiceTbl != 0 then
                return voiceTbl[ random( #voiceTbl ) ]
            end
        end

        local voiceTbl = LambdaVoiceLinesTable[ voiceType ]
        return voiceTbl[ random( #voiceTbl ) ]
    end

    local function PlaySoundFile( npc, voiceType, dontDeleteOnRemove )
        if !npc.l_NPCVC_Initialized then return end
        if npc.LastPathingInfraction and !vcAllowSanics:GetBool() then return end
        if npc.IsDrGNextbot and ( npc:IsPossessed() or !vcAllowDrGBase:GetBool() ) then return end
        if npc.IsVJBaseSNPC then
            if npc.VJ_IsBeingControlled or npc:GetState() != 0 or !vcAllowVJBase:GetBool() then return end
        elseif npc:IsNPC() and !vcAllowNPCs:GetBool() then 
            return 
        end
        if vcIgnoreGagged:GetBool() and npc:HasSpawnFlags( SF_NPC_GAG ) then return end

        local sndEmitter = ents_Create( "lambda_npcvc_sndemitter" )
        sndEmitter:SetPos( npc:GetPos() )
        sndEmitter:SetOwner( npc )
        sndEmitter.DontRemoveEntity = dontDeleteOnRemove
        sndEmitter:Spawn()

        if !IsSinglePlayer() then
            SimpleTimer( 0.1, function()
                if !IsValid( sndEmitter ) then return end
                
                if !IsValid( npc ) then 
                    sndEmitter:Remove()
                    return 
                end

                net.Start( "npcsqueakers_playsound" )
                    net.WriteEntity( sndEmitter )
                    net.WriteString( GetVoiceLine( npc, voiceType ) )
                    net.WriteUInt( npc:GetCreationID(), 32 )
                    net.WriteUInt( npc.l_NPCVC_VoicePitch, 8 )
                    net.WriteUInt( npc.l_NPCVC_VoiceIconHeight, 12 )
                    net.WriteFloat( npc.l_NPCVC_VoiceVolumeScale )
                    net.WriteString( npc.l_NPCVC_Nickname )
                    net.WriteString( npc.l_NPCVC_ProfilePicture )
                net.Broadcast()
            end )
        else
            net.Start( "npcsqueakers_playsound" )
                net.WriteEntity( sndEmitter )
                net.WriteString( GetVoiceLine( npc, voiceType ) )
                net.WriteUInt( npc:GetCreationID(), 32 )
                net.WriteUInt( npc.l_NPCVC_VoicePitch, 8 )
                net.WriteUInt( npc.l_NPCVC_VoiceIconHeight, 12 )
                net.WriteFloat( npc.l_NPCVC_VoiceVolumeScale )
                net.WriteString( npc.l_NPCVC_Nickname )
                net.WriteString( npc.l_NPCVC_ProfilePicture )
            net.Broadcast()
        end

        local oldEmitter = npc:GetNW2Entity( "npcsqueakers_sndemitter" )
        if IsValid( oldEmitter ) then oldEmitter:Remove() end

        npc.l_NPCVC_LastVoiceLine = voiceType
        npc:SetNW2Entity( "npcsqueakers_sndemitter", sndEmitter )
    end

    local function IsSpeaking( npc, voiceType )
        return ( ( !voiceType or npc.l_NPCVC_LastVoiceLine == voiceType ) and CurTime() < npc.l_NPCVC_SpeechPlayTime )
    end

    local function GetOpenLambdaName()
        local nameListCopy = table_Copy( LambdaPlayerNames )
        for _, v in ipairs( ents_GetAll() ) do
            if v == self or !IsValid( v ) or !v.IsLambdaPlayer and !v.l_NPCVC_Initialized then continue end
            table_RemoveByValue( nameListCopy, ( v.IsLambdaPlayer and v:GetLambdaName() or v.l_NPCVC_Nickname ) )
        end
        
        local rndName = nameListCopy[ random( #nameListCopy ) ]
        return ( rndName and rndName or LambdaPlayerNames[ random( #LambdaPlayerNames ) ] )
    end

    local function CheckNearbyNPCOnDeath( ent, attacker )
        local entPos = ent:GetPos()

        local attackPos
        if IsValid( attacker ) and ( attacker:IsPlayer() or attacker:IsNPC() or attacker:IsNextBot() ) then
            attackPos = attacker:GetPos()
        end

        for _, npc in ipairs( FindInSphere( entPos, 1500 ) ) do
            if npc == ent or !IsValid( npc ) or !npc.l_NPCVC_Initialized or npc.LastPathingInfraction or random( 1, 100 ) > npc.l_NPCVC_SpeechChance or IsSpeaking( npc ) then continue end

            if npc:Disposition( ent ) == D_LI and vcAllowLines_AllyDeath:GetBool() and ( entPos:DistToSqr( npc:GetPos() ) <= 90000 or npc:Visible( ent ) ) then
                PlaySoundFile( npc, ( random( 1, 4 ) == 1 and "witness" or "panic" ) )
                continue
            end

            if attacker == npc then
                if vcAllowLines_KillEnemy:GetBool() and npc:GetEnemy() == ent then
                    PlaySoundFile( npc, ( random( 1, 6 ) == 1 and "laugh" or "kill" ) )
                    continue
                end
            elseif attackPos and npc:Disposition( attacker ) != D_HT and vcAllowLines_Assist:GetBool() and ( attackPos:DistToSqr( npc:GetPos() ) <= 90000 or npc:Visible( attacker ) ) then
                local isEnemy = ( npc:GetEnemy() == ent )
                if !isEnemy and npc:IsNPC() then
                    for _, knownEne in ipairs( npc:GetKnownEnemies() ) do
                        isEnemy = ( knownEne == ent )
                        if isEnemy then break end
                    end
                end
                if isEnemy then
                    PlaySoundFile( npc, "assist" )
                    continue
                end
            end
        end
    end

    local function OnEntityCreated( npc )
		SimpleTimer( 0, function()
			if !IsValid( npc ) or !npc.IsDrGNextbot and !npc.LastPathingInfraction and ( !npc:IsNPC() or nonNPCNPCs[ npc:GetClass() ] ) then return end

            npc.l_NPCVC_Initialized = true
            npc.l_NPCVC_LastEnemy = NULL
            npc.l_NPCVC_IsLowHealth = false
            npc.l_NPCVC_WasOnFire = false
            npc.l_NPCVC_IsSelfDestructing = false
            npc.l_NPCVC_LastState = -1
            npc.l_NPCVC_LastTakeDamageTime = 0
            npc.l_NPCVC_LastSeenEnemyTime = 0
			npc.l_NPCVC_NextIdleSpeak = ( CurTime() + Rand( 3, 8 ) )
            npc.l_NPCVC_NextDangerSoundTime = 0
            npc.l_NPCVC_SpeechPlayTime = 0
            npc.l_NPCVC_LastVoiceLine = ""

            if !npc.LastPathingInfraction then
                local height = npc:OBBMaxs().z
                npc.l_NPCVC_VoiceIconHeight = ( height + 10 )
                npc.l_NPCVC_VoiceVolumeScale = Clamp( ( height / 72 ), 0.5, 2.5 )
            else
                npc.l_NPCVC_VoiceIconHeight = 138
                npc.l_NPCVC_VoiceVolumeScale = 2
            end

            if !npc.l_NPCVC_IsDuplicated then
                local speechChance = random( 0, 100 )
                npc.l_NPCVC_SpeechChance = speechChance
                
                local voicePitch = random( vcPitchMin:GetInt(), vcPitchMax:GetInt() )
                npc.l_NPCVC_VoicePitch = voicePitch
                
                local openName = GetOpenLambdaName()
                npc.l_NPCVC_Nickname = openName

                local voicePfp = nil
                local serverPfp = vcForceProfile:GetString()
                if serverPfp != "" then
                    voicePfp = serverPfp
                    npc.l_NPCVC_IsVoiceProfileServerside = true
                elseif random( 1, 100 ) <= vcProfileChance:GetInt() then
                    local voicePfps = table_GetKeys( LambdaVoiceProfiles ) 
                    voicePfp = voicePfps[ random( #voicePfps ) ] 
                end
                npc.l_NPCVC_VoiceProfile = voicePfp

                local profilePic = nil
                local mdlDir = npc:GetModel()
                local mdlIcon = ( mdlDir and "spawnicons/".. string_sub( mdlDir, 1, #mdlDir - 4 ).. ".png" )
                if vcUseLambdaPfps:GetBool() or !mdlIcon or !file.Exists( "materials/" .. mdlIcon, "MOD" ) then
                    profilePic = Lambdaprofilepictures[ random( #Lambdaprofilepictures ) ]
                else
                    profilePic = mdlIcon
                end
                npc.l_NPCVC_ProfilePicture = profilePic

                duplicator.StoreEntityModifier( npc, "Lambda NPC VoiceChat - NPC's Voice Data", {
                    SpeechChance = speechChance,
                    VoicePitch = voicePitch,
                    NickName = openName,
                    VoiceProfile = voicePfp,
                    ProfilePicture = profilePic
                } )
            end

            if npc.IsVJBaseSNPC then
                local old_PlaySoundSystem = npc.PlaySoundSystem

                function npc:PlaySoundSystem( sdSet, customSd, sdType )
                    if sdSet == "OnDangerSight" or sdSet == "OnGrenadeSight" and vcAllowLines_SpotDanger:GetBool() then
                        PlaySoundFile( npc, "panic" )
                    elseif random( 1, 100 ) <= npc.l_NPCVC_SpeechChance and !IsSpeaking( npc ) then
                        if sdSet == "MedicReceiveHeal" and vcAllowLines_Assist:GetBool() then
                            PlaySoundFile( npc, "assist" )
                        end
                    end

                    old_PlaySoundSystem( npc, sdSet, customSd, sdType )
                end
            end
        end )
	end

    local function OnPlayerSpawnedNPC( ply, npc )
        SimpleTimer( 0, function()
            if !IsValid( npc ) or !npc.l_NPCVC_Initialized or npc.l_NPCVC_IsDuplicated then return end

            if !npc.l_NPCVC_IsVoiceProfileServerside then
                local voicePfp = ply:GetInfo( "lambdaplayers_npcvoicechat_voiceprofile_client" )
                if voicePfp and voicePfp != "" then
                    npc.l_NPCVC_VoiceProfile = voicePfp

                    duplicator.StoreEntityModifier( npc, "Lambda NPC VoiceChat - NPC's Voice Data", {
                        SpeechChance = npc.l_NPCVC_SpeechChance,
                        VoicePitch = npc.l_NPCVC_VoicePitch,
                        NickName = npc.l_NPCVC_Nickname,
                        VoiceProfile = voicePfp,
                        ProfilePicture = npc.l_NPCVC_ProfilePicture
                    } )
                end
            end
        end )
    end

    local function OnNPCKilled( npc, attacker, inflictor )
        if vcAllowLines_Death:GetBool() then
            PlaySoundFile( npc, "death", true )
        end

        CheckNearbyNPCOnDeath( npc, attacker )
    end

    local function OnPlayerDeath( ply, inflictor, attacker )
        if ignorePlys:GetBool() then return end

        SimpleTimer( 0.1, function()
            CheckNearbyNPCOnDeath( ply, attacker )
        end )
    end

    local function OnCreateEntityRagdoll( owner, ragdoll )
        local sndEmitter = owner:GetNW2Entity( "npcsqueakers_sndemitter" )
        if !IsValid( sndEmitter ) then return end

        sndEmitter:SetSoundSource( ragdoll )
        sndEmitter:SetRemoveEntity( ragdoll )
    end

    local function OnServerThink()
        local curTime = CurTime()
        if curTime < nextNPCSoundThink then return end

        nextNPCSoundThink = ( curTime + 0.1 )
        if aiDisabled:GetBool() then return end

        for _, npc in ipairs( ents_GetAll() ) do
            if !IsValid( npc ) or !npc.l_NPCVC_Initialized then continue end

            if npc:GetClass() == "npc_turret_floor" then 
                local selfDestructing = npc:GetInternalVariable( "m_bSelfDestructing" )
                if !selfDestructing then 
                    local curState = npc:GetNPCState()
                    local lastState = npc.l_NPCVC_LastState
                    if curState != lastState then
                        if lastState == NPC_STATE_DEAD then
                            PlaySoundFile( npc, "assist" )
                        elseif curState == NPC_STATE_DEAD then
                            PlaySoundFile( npc, "panic" )
                        elseif curState == NPC_STATE_COMBAT then
                            PlaySoundFile( npc, "taunt" )
                        end
                    end
                    npc.l_NPCVC_LastState = curState

                    local curEnemy = npc:GetEnemy()
                    local lastEnemy = npc.l_NPCVC_LastEnemy
                    if curEnemy != lastEnemy and IsValid( curEnemy ) then
                        PlaySoundFile( npc, "taunt" )
                    end
                    npc.l_NPCVC_LastEnemy = curEnemy
                elseif !npc.l_NPCVC_IsSelfDestructing then
                    npc.l_NPCVC_IsSelfDestructing = true

                    SimpleTimer( Rand( 0.8, 1.25 ), function()
                        if !IsValid( npc ) then return end
                        PlaySoundFile( npc, "panic" )
                    end )

                    SimpleTimer( Rand( 2, 3.5 ), function()
                        if !IsValid( npc ) then return end
                        PlaySoundFile( npc, "fall" )
                    end )
                end
            else
                local curEnemy
                local rolledSpeech = ( random( 1, 100 ) <= npc.l_NPCVC_SpeechChance )

                if npc.LastPathingInfraction then
                    curEnemy = npc.CurrentTarget

                    local isVisible = false
                    local lastSeenTime = npc.l_NPCVC_LastSeenEnemyTime
                    if !IsValid( curEnemy ) then
                        npc.l_NPCVC_LastSeenEnemyTime = 0
                    elseif npc:GetRangeSquaredTo( curEnemy ) <= 1000000 and npc:Visible( curEnemy ) then
                        isVisible = true
                        npc.l_NPCVC_LastSeenEnemyTime = curTime
                    end

                    if rolledSpeech then
                        if lastSeenTime == 0 and isVisible and vcAllowLines_SpotEnemy:GetBool() then
                            PlaySoundFile( npc, "taunt" )
                        elseif curTime >= npc.l_NPCVC_NextIdleSpeak and !IsSpeaking( npc ) then
                            if ( curTime - npc.l_NPCVC_LastSeenEnemyTime ) <= 5 and IsValid( curEnemy ) then
                                if vcAllowLines_CombatIdle:GetBool() then
                                    PlaySoundFile( npc, "taunt" )
                                end
                            elseif vcAllowLines_Idle:GetBool() then
                                PlaySoundFile( npc, "idle" )
                            end
                        end
                    end
                elseif !npc:IsEFlagSet( EFL_IS_BEING_LIFTED_BY_BARNACLE ) and npc:GetInternalVariable( "m_lifeState" ) == 0 then 
                    local onFire = ( drownNPCs[ npc:GetClass() ] and npc:WaterLevel() >= 2 or npc:IsOnFire() )
                    if onFire and !npc.l_NPCVC_WasOnFire and vcAllowLines_CatchOnFire:GetBool() then
                        PlaySoundFile( npc, "panic" )
                    end
                    npc.l_NPCVC_WasOnFire = onFire

                    local lowHP = npc.l_NPCVC_IsLowHealth
                    if !lowHP then
                        local hpThreshold = Rand( 0.2, 0.5 )
                        if npc:Health() <= ( npc:GetMaxHealth() * hpThreshold ) then
                            npc.l_NPCVC_IsLowHealth = hpThreshold

                            if rolledSpeech and ( curTime - npc.l_NPCVC_LastTakeDamageTime ) <= 5 and vcAllowLines_LowHealth:GetBool() then
                                PlaySoundFile( npc, "panic" )
                            end
                        end
                    elseif npc:Health() > ( npc:GetMaxHealth() * lowHP ) then
                        npc.l_NPCVC_IsLowHealth = false
                    end

                    curEnemy = npc:GetEnemy()
                    local lastEnemy = npc.l_NPCVC_LastEnemy
                    local isPanicking = ( npc.l_NPCVC_WasOnFire or !npc.IsDrGNextbot and IsValid( curEnemy ) and curEnemy.LastPathingInfraction )
                    if npc.IsVJBaseSNPC or npc.IsDrGNextbot then
                        if rolledSpeech then
                            if !isPanicking then
                                isPanicking = ( isPanicking or ( npc.NoWeapon_UseScaredBehavior and !IsValid( npc:GetActiveWeapon() ) ) )
                            end

                            local spotLine = ( ( !isPanicking and ( !lowHP or random( 1, 3 ) != 1 ) ) and "taunt" or "panic" )                            
                            if curEnemy != lastEnemy then
                                if IsValid( curEnemy ) and !IsValid( lastEnemy ) and vcAllowLines_SpotEnemy:GetBool() then
                                    PlaySoundFile( npc, spotLine )
                                end
                            elseif curTime >= npc.l_NPCVC_NextIdleSpeak and !IsSpeaking( npc ) then
                                if IsValid( curEnemy ) then
                                    if vcAllowLines_CombatIdle:GetBool() then
                                        PlaySoundFile( npc, spotLine )
                                    end
                                elseif vcAllowLines_Idle:GetBool() then
                                    PlaySoundFile( npc, "idle" )
                                end
                            end
                        end
                    else
                        if curTime >= npc.l_NPCVC_NextDangerSoundTime and ( npc:HasCondition( 50 ) or npc:HasCondition( 57 ) or npc:HasCondition( 58 ) ) and vcAllowLines_SpotDanger:GetBool() then
                            PlaySoundFile( npc, "panic" )
                            npc.l_NPCVC_NextDangerSoundTime = ( curTime + 5 )
                        end

                        local curState = npc:GetNPCState()
                        if rolledSpeech then
                            if !isPanicking then
                                isPanicking = ( IsValid( curEnemy ) and ( noWepFearNPCs[ npc:GetClass() ] and !IsValid( npc:GetActiveWeapon() ) or npc:Disposition( curEnemy ) == D_FR ) )
                            end

                            local spotLine = ( ( !isPanicking and ( !lowHP or random( 1, 3 ) != 1 ) ) and "taunt" or "panic" )                            
                            if curState != npc.l_NPCVC_LastState then
                                if curState == NPC_STATE_COMBAT and !IsValid( lastEnemy ) and vcAllowLines_SpotEnemy:GetBool() then
                                    PlaySoundFile( npc, spotLine )
                                end
                            elseif curTime >= npc.l_NPCVC_NextIdleSpeak and !IsSpeaking( npc ) then
                                if curState == NPC_STATE_COMBAT then
                                    if vcAllowLines_CombatIdle:GetBool() then
                                        PlaySoundFile( npc, spotLine )
                                    end
                                elseif ( curState == NPC_STATE_IDLE or curState == NPC_STATE_ALERT ) and vcAllowLines_Idle:GetBool() then
                                    PlaySoundFile( npc, "idle" )
                                end
                            end
                        end
                        npc.l_NPCVC_LastState = curState
                    end
                end

                npc.l_NPCVC_LastEnemy = curEnemy
                if curTime >= npc.l_NPCVC_NextIdleSpeak then
                    npc.l_NPCVC_NextIdleSpeak = ( curTime + Rand( 3, 8 ) )
                end
            end
        end
    end

    local function OnPostEntityTakeDamage( ent, dmginfo, tookDamage )
        if !tookDamage or !ent.l_NPCVC_Initialized then return end
        ent.l_NPCVC_LastTakeDamageTime = CurTime()
    end

    hook.Add( "OnEntityCreated", "NPCSqueakers_OnEntityCreated", OnEntityCreated )
    hook.Add( "PlayerSpawnedNPC", "NPCSqueakers_OnPlayerSpawnedNPC", OnPlayerSpawnedNPC )
    hook.Add( "OnNPCKilled", "NPCSqueakers_OnNPCKilled", OnNPCKilled )
    hook.Add( "PlayerDeath", "NPCSqueakers_OnPlayerDeath", OnPlayerDeath )
    hook.Add( "CreateEntityRagdoll", "NPCSqueakers_OnCreateEntityRagdoll", OnCreateEntityRagdoll )
    hook.Add( "Think", "NPCSqueakers_OnServerThink", OnServerThink )
    hook.Add( "PostEntityTakeDamage", "NPCSqueakers_OnPostEntityTakeDamage", OnPostEntityTakeDamage )
end