local net = net
local ipairs = ipairs
local pairs = pairs
local SortedPairs = SortedPairs
local IsValid = IsValid
local SimpleTimer = timer.Simple
local random = math.random
local string_sub = string.sub
local Clamp = math.Clamp
local table_Empty = table.Empty
local RealTime = RealTime
local PlayFile = sound.PlayFile
local EyeAngles = EyeAngles
local LocalPlayer = LocalPlayer
local cam = cam
local surface = surface
local table_remove = table.remove
local max = math.max
local GetConVar = GetConVar
local RoundedBox = draw.RoundedBox
local DrawText = draw.DrawText
local SortedPairsByMemberValue = SortedPairsByMemberValue
local Lerp = Lerp
local Material = Material
local ScrW = ScrW
local ScrH = ScrH
local Start3D2D = cam.Start3D2D
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetMaterial = surface.SetMaterial
local surface_DrawRect = surface.DrawRect
local surface_DrawTexturedRect = surface.DrawTexturedRect
local End3D2D = cam.End3D2D
local file_Find = file.Find

local voiceIconMat      = Material( "voice/icntlk_pl" )
local popup_BaseClr     = Color( 255, 255, 255, 255 )
local popup_BoxClr      = Color( 0, 255, 0, 240 )

local vcEnabled         = CreateConVar( "sv_npcvoicechat_enabled", "1", ( FCVAR_ARCHIVE + FCVAR_REPLICATED ), "Allows to NPCs and nextbots to able to speak voicechat-like using Lambda Players' voicelines", 0, 1 )
local vcGlobalVC        = CreateClientConVar( "cl_npcvoicechat_globalvoicechat", "0", nil, nil, "If the NPC voices can be heard globally", 0, 1 )
local vcPlayVol         = CreateClientConVar( "cl_npcvoicechat_playvolume", "1", nil, nil, "The sound volume of NPC voices", 0 )
local vcPlayDist        = CreateClientConVar( "cl_npcvoicechat_playdistance", "300", nil, nil, "Controls how far the NPC voices can be clearly heard from. Requires global voicechat to be disabled", 0 )
local vcShowIcon        = CreateClientConVar( "cl_npcvoicechat_showvoiceicon", "1", nil, nil, "If a voice icon should appear above NPC while they're speaking?", 0, 1 )
local vcShowPopups      = CreateClientConVar( "cl_npcvoicechat_showpopups", "0", nil, nil, "Allows to draw and display a voicechat popup when NPCs are currently speaking", 0, 1 )
local vcPopupDist       = CreateClientConVar( "cl_npcvoicechat_popupdisplaydist", "0", nil, nil, "How close should the NPC be for its voice popup to show up? Set to zero to show up regardless of distance", 0 )
local vcPopupFadeTime   = CreateClientConVar( "cl_npcvoicechat_popupfadetime", "2", nil, nil, "Time in seconds needed for popup to fadeout after stopping playing or being out of range", 0, 5 )

local vcPopupColorR     = CreateClientConVar( "cl_npcvoicechat_popupcolor_r", "0", nil, nil, "The red color of voice popup when the NPC is using it", 0, 255 )
local vcPopupColorG     = CreateClientConVar( "cl_npcvoicechat_popupcolor_g", "255", nil, nil, "The green color of voice popup when the NPC is using it", 0, 255 )
local vcPopupColorB     = CreateClientConVar( "cl_npcvoicechat_popupcolor_b", "0", nil, nil, "The blue color of voice popup when the NPC is using it", 0, 255 )

CreateClientConVar( "cl_npcvoicechat_lambdavoicepfp", "", nil, true, "The Lambda Voice Profile your newly created NPC should be spawned with. Note: This will only work if there's no voice profile specified serverside" )

NPCVC_SoundEmitters         = {}
NPCVC_VoicePopups           = {}
NPCVC_LambdaVoiceProfile    = {}

