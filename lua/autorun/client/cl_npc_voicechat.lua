local net = net
local ipairs = ipairs
local pairs = pairs
local SortedPairsByValue = SortedPairsByValue
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

local vcEnabled         = CreateConVar( "sv_npcvoicechat_enabled", "1", ( FCVAR_ARCHIVE + FCVAR_REPLICATED ), "Allows to NPCs and nextbots to able to speak voicechat-like using voicelines", 0, 1 )
local vcGlobalVC        = CreateClientConVar( "cl_npcvoicechat_globalvoicechat", "0", nil, nil, "If the NPC voices can be heard globally", 0, 1 )
local vcPlayVol         = CreateClientConVar( "cl_npcvoicechat_playvolume", "1", nil, nil, "The sound volume of NPC voices", 0 )
local vcPlayDist        = CreateClientConVar( "cl_npcvoicechat_playdistance", "300", nil, nil, "Controls how far the NPC voices can be clearly heard from. Requires global voicechat to be disabled", 0 )
local vcShowIcon        = CreateClientConVar( "cl_npcvoicechat_showvoiceicon", "1", nil, nil, "If a voice icon should appear above NPC while they're speaking?", 0, 1 )
local vcShowPopups      = CreateClientConVar( "cl_npcvoicechat_showpopups", "0", nil, nil, "Allows to draw and display a voicechat popup when NPCs are currently speaking", 0, 1 )
local vcPopupDist       = CreateClientConVar( "cl_npcvoicechat_popupdisplaydist", "0", nil, nil, "How close should the NPC be for its voice popup to show up? Set to zero to show up regardless of distance", 0 )
local vcPopupFadeTime   = CreateClientConVar( "cl_npcvoicechat_popupfadetime", "2", nil, nil, "Time in seconds needed for popup to fadeout after stopping playing or being out of range", 0, 5 )
local vcPopupDrawPfp    = CreateClientConVar( "cl_npcvoicechat_popupdrawpfp", "1", nil, nil, "If the NPC's voice popup should draw its profile picture", 0, 1 )

local vcPopupColorR     = CreateClientConVar( "cl_npcvoicechat_popupcolor_r", "0", nil, nil, "The red color of voice popup when the NPC is using it", 0, 255 )
local vcPopupColorG     = CreateClientConVar( "cl_npcvoicechat_popupcolor_g", "255", nil, nil, "The green color of voice popup when the NPC is using it", 0, 255 )
local vcPopupColorB     = CreateClientConVar( "cl_npcvoicechat_popupcolor_b", "0", nil, nil, "The blue color of voice popup when the NPC is using it", 0, 255 )

CreateClientConVar( "cl_npcvoicechat_spawnvoiceprofile", "", nil, true, "The Voice Profile your newly created NPC should be spawned with. Note: This will only work if there's no voice profile specified serverside" )

NPCVC_SoundEmitters         = {}
NPCVC_VoicePopups           = {}
NPCVC_VoiceProfiles         = {}

local function UpdateVoiceProfiles()
    table_Empty( NPCVC_VoiceProfiles )

    local _, voicePfpDirs = file_Find( "sound/npcvoicechat/voiceprofiles/*", "GAME" )
    if voicePfpDirs then
        for _, voicePfp in ipairs( voicePfpDirs ) do
            NPCVC_VoiceProfiles[ voicePfp ] = ""
        end
    end

    local _, lambdaVPs = file_Find( "sound/lambdaplayers/voiceprofiles/*", "GAME" )
    if lambdaVPs then
        for _, voicePfp in ipairs( lambdaVPs ) do
            NPCVC_VoiceProfiles[ voicePfp ] = "[LambdaVP] "
        end
    end
    
    local _, zetaVPs = file_Find( "sound/zetaplayer/custom_vo/*", "GAME" )
    if zetaVPs then
        for _, voicePfp in ipairs( zetaVPs ) do
            NPCVC_VoiceProfiles[ voicePfp ] = "[ZetaVP] "
        end
    end
end
UpdateVoiceProfiles()