local function UpdateVoiceProfiles()
    if LambdaVoiceProfiles then
        NPCVC_LambdaVoiceProfile = LambdaVoiceProfiles
        return
    end

    table_Empty( NPCVC_LambdaVoiceProfile )
    local _, lambdaVPs = file_Find( "sound/lambdaplayers/voiceprofiles/*", "GAME" )
    
    for _, voicePfp in ipairs( lambdaVPs ) do
        NPCVC_LambdaVoiceProfile[ voicePfp ] = {}

        for voiceType, _ in pairs( voicelineDirs ) do 
            local voicelines = file_Find( "sound/lambdaplayers/voiceprofiles/" .. voicePfp .. "/" .. voiceType .. "/*", "GAME" )
            if !voicelines or #voicelines == 0 then continue end

            NPCVC_LambdaVoiceProfile[ voicePfp ][ voiceType ] = {}
            for _, voiceline in ipairs( voicelines ) do
                table_insert( NPCVC_LambdaVoiceProfile[ voicePfp ][ voiceType ], "lambdaplayers/voiceprofiles/" .. voicePfp .. "/" .. voiceType .. "/" .. voiceline )
            end
        end
    end
end
SimpleTimer( 0, UpdateVoiceProfiles )

local function PlaySoundFile( sndDir, vcData, is3D )
    local ent = vcData.Emitter
    if !IsValid( ent ) then return end

    PlayFile( "sound/" .. sndDir, ( is3D and "3d" or "" ), function( snd, errorId, errorName )
        if errorId == 21 then
            PlaySoundFile( sndDir, vcData, false )
            return
        elseif !IsValid( snd ) then
            print( "NPC Voice Chat Error: Sound file " .. sndDir .. " failed to open!" )
            return
        end

        local sndLength = snd:GetLength()
        if sndLength <= 0 or !IsValid( ent ) then
            snd:Stop()
            snd = nil
            return
        end

        local srcEnt = ( ent.GetSoundSource and ent:GetSoundSource() )
        local playPos = ( IsValid( srcEnt ) and srcEnt:GetPos() or ent:GetPos() )
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
            local pfpPic = vcData.ProfilePicture
            if pfpPic then
                pfpPic = Material( pfpPic )
                if pfpPic and pfpPic:IsError() then pfpPic = nil end
            end

            NPCVC_VoicePopups[ entIndex ] = {
                Nick = vcData.Nickname,
                Entity = ent,
                Sound = snd,
                LastPlayPos = playPos,
                ProfilePicture = pfpPic,
                PfpBackgroundColor = vcData.PfpBackgroundColor,
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
    PlaySoundFile( net.ReadString(), net.ReadTable(), true )
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
                    snd:SetPos( lastPos )

                    local hearDist = ( fadeDist * max( volMult * 0.75, 1 ) )
                    snd:Set3DFadeDistance( hearDist, ( hearDist * 3 ) )
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

    local canDrawSomething = false
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

        canDrawSomething = true
        drawPopupIndexes[ index ] = vcData
    end

    if !canDrawSomething then return end
    local drawX, drawY = ( ScrW() - 298 ), ( ScrH() - 142 )
    drawY = ( drawY - ( 44 * #g_VoicePanelList:GetChildren() ) )

    local popupClrR = vcPopupColorR:GetInt()
    local popupClrG = vcPopupColorG:GetInt()
    local popupClrB = vcPopupColorB:GetInt()

    for _, vcData in SortedPairsByMemberValue( drawPopupIndexes, "FirstDisplayTime" ) do
        local drawAlpha = vcData.AlphaRatio
        popup_BaseClr.a = ( drawAlpha * 255 )

        local vol = ( vcData.VoiceVolume * drawAlpha )
        popup_BoxClr.r = ( vol * popupClrR )
        popup_BoxClr.g = ( vol * popupClrG )
        popup_BoxClr.b = ( vol * popupClrB )
        popup_BoxClr.a = ( drawAlpha * 240 )

        RoundedBox( 4, drawX, drawY, 246, 40, popup_BoxClr )
        
        local bgClr = vcData.PfpBackgroundColor
        if bgClr then
            bgClr.a = popup_BaseClr.a
            surface_SetDrawColor( bgClr )
            surface_DrawRect( drawX + 4, drawY + 4, 32, 32 )
        end
        local pfp = vcData.ProfilePicture
        if pfp then
            surface_SetDrawColor( popup_BaseClr )
            surface_SetMaterial( pfp )
            surface_DrawTexturedRect( drawX + 4, drawY + 4, 32, 32 )
        end

        local nickname = vcData.Nick
        if #nickname > 20 then 
            nickname = string_sub( nickname, 0, 17 ) .. "..." 
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

local function AddToolMenuTabs()
    spawnmenu.AddToolCategory( "Utilities", "YerSoMashy", "YerSoMashy" )
end

local clientColor = Color( 255, 145, 0 )
local function ClientControlHelp( panel, text )
    local help = panel:ControlHelp( text )
    help:SetTextColor( clientColor )
end

local function PopulateToolMenu()
    spawnmenu.AddToolMenuOption( "Utilities", "YerSoMashy", "NPCSqueakersMenu", "NPC Voice Chat", "", "", function( panel ) 
        local clText = panel:Help( "Client-Side (User Settings):" )
        clText:SetTextColor( clientColor )

        panel:NumSlider( "Voice Volume", "cl_npcvoicechat_playvolume", 0, 4, 1 )
        ClientControlHelp( panel, "Volume of NPCs' voices during their voicechat shenanigans" )

        panel:NumSlider( "Max Volume Range", "cl_npcvoicechat_playdistance", 0, 2000, 0 )
        ClientControlHelp( panel, "How close should you be to the NPC for its voiceline's volume to reach maximum possible value" )

        local clVoicePfps
        if NPCVC_LambdaVoiceProfile then
            clVoicePfps = panel:ComboBox( "Lambda Voice Profile", "cl_npcvoicechat_lambdavoicepfp" )
            clVoicePfps:SetSortItems( false )
            clVoicePfps:AddChoice( "None", "" )

            local curValue
            local curVoicePfp = GetConVar( "cl_npcvoicechat_lambdavoicepfp" ):GetString()
            for lambdaVP, _ in SortedPairs( NPCVC_LambdaVoiceProfile ) do
                if curVoicePfp == lambdaVP then curValue = lambdaVP end
                clVoicePfps:AddChoice( lambdaVP, lambdaVP )
            end
            clVoicePfps:SetValue( curValue or "None" )

            ClientControlHelp( panel, "The Lambda Voice Profile your newly created NPC should be spawned with. Note: This will only work if there's no voice profile specified serverside" )
        end

        panel:CheckBox( "Global Voice Chat", "cl_npcvoicechat_globalvoicechat" )
        ClientControlHelp( panel, "If NPC's voice chat can be heard globally and not in 3D" )

        panel:CheckBox( "Display Voice Icon", "cl_npcvoicechat_showvoiceicon" )
        ClientControlHelp( panel, "If a voice icon should appear above NPC while they're speaking or using voicechat" )

        panel:CheckBox( "Display Voice Popups", "cl_npcvoicechat_showpopups" )
        ClientControlHelp( panel, "If a voicechat popup similar to real player one should display while NPC is using voicechat" )

        panel:NumSlider( "Popup Display Range", "cl_npcvoicechat_popupdisplaydist", 0, 2000, 0 )
        ClientControlHelp( panel, "How close should you be to the the NPC in order for its voice popup to display. Set to zero to draw regardless of range" )

        panel:NumSlider( "Popup Fadeout Time", "cl_npcvoicechat_popupfadetime", 0, 10, 1 )
        ClientControlHelp( panel, "Time in seconds required for a voice popup to fully fadeout after not being used" )

        panel:Help( "Popup Volume Color:" )
        local popupColor = vgui.Create( "DColorMixer", panel )
        panel:AddItem( popupColor )

        popupColor:SetConVarR( "cl_npcvoicechat_popupcolor_r" )
        popupColor:SetConVarG( "cl_npcvoicechat_popupcolor_g" )
        popupColor:SetConVarB( "cl_npcvoicechat_popupcolor_b" )

        ClientControlHelp( panel, "\nThe color of the voice popup when it's liten up by NPC's voice volume" )

        if !LocalPlayer():IsSuperAdmin() then 
            panel:Help( "" )
            return 
        end

        panel:Help( "------------------------------------------------------------" )
        local svText = panel:Help( "Server-Side (Admin Settings):" )
        svText:SetTextColor( Color( 0, 174, 255 ) )

        panel:CheckBox( "Enable NPC Voice Chat", "sv_npcvoicechat_enabled" )
        panel:ControlHelp( "Allows to NPCs and nextbots to able to speak voicechat-like using voicelines" )

        panel:Help( "NPC Type Toggles:" )
        panel:CheckBox( "Allow Standart NPCs", "sv_npcvoicechat_allownpc" )
        panel:CheckBox( "Allow VJ Base SNPCs", "sv_npcvoicechat_allowvjbase" )
        panel:CheckBox( "Allow DrGBase Nextbots", "sv_npcvoicechat_allowdrgbase" )
        panel:CheckBox( "Allow 2D Chase Nextbots", "sv_npcvoicechat_allowsanic" )
        panel:Help( "------------------------------------------------------------" )

        panel:CheckBox( "Ignore Gagged NPCs", "sv_npcvoicechat_ignoregagged" )
        panel:ControlHelp( "If NPCs that are gagged by a spawnflag aren't allowed to speak until its removed" )

        panel:CheckBox( "Slightly Delay Playing", "sv_npcvoicechat_slightdelay" )
        panel:ControlHelp( "If there should be a slight delay before NPC plays its voiceline to simulate its reaction time" )

        panel:CheckBox( "Use Custom Profile Pictures", "sv_npcvoicechat_usecustompfps" )
        panel:ControlHelp( "If NPCs are allowed to use custom profile pictures instead of their model's spawnmenu icon if any is available" )

        local minPitch = panel:NumSlider( "Min Voice Pitch", "sv_npcvoicechat_voicepitch_min", 10, 100, 0 )
        panel:ControlHelp( "The lowest pitch a NPC's voice can get upon spawning" )
       
        local maxPitch = panel:NumSlider( "Max Voice Pitch", "sv_npcvoicechat_voicepitch_max", 100, 255, 0 )
        panel:ControlHelp( "The highest pitch a NPC's voice can get upon spawning" )

        function minPitch:OnValueChanged( value )
            maxPitch:SetMin( value )
        end
        function maxPitch:OnValueChanged( value )
            minPitch:SetMax( value )
        end

        if NPCVC_LambdaVoiceProfile then
            panel:Help( "Lambda-Related Stuff:" )
        end

        if LambdaVoiceProfiles then
            panel:CheckBox( "Use Lambda Players Voicelines", "sv_npcvoicechat_uselambdavoicelines" )
            panel:ControlHelp( "If NPCs should use voicelines from Lambda Players and its addons + modules instead" )

            panel:CheckBox( "Use Lambda Players Profile Pictures", "sv_npcvoicechat_uselambdapfppics" )
            panel:ControlHelp( "If NPCs should use profile pictures from Lambda Players and its addons + modules instead" )
            
            panel:CheckBox( "Use Lambda Players Nicknames", "sv_npcvoicechat_uselambdanames" )
            panel:ControlHelp( "If NPCs should use nicknames from Lambda Players and its addons + modules instead" )
        end

        local svVoicePfps
        if NPCVC_LambdaVoiceProfile then
            svVoicePfps = panel:ComboBox( "Lambda Voice Profile", "sv_npcvoicechat_lambdavoicepfp" )
            svVoicePfps:SetSortItems( false )
            svVoicePfps:AddChoice( "None", "" )

            local curValue
            local curVoicePfp = GetConVar( "sv_npcvoicechat_lambdavoicepfp" ):GetString()
            for lambdaVP, _ in SortedPairs( NPCVC_LambdaVoiceProfile ) do
                if curVoicePfp == lambdaVP then curValue = lambdaVP end
                svVoicePfps:AddChoice( lambdaVP, lambdaVP )
            end
            svVoicePfps:SetValue( curValue or "None" )

            panel:ControlHelp( "The Lambda Voice Profile the newly created NPC should be spawned with. Note: This will override every player's client option with this one" )

            panel:NumSlider( "Voice Profile Spawn Chance", "sv_npcvoicechat_lambdavoicepfp_spawnchance", 0, 100, 0 )
            panel:ControlHelp( "The chance the a NPC will use a random available Lambda Voice Profile as their voice profile after they spawn" )
        end

        net.Receive( "npcsqueakers_updatespawnmenu", function()
            UpdateVoiceProfiles()

            if IsValid( clVoicePfps ) then
                clVoicePfps:Clear()
                clVoicePfps:AddChoice( "None", "" )

                local curValue
                local curVoicePfp = GetConVar( "cl_npcvoicechat_lambdavoicepfp" ):GetString()
                for lambdaVP, _ in SortedPairs( NPCVC_LambdaVoiceProfile ) do
                    if curVoicePfp == lambdaVP then curValue = lambdaVP end
                    clVoicePfps:AddChoice( lambdaVP, lambdaVP )
                end
                clVoicePfps:SetValue( curValue or "None" )
            end

            if IsValid( svVoicePfps ) then
                svVoicePfps:Clear()
                svVoicePfps:AddChoice( "None", "" )

                local curValue
                local curVoicePfp = GetConVar( "sv_npcvoicechat_lambdavoicepfp" ):GetString()
                for lambdaVP, _ in SortedPairs( NPCVC_LambdaVoiceProfile ) do
                    if curVoicePfp == lambdaVP then curValue = lambdaVP end
                    svVoicePfps:AddChoice( lambdaVP, lambdaVP )
                end
                svVoicePfps:SetValue( curValue or "None" )
            end
        end )

        panel:Help( "------------------------------------------------------------" )
        panel:Button( "Update Data", "sv_npcvoicechat_updatedata" )
        panel:ControlHelp( "Updates and refreshes the nicknames, voicelines and other data required for NPC's proper voice chatting. You should always do it after adding or removing stuff" )

        panel:Help( "Voiceline Type Toggles:" )
        panel:CheckBox( "Idling", "sv_npcvoicechat_allowlines_idle" )
        panel:CheckBox( "In-Combat Idling", "sv_npcvoicechat_allowlines_combatidle" )
        panel:CheckBox( "Death", "sv_npcvoicechat_allowlines_death" )
        panel:CheckBox( "Spot Enemy", "sv_npcvoicechat_allowlines_spotenemy" )
        panel:CheckBox( "Kill Enemy", "sv_npcvoicechat_allowlines_killenemy" )
        panel:CheckBox( "Ally Death", "sv_npcvoicechat_allowlines_allydeath" )
        panel:CheckBox( "Assisted", "sv_npcvoicechat_allowlines_assist" )
        panel:CheckBox( "Spot Danger", "sv_npcvoicechat_allowlines_spotdanger" )
        panel:CheckBox( "Catch On Fire", "sv_npcvoicechat_allowlines_catchonfire" )
        panel:CheckBox( "Low On Health", "sv_npcvoicechat_allowlines_lowhealth" )
        panel:Help( "" )
    end )
end

hook.Add( "Tick", "NPCSqueakers_UpdateSounds", UpdateSounds )
hook.Add( "PreDrawEffects", "NPCSqueakers_DrawVoiceIcons", DrawVoiceIcons )
hook.Add( "HUDPaint", "NPCSqueakers_DrawVoiceChat", DrawVoiceChat )
hook.Add( "CreateClientsideRagdoll", "NPCSqueakers_OnCreateClientsideRagdoll", OnCreateClientsideRagdoll )
hook.Add( "AddToolMenuTabs", "NPCSqueakers_AddToolMenuTab", AddToolMenuTabs )
hook.Add( "PopulateToolMenu", "NPCSqueakers_PopulateToolMenu", PopulateToolMenu )