local function PlaySoundFile( sndDir, vcData, is3D )
    local ent = vcData.Emitter
    if !IsValid( ent ) then return end

    PlayFile( "sound/" .. sndDir, ( is3D and "3d" or "" ), function( snd, errorId, errorName )
        if errorId == 21 then
            PlaySoundFile( sndDir, vcData, false )
            return
        elseif !IsValid( snd ) then
            print( "NPC Voice Chat Error: Sound file " .. sndDir .. " failed to open!\nError Index: " .. errorName .. "#" .. errorId )
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
            Is3D = is3D
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
        local srcEnt = ( IsValid( ent ) and ent:GetSoundSource() )

        if !IsValid( ent ) or !IsValid( snd ) or snd:GetState() == GMOD_CHANNEL_STOPPED or ent:GetRemoveOnNoSource() and !IsValid( srcEnt ) then
            if IsValid( snd ) then snd:Stop() end
            table_remove( NPCVC_SoundEmitters, index )
            continue
        end

        if enabled then
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
                    snd:Set3DFadeDistance( ( fadeDist * max( volMult * 0.75, 1 ) ), 0 )
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
    local drawPfp = vcPopupDrawPfp:GetBool()

    for _, vcData in SortedPairsByMemberValue( drawPopupIndexes, "FirstDisplayTime" ) do
        local drawAlpha = vcData.AlphaRatio
        popup_BaseClr.a = ( drawAlpha * 255 )

        local vol = ( vcData.VoiceVolume * drawAlpha )
        popup_BoxClr.r = ( vol * popupClrR )
        popup_BoxClr.g = ( vol * popupClrG )
        popup_BoxClr.b = ( vol * popupClrB )
        popup_BoxClr.a = ( drawAlpha * 240 )

        RoundedBox( 4, drawX, drawY, 246, 40, popup_BoxClr )
        
        if drawPfp then
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
        end

        local nickname = vcData.Nick
        if #nickname > 22 then 
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
        if IsValid( sndEmitter ) then sndEmitter:SetSoundSource( ragdoll ) end
    end )
end

local function AddToolMenuTabs()
    spawnmenu.AddToolCategory( "Utilities", "YerSoMashy", "YerSoMashy" )
end

local function PopulateToolMenu()
    local clientColor = Color( 255, 145, 0 )
    local serverColor = Color( 0, 174, 255 )
    local function ColoredControlHelp( isClient, panel, text )
        local help = panel:ControlHelp( text )
        help:SetTextColor( isClient and clientColor or serverColor )
    end

    local function GetComboBoxVoiceProfiles( panel, comboBox, cvarName )
        if comboBox == false then
            comboBox = panel:ComboBox( "Voice Profile", cvarName )
            comboBox:SetSortItems( false )
        else
            if !IsValid( comboBox ) then return end
            comboBox:Clear()
        end

        comboBox:AddChoice( "None", "" )
        local curVoicePfp, curValue = GetConVar( cvarName ):GetString()
        for vp, prefix in SortedPairsByValue( NPCVC_VoiceProfiles ) do
            local prettyName = prefix .. vp
            comboBox:AddChoice( prettyName, vp )
            if curVoicePfp == vp then curValue = prettyName end
        end
        comboBox:SetValue( curValue or "None" )

        return comboBox
    end

    spawnmenu.AddToolMenuOption( "Utilities", "YerSoMashy", "NPCSqueakersMenu", "NPC Voice Chat", "", "", function( panel ) 
        local clText = panel:Help( "Client-Side (User Settings):" )
        clText:SetTextColor( clientColor )

        panel:NumSlider( "Voice Volume", "cl_npcvoicechat_playvolume", 0, 4, 1 )
        ColoredControlHelp( true, panel, "Volume of NPCs' voices during their voicechat shenanigans" )

        panel:NumSlider( "Max Volume Range", "cl_npcvoicechat_playdistance", 0, 2000, 0 )
        ColoredControlHelp( true, panel, "How close should you be to the NPC for its voiceline's volume to reach maximum possible value" )

        local clVoicePfps = GetComboBoxVoiceProfiles( panel, false, "cl_npcvoicechat_spawnvoiceprofile" )
        ColoredControlHelp( true, panel, "The Voice Profile your newly created NPC should be spawned with. Note: This will only work if there's no voice profile specified serverside" )

        panel:CheckBox( "Global Voice Chat", "cl_npcvoicechat_globalvoicechat" )
        ColoredControlHelp( true, panel, "If NPC's voice chat can be heard globally and not in 3D" )

        panel:CheckBox( "Display Voice Icon", "cl_npcvoicechat_showvoiceicon" )
        ColoredControlHelp( true, panel, "If a voice icon should appear above NPC while they're speaking or using voicechat" )

        panel:CheckBox( "Display Voice Popups", "cl_npcvoicechat_showpopups" )
        ColoredControlHelp( true, panel, "If a voicechat popup similar to real player one should display while NPC is using voicechat" )

        panel:CheckBox( "Draw Popup Profile Picture", "cl_npcvoicechat_popupdrawpfp" )
        ColoredControlHelp( true, panel, "If the NPC's voice popup should draw its profile picture" )

        panel:NumSlider( "Popup Display Range", "cl_npcvoicechat_popupdisplaydist", 0, 2000, 0 )
        ColoredControlHelp( true, panel, "How close should you be to the the NPC in order for its voice popup to display. Set to zero to draw regardless of range" )

        panel:NumSlider( "Popup Fadeout Time", "cl_npcvoicechat_popupfadetime", 0, 10, 1 )
        ColoredControlHelp( true, panel, "Time in seconds required for a voice popup to fully fadeout after not being used" )

        panel:Help( "Popup Volume Color:" )
        local popupColor = vgui.Create( "DColorMixer", panel )
        panel:AddItem( popupColor )

        popupColor:SetConVarR( "cl_npcvoicechat_popupcolor_r" )
        popupColor:SetConVarG( "cl_npcvoicechat_popupcolor_g" )
        popupColor:SetConVarB( "cl_npcvoicechat_popupcolor_b" )

        ColoredControlHelp( true, panel, "\nThe color of the voice popup when it's liten up by NPC's voice volume" )

        if !LocalPlayer():IsSuperAdmin() then 
            panel:Help( "" )
            return 
        end

        panel:Help( "------------------------------------------------------------" )
        local svText = panel:Help( "Server-Side (Admin Settings):" )
        svText:SetTextColor( serverColor )

        panel:CheckBox( "Enable NPC Voice Chat", "sv_npcvoicechat_enabled" )
        ColoredControlHelp( false, panel, "Allows to NPCs and nextbots to able to speak voicechat-like using voicelines" )

        panel:Help( "NPC Type Toggles:" )
        panel:CheckBox( "Standart NPCs", "sv_npcvoicechat_allownpc" )
        panel:CheckBox( "VJ Base SNPCs", "sv_npcvoicechat_allowvjbase" )
        panel:CheckBox( "DrGBase Nextbots", "sv_npcvoicechat_allowdrgbase" )
        panel:CheckBox( "2D Chase (Sanic-like) Nextbots", "sv_npcvoicechat_allowsanic" )
        panel:Help( "------------------------------------------------------------" )

        panel:CheckBox( "Ignore Gagged NPCs", "sv_npcvoicechat_ignoregagged" )
        ColoredControlHelp( false, panel, "If NPCs that are gagged by a spawnflag aren't allowed to speak until its removed" )

        panel:CheckBox( "Slightly Delay Playing", "sv_npcvoicechat_slightdelay" )
        ColoredControlHelp( false, panel, "If there should be a slight delay before NPC plays its voiceline to simulate its reaction time" )

        panel:CheckBox( "Use Custom Profile Pictures", "sv_npcvoicechat_usecustompfps" )
        ColoredControlHelp( false, panel, "If NPCs are allowed to use custom profile pictures instead of their model's spawnmenu icon if any is available" )

        local minPitch = panel:NumSlider( "Min Voice Pitch", "sv_npcvoicechat_voicepitch_min", 10, 100, 0 )
        ColoredControlHelp( false, panel, "The lowest pitch a NPC's voice can get upon spawning" )
       
        local maxPitch = panel:NumSlider( "Max Voice Pitch", "sv_npcvoicechat_voicepitch_max", 100, 255, 0 )
        ColoredControlHelp( false, panel, "The highest pitch a NPC's voice can get upon spawning" )

        function minPitch:OnValueChanged( value )
            maxPitch:SetMin( value )
        end
        function maxPitch:OnValueChanged( value )
            minPitch:SetMax( value )
        end

        panel:NumSlider( "Speak Limit", "sv_npcvoicechat_speaklimit", 0, 15, 0 )
        ColoredControlHelp( false, panel, "Controls the amount of NPCs that can use voicechat at once. Set to zero to disable" )

        panel:CheckBox( "Limit Doesn't Affect Death and Panic", "sv_npcvoicechat_speaklimit_dontaffectdeathpanic" )
        ColoredControlHelp( false, panel, "If the speak limit shouldn't affect NPCs that are playing their death or panicking voicelines" )

        if LambdaVoiceProfiles then
            panel:Help( "Lambda-Related Stuff:" )

            panel:CheckBox( "Use Lambda Players Voicelines", "sv_npcvoicechat_uselambdavoicelines" )
            ColoredControlHelp( false, panel, "If NPCs should use voicelines from Lambda Players and its addons + modules instead" )

            panel:CheckBox( "Use Lambda Players Profile Pictures", "sv_npcvoicechat_uselambdapfppics" )
            ColoredControlHelp( false, panel, "If NPCs should use profile pictures from Lambda Players and its addons + modules instead" )
            
            panel:CheckBox( "Use Lambda Players Nicknames", "sv_npcvoicechat_uselambdanames" )
            ColoredControlHelp( false, panel, "If NPCs should use nicknames from Lambda Players and its addons + modules instead" )
        end

        local svVoicePfps = GetComboBoxVoiceProfiles( panel, false, "sv_npcvoicechat_spawnvoiceprofile" )
        ColoredControlHelp( false, panel, "The Voice Profile the newly created NPC should be spawned with. Note: This will override every player's client option with this one" )

        panel:NumSlider( "Voice Profile Spawn Chance", "sv_npcvoicechat_randomvoiceprofilechance", 0, 100, 0 )
        ColoredControlHelp( false, panel, "The chance the a NPC will use a random available Voice Profile as their voice profile after they spawn" )

        panel:CheckBox( "Enable Profile Fallback", "sv_npcvoicechat_voiceprofilefallbacks" )
        ColoredControlHelp( false, panel, "If NPC with a voice profile should fallback to standart voicelines instead of playing nothing if its profile doesn't have a specified voice type in it" )

        net.Receive( "npcsqueakers_updatespawnmenu", function()
            UpdateVoiceProfiles()
            GetComboBoxVoiceProfiles( panel, clVoicePfps, "cl_npcvoicechat_spawnvoiceprofile" )
            GetComboBoxVoiceProfiles( panel, svVoicePfps, "sv_npcvoicechat_spawnvoiceprofile" )
        end )

        panel:Help( "------------------------------------------------------------" )
        panel:Button( "Update Data", "sv_npcvoicechat_updatedata" )
        ColoredControlHelp( false, panel, "Updates and refreshes the nicknames, voicelines and other data required for NPC's proper voice chatting. You should always do it after adding or removing stuff" )
        panel:Help( "------------------------------------------------------------" )

        panel:Help( "You can add new voicelines, nicknames, profile pictures and etc. by doing following the steps below:" )
        panel:Help( "Voicelines:" )
        ColoredControlHelp( false, panel, "Go to or create this filepath in the game's root directory: 'garrysmod/sound/npcvoicechat/vo'.\nIn that directory create a folder with the name of your sound's voiceline type and put the soundfile there. The filename doesn't matter, but the sound must be in .wav, .mp3, or .ogg format, have a frequency of 44100Hz, and must be in mono channel.\nThere are currently 8 types of sounds: assist, death, witness, idle, taunt, panic, laugh, and kill" )
        panel:Help( "Voice Profiles:" )
        ColoredControlHelp( false, panel, "Go to or create this filepath in the game's root directory: 'garrysmod/sound/npcvoicechat/voiceprofiles'.\nIn that directory you create a folder with the name of voice profile. After that the steps are the same from the voicelines one" )
        panel:Help( "Nicknames:" )
        ColoredControlHelp( false, panel, "Go to this path in the game's root directory: 'garrysmod/data/npcvoicechat'. There, you need the 'names.json' file.\nOpen it with you text editor and add or remove as many names as you like to. Just remember to follow the JSON file's formatting" )
        panel:Help( "Profile Pictures:" )
        ColoredControlHelp( false, panel, "Go to this path in the game's root directory: 'garrysmod/materials/npcvcdata/profilepics'.\nPut your profile picture images there, but make sure that its format is either .jpg or .png" )

        panel:Help( "------------------------------------------------------------" )

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