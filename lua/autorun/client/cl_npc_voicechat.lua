local net = net
local ipairs = ipairs
local pairs = pairs
local SortedPairsByValue = SortedPairsByValue
local IsValid = IsValid
local SimpleTimer = timer.Simple
local random = math.random
local string_sub = string.sub
local string_find = string.find
local lower = string.lower
local Clamp = math.Clamp
local table_Empty = table.Empty
local RealTime = RealTime
local PlayFile = sound.PlayFile
local EyeAngles = EyeAngles
local LocalPlayer = LocalPlayer
local table_remove = table.remove
local table_HasValue = table.HasValue
local table_Merge = table.Merge
local table_RemoveByValue = table.RemoveByValue
local max = math.max
local GetConVar = GetConVar
local RoundedBox = draw.RoundedBox
local DrawText = draw.DrawText
local SortedPairsByMemberValue = SortedPairsByMemberValue
local Lerp = Lerp
local Material = Material
local GetPhrase = language.GetPhrase
local ScrW = ScrW
local ScrH = ScrH
local Start3D2D = cam.Start3D2D
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetMaterial = surface.SetMaterial
local surface_DrawRect = surface.DrawRect
local surface_DrawTexturedRect = surface.DrawTexturedRect
local End3D2D = cam.End3D2D
local file_Find = file.Find
local JSONToTable = util.JSONToTable
local TableToJSON = util.TableToJSON
local PlaySound = surface.PlaySound
local notification_AddLegacy = notification.AddLegacy
local vgui_Create = vgui.Create
local list_Get = list.Get

local voiceIconMat      = Material( "voice/icntlk_pl" )
local popup_BaseClr     = Color( 255, 255, 255, 255 )
local popup_BoxClr      = Color( 0, 255, 0, 240 )
local clientColor       = Color( 255, 145, 0 )
local serverColor       = Color( 0, 174, 255 )
local npcNameBgColor    = Color( 72, 72, 72 )

local vcEnabled         = CreateConVar( "sv_npcvoicechat_enabled", "1", ( FCVAR_ARCHIVE + FCVAR_REPLICATED ), "Allows to NPCs and nextbots to able to speak voicechat-like using voicelines", 0, 1 )
local vcGlobalVC        = CreateClientConVar( "cl_npcvoicechat_globalvoicechat", "0", nil, nil, "If the NPC voices can be heard globally", 0, 1 )
local vcPlayVol         = CreateClientConVar( "cl_npcvoicechat_playvolume", "1", nil, nil, "The sound volume of NPC voices", 0 )
local vcPlayDist        = CreateClientConVar( "cl_npcvoicechat_playdistance", "300", nil, nil, "Controls how far the NPC voices can be clearly heard from. Requires global voicechat to be disabled", 0 )
local vcShowIcon        = CreateClientConVar( "cl_npcvoicechat_showvoiceicon", "1", nil, nil, "If a voice icon should appear above NPC while they're speaking?", 0, 1 )
local vcScaleIcon       = CreateClientConVar( "cl_npcvoicechat_scaleicon", "1", nil, nil, "If voice icons should scale with their owner's sizes", 0, 1 )
local vcShowPopups      = CreateClientConVar( "cl_npcvoicechat_showpopups", "1", nil, nil, "Allows to draw and display a voicechat popup when NPCs are currently speaking", 0, 1 )
local vcPopupDist       = CreateClientConVar( "cl_npcvoicechat_popupdisplaydist", "0", nil, nil, "How close should the NPC be for its voice popup to show up? Set to zero to show up regardless of distance", 0 )
local vcPopupFadeTime   = CreateClientConVar( "cl_npcvoicechat_popupfadetime", "2", nil, nil, "Time in seconds needed for popup to fadeout after stopping playing or being out of range", 0, 5 )
local vcPopupDrawPfp    = CreateClientConVar( "cl_npcvoicechat_popupdrawpfp", "1", nil, nil, "If the NPC's voice popup should draw its profile picture", 0, 1 )

local vcPopupColorR     = CreateClientConVar( "cl_npcvoicechat_popupcolor_r", "0", nil, nil, "The red color of voice popup when the NPC is using it", 0, 255 )
local vcPopupColorG     = CreateClientConVar( "cl_npcvoicechat_popupcolor_g", "255", nil, nil, "The green color of voice popup when the NPC is using it", 0, 255 )
local vcPopupColorB     = CreateClientConVar( "cl_npcvoicechat_popupcolor_b", "0", nil, nil, "The blue color of voice popup when the NPC is using it", 0, 255 )

local vcUniqueEnemyPopupClr    = CreateClientConVar( "cl_npcvoicechat_uniquepopupcolorforenemies", "0", nil, nil, "If NPCs that are hostile to you should have a different unique popup color", 0, 1 )
local vcHostilePopupColorR     = CreateClientConVar( "cl_npcvoicechat_enemypopupcolor_r", "255", nil, nil, "The red color of voice popup when the hostile NPC is using it", 0, 255 )
local vcHostilePopupColorG     = CreateClientConVar( "cl_npcvoicechat_enemypopupcolor_g", "0", nil, nil, "The green color of voice popup when the hostile NPC is using it", 0, 255 )
local vcHostilePopupColorB     = CreateClientConVar( "cl_npcvoicechat_enemypopupcolor_b", "0", nil, nil, "The blue color of voice popup when the hostile NPC is using it", 0, 255 )

CreateClientConVar( "cl_npcvoicechat_spawnvoiceprofile", "", nil, true, "The Voice Profile your newly created NPC should be spawned with. Note: This will only work if there's no voice profile specified serverside" )

NPCVC                       = NPCVC or {}
NPCVC.SoundEmitters         = NPCVC.SoundEmitters or {}
NPCVC.CachedNamePhrases     = NPCVC.CachedNamePhrases or {}
NPCVC.VoicePopups           = {}
NPCVC.VoiceProfiles         = {}
NPCVC.CachedMaterials       = {}

local function UpdateVoiceProfiles()
    table_Empty( NPCVC.VoiceProfiles )

    local _, voicePfpDirs = file_Find( "sound/npcvoicechat/voiceprofiles/*", "GAME" )
    if voicePfpDirs then
        for _, voicePfp in ipairs( voicePfpDirs ) do
            NPCVC.VoiceProfiles[ voicePfp ] = ""
        end
    end

    local _, lambdaVPs = file_Find( "sound/lambdaplayers/voiceprofiles/*", "GAME" )
    if lambdaVPs then
        for _, voicePfp in ipairs( lambdaVPs ) do
            NPCVC.VoiceProfiles[ voicePfp ] = "[LambdaVP] "
        end
    end
    
    local _, zetaVPs = file_Find( "sound/zetaplayer/custom_vo/*", "GAME" )
    if zetaVPs then
        for _, voicePfp in ipairs( zetaVPs ) do
            NPCVC.VoiceProfiles[ voicePfp ] = "[ZetaVP] "
        end
    end
end
UpdateVoiceProfiles()

local function GetSoundSource( ent )
    local netFunc, srcEnt = ent.GetSoundSource
    if netFunc then
        srcEnt = netFunc( ent )
    else
        srcEnt = ent:GetNW2Entity( "npcsqueakers_soundsrc", NULL )
    end
    return srcEnt, netFunc
end

local function PlaySoundFile( sndDir, vcData, playDelay, is3D )
    local ent = vcData.Emitter
    if !IsValid( ent ) then return end

    PlayFile( "sound/" .. sndDir, "noplay" .. ( is3D and "3d" or "" ), function( snd, errorId, errorName )
        if errorId == 21 then
            PlaySoundFile( sndDir, vcData, playDelay, false )
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

        local srcEnt = GetSoundSource( ent )
        local playPos = ( IsValid( srcEnt ) and srcEnt:GetPos() or ent:GetPos() )
        snd:SetPos( playPos )

        local playRate = ( vcData.Pitch / 100 )
        snd:SetPlaybackRate( playRate )

        local volMult = vcData.VolumeMult
        snd:SetVolume( !vcEnabled:GetBool() and 0 or ( vcPlayVol:GetFloat() * volMult ) )
        snd:Set3DFadeDistance( vcPlayDist:GetInt() * max( volMult * 0.66, ( volMult >= 2.0 and 1.5 or 1 ) ), 0 )

        local playTime = ( RealTime() + playDelay )
        NPCVC.SoundEmitters[ #NPCVC.SoundEmitters + 1 ] = {
            Entity = ent,
            Sound = snd,
            LastPlayPos = playPos,
            VolumeMult = volMult,
            Is3D = is3D,
            IconHeight = vcData.IconHeight,
            PlayTime = playTime
        }

        local entIndex = vcData.EntIndex
        local voicePopup = NPCVC.VoicePopups[ entIndex ]
        if voicePopup then 
            voicePopup.Entity = ent
            voicePopup.Sound = snd
            voicePopup.LastPlayPos = playPos
        else
            local pfpPic, pfpMat = vcData.ProfilePicture
            if pfpPic then
                pfpMat = NPCVC.CachedMaterials[ pfpPic ]
                if pfpMat == nil then pfpMat = Material( pfpPic ) end
                if pfpMat and pfpMat:IsError() then pfpMat = nil end
                NPCVC.CachedMaterials[ pfpPic ] = ( pfpMat or false )
            end

            local nickName = vcData.Nickname
            if vcData.UsesRealName then
                local nickPhrase = NPCVC.CachedNamePhrases[ nickName ]
                if !nickPhrase then
                    nickPhrase = GetPhrase( nickName )
                    if ( !nickPhrase or nickPhrase == nickName ) and IsValid( srcEnt ) then
                        local npcName = list_Get( "NPC" )[ srcEnt:GetClass() ]
                        nickPhrase = ( npcName and npcName.Name or nickPhrase )
                        if nickPhrase and nickPhrase != nickName then NPCVC.CachedNamePhrases[ nickName ] = nickPhrase end
                    else
                        NPCVC.CachedNamePhrases[ nickName ] = nickPhrase
                    end
                end
                nickName = nickPhrase
            end
            if #nickName > 24 then 
                nickName = string_sub( nickName, 0, 22 ) .. "..." 
            end

            local displayDist = vcPopupDist:GetInt()
            displayDist = ( displayDist * displayDist )
            local canDrawRn = ( displayDist == 0 or LocalPlayer():GetPos():DistToSqr( playPos ) <= displayDist )

            NPCVC.VoicePopups[ entIndex ] = {
                Nick = nickName,
                Entity = ent,
                Sound = snd,
                LastPlayPos = playPos,
                ProfilePicture = pfpMat,
                VoiceVolume = 0,
                AlphaRatio = ( canDrawRn and 1 or 0 ),
                VolumeMult = volMult,
                PlayTime = playTime,
                LastPlayTime = ( canDrawRn and RealTime() or 0 ),
                FirstDisplayTime = ( canDrawRn and RealTime() or 0 ),
                IsHostile = ( vcData.EnemyPlayers[ LocalPlayer() ] or false )
            }
        end

        net.Start( "npcsqueakers_sndduration" )
            net.WriteEntity( ent )
            net.WriteFloat( ( sndLength / playRate ) + playDelay )
        net.SendToServer()
    end )
end

net.Receive( "npcsqueakers_playsound", function()
    PlaySoundFile( net.ReadString(), net.ReadTable(), net.ReadFloat(), true )
end )

local function UpdateSounds()
    if #NPCVC.SoundEmitters == 0 then return end

    local enabled = vcEnabled:GetBool()
    local volume = vcPlayVol:GetFloat()
    local fadeDist = vcPlayDist:GetInt()
    local isGlobal = vcGlobalVC:GetBool()
    local plyPos = LocalPlayer():GetPos()
    local realTime = RealTime()

    for index, sndData in ipairs( NPCVC.SoundEmitters ) do
        local ent = sndData.Entity
        local snd = sndData.Sound
        local srcEnt, netFunc = ( IsValid( ent ) and GetSoundSource( ent ) )
        local playTime = sndData.PlayTime

        if !IsValid( ent ) or !IsValid( snd ) or !playTime and snd:GetState() == GMOD_CHANNEL_STOPPED or netFunc and !IsValid( srcEnt ) and ent:GetRemoveOnNoSource() then
            if IsValid( snd ) then snd:Stop() end
            table_remove( NPCVC.SoundEmitters, index )
            continue
        end

        local lastPos = sndData.LastPlayPos
        if IsValid( srcEnt ) then
            lastPos = srcEnt:GetPos()
            sndData.LastPlayPos = lastPos
        end

        if playTime and realTime >= sndData.PlayTime then
            snd:Play()
            sndData.PlayTime = false
        end

        if enabled then
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
                    snd:Set3DFadeDistance( ( fadeDist * max( volMult * 0.66, ( volMult >= 2.0 and 1.5 or 1 ) ) ), 0 )
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

    for _, sndData in ipairs( NPCVC.SoundEmitters ) do
        if sndData.PlayTime then continue end

        local ang = EyeAngles()
        ang:RotateAroundAxis( ang:Up(), -90 )
        ang:RotateAroundAxis( ang:Forward(), 90 )

        local pos = ( sndData.LastPlayPos + vector_up * sndData.IconHeight )
        local scale = max( 0.66, 1 * ( vcScaleIcon:GetBool() and sndData.VolumeMult or 1 ) )
        if scale > 1 then 
            local ent = sndData.Entity
            if IsValid( ent ) then
                local srcEnt = GetSoundSource( ent )
                if IsValid( srcEnt ) and !srcEnt:IsRagdoll() then
                    pos = ( pos + vector_up * ( 24 * ( scale - 1 ) ) )
                end
            end 
        end

        Start3D2D( pos, ang, scale )
            surface_SetDrawColor( 255, 255, 255 )
            surface_SetMaterial( voiceIconMat )
            surface_DrawTexturedRect( -8, -8, 16, 16 )
        End3D2D()
    end
end

local scrSizeW, scrSizeH = ScrW(), ScrH()
local function OnScreenSizeChanged( oldW, oldH )
    scrSizeW, scrSizeH = ScrW(), ScrH()
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
    for index, vcData in SortedPairsByMemberValue( NPCVC.VoicePopups, "FirstDisplayTime" ) do
        local playTime = vcData.PlayTime
        if playTime then
            if realTime >= playTime then
                playTime = false
                vcData.PlayTime = playTime
            else
                continue
            end
        end
        
        local ent = vcData.Entity
        local lastPos = vcData.LastPlayPos
        if IsValid( ent ) then 
            local srcEnt = GetSoundSource( ent )
            if IsValid( srcEnt ) then
                lastPos = srcEnt:GetPos()
                vcData.LastPlayPos = lastPos
            end
        end

        local sndVol = 0
        local snd = vcData.Sound
        if IsValid( snd ) and snd:GetState() == GMOD_CHANNEL_PLAYING then
            local leftChan, rightChan = snd:GetLevel()
            sndVol = ( ( leftChan + rightChan ) * 0.5 )

            if displayDist == 0 or plyPos:DistToSqr( lastPos ) <= displayDist then
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
            NPCVC.VoicePopups[ index ] = nil
            continue
        end

        vcData.AlphaRatio = drawAlpha
        if drawAlpha == 0 then
            vcData.FirstDisplayTime = 0
            continue 
        end

        canDrawSomething = true
        drawPopupIndexes[ index ] = vcData
    end

    if !canDrawSomething then return end
    local drawX, drawY = ( scrSizeW - 298 ), ( scrSizeH - 142 )
    drawY = ( drawY - ( 44 * #g_VoicePanelList:GetChildren() ) )

    local popupClrR = vcPopupColorR:GetInt()
    local popupClrG = vcPopupColorG:GetInt()
    local popupClrB = vcPopupColorB:GetInt()

    local enemyPopupEnabled = vcUniqueEnemyPopupClr:GetBool()
    local enemyPopupClrR = vcHostilePopupColorR:GetInt()
    local enemyPopupClrG = vcHostilePopupColorG:GetInt()
    local enemyPopupClrB = vcHostilePopupColorB:GetInt()

    local drawPfp = vcPopupDrawPfp:GetBool()

    for _, vcData in SortedPairsByMemberValue( drawPopupIndexes, "FirstDisplayTime" ) do
        local drawAlpha = vcData.AlphaRatio
        popup_BaseClr.a = ( drawAlpha * 255 )

        local vol = ( vcData.VoiceVolume * drawAlpha )
        popup_BoxClr.r = ( vol * ( ( enemyPopupEnabled and vcData.IsHostile ) and enemyPopupClrR or popupClrR ) )
        popup_BoxClr.g = ( vol * ( ( enemyPopupEnabled and vcData.IsHostile ) and enemyPopupClrG or popupClrG ) )
        popup_BoxClr.b = ( vol * ( ( enemyPopupEnabled and vcData.IsHostile ) and enemyPopupClrB or popupClrB ) )
        popup_BoxClr.a = ( drawAlpha * 240 )

        RoundedBox( 4, drawX, drawY, 246, 40, popup_BoxClr )
        
        if drawPfp then
            local pfp = vcData.ProfilePicture
            if pfp then
                surface_SetDrawColor( popup_BaseClr )
                surface_SetMaterial( pfp )
                surface_DrawTexturedRect( drawX + 4, drawY + 4, 32, 32 )
            end
        end

        DrawText( vcData.Nick, "GModNotify", drawX + 43.5, drawY + 9, popup_BaseClr, TEXT_ALIGN_LEFT )
        drawY = ( drawY - 44 )
    end
end

local function OnCreateClientsideRagdoll( owner, ragdoll )
    SimpleTimer( 0.1, function()
        if !IsValid( owner ) or !IsValid( ragdoll ) then return end
        sndEmitter = owner:GetNW2Entity( "npcsqueakers_sndemitter" )
        if IsValid( sndEmitter ) then sndEmitter:SetSoundSource( ragdoll ) end
    end )
end

hook.Add( "Tick", "NPCSqueakers_UpdateSounds", UpdateSounds )
hook.Add( "PreDrawEffects", "NPCSqueakers_DrawVoiceIcons", DrawVoiceIcons )
hook.Add( "HUDPaint", "NPCSqueakers_DrawVoiceChat", DrawVoiceChat )
hook.Add( "CreateClientsideRagdoll", "NPCSqueakers_OnCreateClientsideRagdoll", OnCreateClientsideRagdoll )

------------------------------------------------------------------------------------------------------------

NPCVC.ClientSettings    = NPCVC.ClientSettings or {}
NPCVC.ServerSettings    = NPCVC.ServerSettings or {}

local function OpenClassSpecificVPs( ply )
    if !ply:IsSuperAdmin() then
        PlaySound( "buttons/button11.wav" )
        notification_AddLegacy( "You must be a Super Admin in order to use this!", 1, 4 )
        return
    end

    local frame = vgui_Create( "DFrame" )
    frame:SetSize( 800, 500 )
    frame:SetSizable( true )
    frame:SetTitle( "NPC-Specific Voice Profiles" )
    frame:SetDeleteOnClose( true )
    frame:Center()
    frame:MakePopup()
    
    local label = vgui_Create( "DLabel", frame )
    label:SetText( "Click on a NPC on the left to assign a voice profile to it. Right click a row to the right to unassign the voice profile from it" )
    label:Dock( TOP )

    local npcSelectPanel = vgui_Create( "DPanel", frame )
    npcSelectPanel:SetSize( 430, 1 )
    npcSelectPanel:Dock( LEFT )

    local scrollPanel = vgui_Create( "DScrollPanel", npcSelectPanel )
    scrollPanel:Dock( FILL )

    local npcIconLayout = vgui_Create( "DIconLayout", scrollPanel )
    npcIconLayout:Dock( FILL )
    npcIconLayout:SetSpaceX( 5 )
    npcIconLayout:SetSpaceY( 5 )

    local npcListPanel = vgui_Create( "DListView", frame )
    npcListPanel:SetSize( 350, 1 )
    npcListPanel:DockMargin( 10, 0, 0, 0 )
    npcListPanel:Dock( LEFT )
    npcListPanel:AddColumn( "NPC", 1 )
    npcListPanel:AddColumn( "Voice Profile", 2 )

    local npcList = list_Get( "NPC" )
    local changedSomething = false

    local function AssignVPToClass( class, prettyName, npcPanel )
        PlaySound( "buttons/lightswitch2.wav" )

        local vpSelectFrame = vgui_Create( "DFrame" )
        vpSelectFrame:SetSize( 300, 100 )
        vpSelectFrame:SetSizable( true )
        vpSelectFrame:SetTitle( "Voice Profile Assigment" )
        vpSelectFrame:SetDeleteOnClose( true )
        vpSelectFrame:SetBackgroundBlur( true )
        vpSelectFrame:Center()
        vpSelectFrame:MakePopup()

        local infoLabel = vgui_Create( "DLabel", vpSelectFrame )
        infoLabel:SetText( "Select the voice profile you want to assign to this NPC class." )
        infoLabel:Dock( TOP )

        local vpSelection = vgui_Create( "DComboBox", vpSelectFrame )
        vpSelection:Dock( TOP )
        vpSelection:SetValue( "None" )

        vpSelection:AddChoice( "None", "" )
        for vp, prefix in SortedPairsByValue( NPCVC.VoiceProfiles ) do
            vpSelection:AddChoice( prefix .. vp, vp )
        end

        local doneButton = vgui_Create( "DButton", vpSelectFrame )
        doneButton:Dock( BOTTOM )
        doneButton:SetText( "Done" )

        function doneButton:DoClick()
            local vpName, vpSelected = vpSelection:GetSelected()
            if vpSelected and #vpSelected != 0 then 
                PlaySound( "buttons/button15.wav" )
                notification_AddLegacy( "Successfully assigned " .. ( prettyName or class ) .. "'s voice profile to " .. vpName .. "!", 0, 4 )

                npcListPanel:AddLine( ( prettyName and prettyName .. " (" .. class .. ")" or class ), vpSelected, class )
                if npcPanel then npcPanel:Remove() end
                changedSomething = true
            end

            vpSelectFrame:Remove()
        end
    end

    local textEntry = vgui_Create( "DTextEntry", npcListPanel )
    textEntry:SetPlaceholderText( "Enter NPC's class here if it's not on the list" )
    textEntry:Dock( BOTTOM )

    function textEntry:OnEnter( class )
        if !class or #class == 0 then return end
        class = lower( class )
        textEntry:SetText( "" )

        for _, line in ipairs( npcListPanel:GetLines() ) do
            if lower( line:GetColumnText( 2 ) ) != class then continue end
            PlaySound( "buttons/button11.wav" )
            notification_AddLegacy( "The class is already registered in the list!", 1, 4 )
            return
        end

        PlaySound( "buttons/lightswitch2.wav" )
        AssignVPToClass( class )
    end

    local function AddNPCPanel( class )
        for _, v in pairs( npcIconLayout:GetChildren() ) do 
            if v:GetNPC() == class then return end 
        end

        local npcPanel = npcIconLayout:Add( "DPanel" )
        npcPanel:SetSize( 100, 120 )
        npcPanel:SetBackgroundColor( npcNameBgColor )

        local npcImg = vgui_Create( "DImageButton", npcPanel )
        npcImg:SetSize( 100, 100 )
        npcImg:Dock( TOP )
        
        local iconMat = NPCVC.CachedMaterials[ class ]
        if !iconMat then
            iconMat = Material( "entities/" .. class .. ".png" )
            if iconMat:IsError() then iconMat = Material( "entities/" .. class .. ".jpg" ) end
            if iconMat:IsError() then iconMat = Material( "vgui/entities/" .. class ) end
        end
        if iconMat != false and !iconMat:IsError() then 
            npcImg:SetMaterial( iconMat )
        end
        NPCVC.CachedMaterials[ class ] = ( iconMat or false ) 

        local npcName = vgui_Create( "DLabel", npcPanel )
        local prettyName = ( npcList[ class ] and npcList[ class ].Name )
        npcName:SetText( prettyName or class )
        npcName:Dock( TOP )

        function npcImg:DoClick()
            AssignVPToClass( class, prettyName, npcPanel )
        end

        function npcPanel:GetNPC() 
            return class 
        end
    end

    for _, v in SortedPairsByMemberValue( npcList, "Category" ) do
        AddNPCPanel( v.Class )
    end

    function npcListPanel:OnRowRightClick( id, line )
        PlaySound( "buttons/combine_button3.wav" )
        changedSomething = true
        
        local class = line:GetColumnText( 3 )
        if npcList[ class ] then AddNPCPanel( class ) end
        self:RemoveLine( id )
    end

    function frame:OnClose()
        if changedSomething then
            PlaySound( "ambient/water/drip4.wav" )
            notification_AddLegacy( "Make sure to update the data after this!", 3, 4 )
        end

        local classVPs = {}
        for _, line in pairs( npcListPanel:GetLines() ) do 
            classVPs[ line:GetColumnText( 3 ) ] = line:GetColumnText( 2 ) 
        end

        net.Start( "npcsqueakers_writedata" )
            net.WriteString( TableToJSON( classVPs ) )
            net.WriteString( "classvps.json" )
        net.SendToServer()
    end

    net.Start( "npcsqueakers_requestdata" )
        net.WriteString( "classvps.json" )
    net.SendToServer()

    net.Receive( "npcsqueakers_returndata", function()
        local data = JSONToTable( net.ReadString() )
        if !data then return end

        for class, vp in pairs( data ) do
            local listData = npcList[ class ]
            local prettyName = ( listData and listData.Name )
            npcListPanel:AddLine( ( prettyName and prettyName .. " (" .. class .. ")" or class ), vp, class )

            for _, npcPanel in pairs( npcIconLayout:GetChildren() ) do
                if npcPanel:GetNPC() == class then npcPanel:Remove() break end 
            end
        end
    end )
end

local function OpenNPCBlacklisting( ply )
    if !ply:IsSuperAdmin() then
        PlaySound( "buttons/button11.wav" )
        notification_AddLegacy( "You must be a Super Admin in order to use this!", 1, 4 )
        return
    end

    local frame = vgui_Create( "DFrame" )
    frame:SetSize( 800, 500 )
    frame:SetSizable( true )
    frame:SetTitle( "NPC Voice Chat Blacklist" )
    frame:SetDeleteOnClose( true )
    frame:Center()
    frame:MakePopup()
    
    local label = vgui_Create( "DLabel", frame )
    label:SetText( "Click on a NPC on the left to blacklist it from voicechat usage. Right click a row to the right to remove it from blacklist" )
    label:Dock( TOP )

    local npcSelectPanel = vgui_Create( "DPanel", frame )
    npcSelectPanel:SetSize( 430, 1 )
    npcSelectPanel:Dock( LEFT )

    local scrollPanel = vgui_Create( "DScrollPanel", npcSelectPanel )
    scrollPanel:Dock( FILL )

    local npcIconLayout = vgui_Create( "DIconLayout", scrollPanel )
    npcIconLayout:Dock( FILL )
    npcIconLayout:SetSpaceX( 5 )
    npcIconLayout:SetSpaceY( 5 )

    local npcListPanel = vgui_Create( "DListView", frame )
    npcListPanel:SetSize( 350, 1 )
    npcListPanel:DockMargin( 10, 0, 0, 0 )
    npcListPanel:Dock( LEFT )
    npcListPanel:AddColumn( "NPC", 1 )

    local textEntry = vgui_Create( "DTextEntry", npcListPanel )
    textEntry:SetPlaceholderText( "Enter NPC's class here if it's not on the list" )
    textEntry:Dock( BOTTOM )

    local npcList = list_Get( "NPC" )
    local changedSomething = false

    function textEntry:OnEnter( class )
        if !class or #class == 0 then return end
        class = lower( class )
        textEntry:SetText( "" )

        for _, line in ipairs( npcListPanel:GetLines() ) do
            if lower( line:GetColumnText( 2 ) ) != class then continue end
            PlaySound( "buttons/button11.wav" )
            notification_AddLegacy( "The class is already registered in the list!", 1, 4 )
            return
        end

        PlaySound( "buttons/lightswitch2.wav" )
        local prettyName = ( npcList[ class ] and npcList[ class ].Name or false )
        changedSomething = true
        npcListPanel:AddLine( ( prettyName and prettyName .. " (" .. class .. ")" or class ), class )
    end

    local function AddNPCPanel( class )
        for _, v in pairs( npcIconLayout:GetChildren() ) do 
            if v:GetNPC() == class then return end 
        end

        local npcPanel = npcIconLayout:Add( "DPanel" )
        npcPanel:SetSize( 100, 120 )
        npcPanel:SetBackgroundColor( npcNameBgColor )

        local npcImg = vgui_Create( "DImageButton", npcPanel )
        npcImg:SetSize( 100, 100 )
        npcImg:Dock( TOP )

        local iconMat = NPCVC.CachedMaterials[ class ]
        if !iconMat then
            iconMat = Material( "entities/" .. class .. ".png" )
            if iconMat:IsError() then iconMat = Material( "entities/" .. class .. ".jpg" ) end
            if iconMat:IsError() then iconMat = Material( "vgui/entities/" .. class ) end
        end
        if iconMat != false and !iconMat:IsError() then 
            npcImg:SetMaterial( iconMat )
        end
        NPCVC.CachedMaterials[ class ] = ( iconMat or false ) 

        local npcName = vgui_Create( "DLabel", npcPanel )
        local prettyName = ( npcList[ class ] and npcList[ class ].Name )
        npcName:SetText( prettyName or class )
        npcName:Dock( TOP )

        function npcImg:DoClick()
            PlaySound( "buttons/lightswitch2.wav" )
            npcListPanel:AddLine( ( prettyName and prettyName .. " (" .. class .. ")" or class ), class )
            npcPanel:Remove()
            changedSomething = true
        end

        function npcPanel:GetNPC() 
            return class 
        end
    end

    for _, v in SortedPairsByMemberValue( npcList, "Category" ) do
        AddNPCPanel( v.Class )
    end

    function npcListPanel:OnRowRightClick( id, line )
        PlaySound( "buttons/combine_button3.wav" )
        changedSomething = true

        local class = line:GetColumnText( 2 )
        if npcList[ class ] then AddNPCPanel( class ) end
        self:RemoveLine( id )
    end

    function frame:OnClose()
        if changedSomething then
            PlaySound( "ambient/water/drip4.wav" )
            notification_AddLegacy( "Make sure to update the data after this!", 3, 4 )
        end

        local classes = {}
        for _, line in pairs( npcListPanel:GetLines() ) do 
            classes[ line:GetColumnText( 2 )  ] = true
        end

        net.Start( "npcsqueakers_writedata" )
            net.WriteString( TableToJSON( classes ) )
            net.WriteString( "npcblacklist.json" )
        net.SendToServer()
    end

    net.Start( "npcsqueakers_requestdata" )
        net.WriteString( "npcblacklist.json" )
    net.SendToServer()

    net.Receive( "npcsqueakers_returndata", function()
        local data = JSONToTable( net.ReadString() )
        if !data then return end

        for class, vp in pairs( data ) do
            local listData = npcList[ class ]
            local prettyName = ( listData and listData.Name )
            npcListPanel:AddLine( ( prettyName and prettyName .. " (" .. class .. ")" or class ), class )

            for _, npcPanel in pairs( npcIconLayout:GetChildren() ) do
                if npcPanel:GetNPC() == class then npcPanel:Remove() break end 
            end
        end
    end )
end

local function OpenNPCWhitelisting( ply )
    if !ply:IsSuperAdmin() then
        PlaySound( "buttons/button11.wav" )
        notification_AddLegacy( "You must be a Super Admin in order to use this!", 1, 4 )
        return
    end

    local frame = vgui_Create( "DFrame" )
    frame:SetSize( 800, 500 )
    frame:SetSizable( true )
    frame:SetTitle( "NPC Voice Chat Whitelist" )
    frame:SetDeleteOnClose( true )
    frame:Center()
    frame:MakePopup()
    
    local label = vgui_Create( "DLabel", frame )
    label:SetText( "Click on a NPC on the left to whitelist it for voicechat usage. Right click a row to the right to remove it from whitelist" )
    label:Dock( TOP )

    local npcSelectPanel = vgui_Create( "DPanel", frame )
    npcSelectPanel:SetSize( 430, 1 )
    npcSelectPanel:Dock( LEFT )

    local scrollPanel = vgui_Create( "DScrollPanel", npcSelectPanel )
    scrollPanel:Dock( FILL )

    local npcIconLayout = vgui_Create( "DIconLayout", scrollPanel )
    npcIconLayout:Dock( FILL )
    npcIconLayout:SetSpaceX( 5 )
    npcIconLayout:SetSpaceY( 5 )

    local npcListPanel = vgui_Create( "DListView", frame )
    npcListPanel:SetSize( 350, 1 )
    npcListPanel:DockMargin( 10, 0, 0, 0 )
    npcListPanel:Dock( LEFT )
    npcListPanel:AddColumn( "NPC", 1 )

    local textEntry = vgui_Create( "DTextEntry", npcListPanel )
    textEntry:SetPlaceholderText( "Enter NPC's class here if it's not on the list" )
    textEntry:Dock( BOTTOM )

    local npcList = list_Get( "NPC" )
    local changedSomething = false

    function textEntry:OnEnter( class )
        if !class or #class == 0 then return end
        class = lower( class )
        textEntry:SetText( "" )

        for _, line in ipairs( npcListPanel:GetLines() ) do
            if lower( line:GetColumnText( 2 ) ) != class then continue end
            PlaySound( "buttons/button11.wav" )
            notification_AddLegacy( "The class is already registered in the list!", 1, 4 )
            return
        end
        PlaySound( "buttons/lightswitch2.wav" )

        local prettyName = ( npcList[ class ] and npcList[ class ].Name or false )
        if prettyName == false then
            local vtSelectFrame = vgui_Create( "DFrame" )
            vtSelectFrame:SetSize( 300, 125 )
            vtSelectFrame:SetSizable( true )
            vtSelectFrame:SetTitle( "Idle Voice Type Assigment" )
            vtSelectFrame:SetDeleteOnClose( true )
            vtSelectFrame:SetBackgroundBlur( true )
            vtSelectFrame:Center()
            vtSelectFrame:MakePopup()

            local infoLabel = vgui_Create( "DLabel", vtSelectFrame )
            infoLabel:SetText( "It seems that you're registering a non-standart NPC." )
            infoLabel:Dock( TOP )

            local infoLabel2 = vgui_Create( "DLabel", vtSelectFrame )
            infoLabel2:SetText( "Select the voice type this NPC will use while idling." )
            infoLabel2:Dock( TOP )

            local voiceType = vgui_Create( "DComboBox", vtSelectFrame )
            voiceType:Dock( TOP )
            voiceType:SetValue( "Idle" )

            voiceType:AddChoice( "Idle", "idle" )
            voiceType:AddChoice( "Taunt", "taunt" )
            voiceType:AddChoice( "Death", "death" )
            voiceType:AddChoice( "Kill", "kill" )
            voiceType:AddChoice( "Laugh", "laugh" )
            voiceType:AddChoice( "Witness", "witness" )
            voiceType:AddChoice( "Assist", "assist" )
            voiceType:AddChoice( "Panic", "panic" )

            local doneButton = vgui_Create( "DButton", vtSelectFrame )
            doneButton:Dock( BOTTOM )
            doneButton:SetText( "Done" )

            function doneButton:DoClick()
                local _, selectedType = voiceType:GetSelected()
                PlaySound( "buttons/button15.wav" )
                npcListPanel:AddLine( class, class, selectedType )
                changedSomething = true
                vtSelectFrame:Remove()
            end
        else
            changedSomething = true
            npcListPanel:AddLine( ( prettyName and prettyName .. " (" .. class .. ")" or class ), class, true )
        end
    end

    local function AddNPCPanel( class )
        for _, v in pairs( npcIconLayout:GetChildren() ) do 
            if v:GetNPC() == class then return end 
        end

        local npcPanel = npcIconLayout:Add( "DPanel" )
        npcPanel:SetSize( 100, 120 )
        npcPanel:SetBackgroundColor( npcNameBgColor )

        local npcImg = vgui_Create( "DImageButton", npcPanel )
        npcImg:SetSize( 100, 100 )
        npcImg:Dock( TOP )

        local iconMat = NPCVC.CachedMaterials[ class ]
        if !iconMat then
            iconMat = Material( "entities/" .. class .. ".png" )
            if iconMat:IsError() then iconMat = Material( "entities/" .. class .. ".jpg" ) end
            if iconMat:IsError() then iconMat = Material( "vgui/entities/" .. class ) end
        end
        if iconMat != false and !iconMat:IsError() then 
            npcImg:SetMaterial( iconMat )
        end
        NPCVC.CachedMaterials[ class ] = ( iconMat or false ) 

        local npcName = vgui_Create( "DLabel", npcPanel )
        local prettyName = ( npcList[ class ] and npcList[ class ].Name )
        npcName:SetText( prettyName or class )
        npcName:Dock( TOP )

        function npcImg:DoClick()
            PlaySound( "buttons/lightswitch2.wav" )
            npcListPanel:AddLine( ( prettyName and prettyName .. " (" .. class .. ")" or class ), class, true )
            npcPanel:Remove()
            changedSomething = true
        end

        function npcPanel:GetNPC() 
            return class 
        end
    end

    for _, v in SortedPairsByMemberValue( npcList, "Category" ) do
        AddNPCPanel( v.Class )
    end

    function npcListPanel:OnRowRightClick( id, line )
        PlaySound( "buttons/combine_button3.wav" )
        changedSomething = true
        
        local class = line:GetColumnText( 2 )
        if npcList[ class ] then AddNPCPanel( class ) end
        self:RemoveLine( id )
    end

    function frame:OnClose()
        if changedSomething then
            PlaySound( "ambient/water/drip4.wav" )
            notification_AddLegacy( "Make sure to update the data after this!", 3, 4 )
        end

        local classes = {}
        for _, line in ipairs( npcListPanel:GetLines() ) do
            local idleVoice = line:GetColumnText( 3 )
            if !idleVoice or idleVoice == "" then idleVoice = true end
            classes[ line:GetColumnText( 2 )  ] = idleVoice
        end

        net.Start( "npcsqueakers_writedata" )
            net.WriteString( TableToJSON( classes ) )
            net.WriteString( "npcwhitelist.json" )
        net.SendToServer()
    end

    net.Start( "npcsqueakers_requestdata" )
        net.WriteString( "npcwhitelist.json" )
    net.SendToServer()

    net.Receive( "npcsqueakers_returndata", function()
        local data = JSONToTable( net.ReadString() )
        if !data then return end

        for class, idleVoice in pairs( data ) do
            local listData = npcList[ class ]
            local prettyName = ( listData and listData.Name )
            npcListPanel:AddLine( ( prettyName and prettyName .. " (" .. class .. ")" or class ), class, idleVoice )

            for _, npcPanel in pairs( npcIconLayout:GetChildren() ) do
                if npcPanel:GetNPC() == class then npcPanel:Remove() break end 
            end
        end
    end )
end

local function OpenNPCNicknames( ply )
    if !ply:IsSuperAdmin() then
        PlaySound( "buttons/button11.wav" )
        notification_AddLegacy( "You must be a Super Admin in order to use this!", 1, 4 )
        return
    end

    local frame = vgui_Create( "DFrame" )
    frame:SetSize( 300, 450 )
    frame:SetSizable( true )
    frame:SetTitle( "NPC Nickname Editor" )
    frame:SetDeleteOnClose( true )
    frame:Center()
    frame:MakePopup()
    
    local label = vgui_Create( "DLabel", frame )
    label:SetText( "Changes are applied after this window is closes" )
    label:Dock( TOP )
    
    local label2 = vgui_Create( "DLabel", frame )
    label2:SetText( "Remove an existing name by right clicking at it" )
    label2:Dock( TOP )
    
    local label3 = vgui_Create( "DLabel", frame )
    label3:SetText( "Make sure to update the data after any changes!" )
    label3:Dock( TOP )

    local nameList = vgui_Create( "DListView", frame )
    nameList:Dock( FILL )
    nameList:SetMultiSelect( false )
    nameList:AddColumn( "Names", 1 )

    local searchBar = vgui_Create( "DTextEntry", frame )
    searchBar:Dock( TOP )
    searchBar:SetPlaceholderText( "Search Bar" )

    local confirmButton = vgui_Create( "DButton", frame )
    confirmButton:SetText( "Confirm Changes" )
    confirmButton:Dock( BOTTOM )

    local textEntry = vgui_Create( "DTextEntry", frame )
    textEntry:SetPlaceholderText( "Enter your names here!" )
    textEntry:Dock( BOTTOM )

    local nickNames = {}

    local function SortNameList()
        nameList:Clear()

        local value = searchBar:GetValue()
        local isEmpty = ( !value or #value == 0 )
        for _, name in SortedPairsByValue( nickNames ) do
            if !isEmpty and !string_find( lower( name ), lower( value ) ) then continue end
            local newLine = nameList:AddLine( name ) 
            newLine:SetSortValue( 1, name )
        end
    end
    searchBar.OnChange = SortNameList

    function textEntry:OnEnter( value )
        if !value or #value == 0 then return end
        textEntry:SetText( "" )

        if table_HasValue( nickNames, value ) then
            PlaySound( "buttons/button11.wav" )
            notification_AddLegacy( "This name is already on the list!", 1, 4 )
            return
        end

        PlaySound( "buttons/button15.wav" )
        notification_AddLegacy( "Successfully added " .. value .. " to the NPC nicknames!", 0, 4 )

        local newLine = nameList:AddLine( value )
        newLine:SetSortValue( 1, value )
        nickNames[ #nickNames + 1 ] = value
    end

    function nameList:OnRowRightClick( id, line )
        local value = line:GetSortValue( 1 )

        PlaySound( "buttons/combine_button3.wav" )
        notification_AddLegacy( "Removed " .. value .. " from the NPC nicknames!", 0, 4 ) 

        table_RemoveByValue( nickNames, value )
        nameList:RemoveLine( id )
        SortNameList()
    end

    function confirmButton:DoClick()
        PlaySound( "buttons/button15.wav" )
        frame:Close()

        net.Start( "npcsqueakers_writedata" )
            net.WriteString( TableToJSON( nickNames ) )
            net.WriteString( "names.json" )
        net.SendToServer()
    end

    net.Start( "npcsqueakers_requestdata" )
        net.WriteString( "names.json" )
    net.SendToServer()

    net.Receive( "npcsqueakers_returndata", function()
        local data = JSONToTable( net.ReadString() )
        if !data then return end
        table_Merge( nickNames, data )

        for _, name in SortedPairsByValue( data ) do
            local newLine = nameList:AddLine( name )
            newLine:SetSortValue( 1, name )
        end
        nameList:InvalidateLayout()
    end )
end

concommand.Add( "cl_npcvoicechat_panel_npcspecificvps", OpenClassSpecificVPs )
concommand.Add( "cl_npcvoicechat_panel_npcblacklist", OpenNPCBlacklisting )
concommand.Add( "cl_npcvoicechat_panel_npcwhitelist", OpenNPCWhitelisting )
concommand.Add( "cl_npcvoicechat_panel_npcnicknames", OpenNPCNicknames )

------------------------------------------------------------------------------------------------------------

local function ResetClientSettings( ply )
    for _, cvar in pairs( NPCVC.ClientSettings ) do cvar:SetString( cvar:GetDefault() ) end
end

local function ResetServerSettings( ply )
    if !ply:IsSuperAdmin() then return end

    net.Start( "npcsqueakers_resetsettings" )
        net.WriteUInt( table.Count( NPCVC.ServerSettings ), 8 )
        for cvarName, _ in pairs( NPCVC.ServerSettings ) do
            net.WriteString( cvarName )
        end
    net.SendToServer()
end

concommand.Add( "cl_npcvoicechat_resetsettings", ResetClientSettings )
concommand.Add( "sv_npcvoicechat_resetsettings", ResetServerSettings )

------------------------------------------------------------------------------------------------------------

local function AddToolMenuTabs()
    spawnmenu.AddToolCategory( "Utilities", "YerSoMashy", "YerSoMashy" )
end

local function PopulateToolMenu()
    -- There might be a better way to do this, but this also should work
    local sbNextbotsInstalled = file.Exists( "entities/sb_advanced_nextbot_soldier_base.lua", "LUA" )

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
        for vp, prefix in SortedPairsByValue( NPCVC.VoiceProfiles ) do
            local prettyName = prefix .. vp
            comboBox:AddChoice( prettyName, vp )
            if curVoicePfp == vp then curValue = prettyName end
        end
        comboBox:SetValue( curValue or "None" )

        return comboBox
    end

    local function AddSettingsPanel( panel, client, type, label, convar, helpText, addArgs )
        addArgs = addArgs or {}

        local setting
        if type == "NumSlider" then
            setting = panel:NumSlider( label, convar, addArgs.min or 0, addArgs.max or 1, addArgs.decimals or 0 )
        else
            setting = panel[ type ]( panel, label, convar )
        end
        
        local descText = "ConVar: " .. convar
        if helpText then descText = helpText .. "\n" .. descText end
        ColoredControlHelp( client, panel, descText ) 

        local cvar = GetConVar( convar )
        if client then
            NPCVC.ClientSettings[ convar ] = cvar
        else
            NPCVC.ServerSettings[ convar ] = cvar
        end

        return setting
    end

    spawnmenu.AddToolMenuOption( "Utilities", "YerSoMashy", "NPCSqueakersMenu", "NPC Voice Chat", "", "", function( panel ) 
        local clText = panel:Help( "Client-Side (User Settings):" )
        clText:SetTextColor( clientColor )

        panel:Button( "Reset To Default", "cl_npcvoicechat_resetsettings" )

        AddSettingsPanel( panel, true, "NumSlider", "Voice Volume", "cl_npcvoicechat_playvolume", "Controls the volume of NPC's voices during their voicechat speech", {
            max = 4,
            decimals = 2
        } )
        AddSettingsPanel( panel, true, "NumSlider", "Max Volume Range", "cl_npcvoicechat_playdistance", "How close should you be to the NPC for its voiceline's volume to reach maximum possible volume value", {
            max = 2000
        } )

        local clVoicePfps = GetComboBoxVoiceProfiles( panel, false, "cl_npcvoicechat_spawnvoiceprofile" )
        NPCVC.ClientSettings[ #NPCVC.ClientSettings + 1 ] = GetConVar( "cl_npcvoicechat_spawnvoiceprofile" )
        ColoredControlHelp( true, panel, "The Voice Profile your newly created NPC should be spawned with. Note: This will only work if there's no voice profile specified serverside\nConVar: cl_npcvoicechat_spawnvoiceprofile" )

        AddSettingsPanel( panel, true, "CheckBox", "Global Voice Chat", "cl_npcvoicechat_globalvoicechat", "If NPC's voice chat can be heard globally and not in 3D" )
        AddSettingsPanel( panel, true, "CheckBox", "Display Voice Icon", "cl_npcvoicechat_showvoiceicon", "If a voice icon should appear above NPC while they're speaking or using voicechat" )
        AddSettingsPanel( panel, true, "CheckBox", "Scale Voice Icon", "cl_npcvoicechat_scaleicon", "If voice icons should scale with their owner's sizes" )
        AddSettingsPanel( panel, true, "CheckBox", "Display Voice Popups", "cl_npcvoicechat_showpopups", "If a voicechat popup similar to real player one should display while NPC is using voicechat" )
        AddSettingsPanel( panel, true, "CheckBox", "Draw Popup Profile Picture", "cl_npcvoicechat_popupdrawpfp", "If the NPC's voice popup should draw its profile picture" )

        AddSettingsPanel( panel, true, "NumSlider", "Popup Display Range", "cl_npcvoicechat_popupdisplaydist", "How close should you be to the the NPC in order for its voice popup to display. Set to zero to draw regardless of range", {
            max = 2000
        } )
        AddSettingsPanel( panel, true, "NumSlider", "Popup Fadeout Time", "cl_npcvoicechat_popupfadetime", "Time in seconds required for a voice popup to fully fadeout after not being used", {
            max = 10,
            decimals = 1
        } )

        panel:Help( "Popup Volume Color:" )
        local popupColor = vgui_Create( "DColorMixer", panel )
        panel:AddItem( popupColor )

        popupColor:SetConVarR( "cl_npcvoicechat_popupcolor_r" )
        NPCVC.ClientSettings[ "cl_npcvoicechat_popupcolor_r" ] = vcPopupColorR

        popupColor:SetConVarG( "cl_npcvoicechat_popupcolor_g" )
        NPCVC.ClientSettings[ "cl_npcvoicechat_popupcolor_g" ] = vcPopupColorG

        popupColor:SetConVarB( "cl_npcvoicechat_popupcolor_b" )
        NPCVC.ClientSettings[ "cl_npcvoicechat_popupcolor_b" ] = vcPopupColorB

        ColoredControlHelp( true, panel, "\nThe color of the voice popup when it's liten up by NPC's voice volume" )

        local enemyPopupClr = AddSettingsPanel( panel, true, "CheckBox", "Unique Popup Color For Enemies", "cl_npcvoicechat_uniquepopupcolorforenemies", "If NPCs that are hostile to you should have a different unique popup color" )

        local enemyPopupClrText = panel:Help( "Enemy Popup Volume Color:" )
        local enemyPopupClrMix = vgui_Create( "DColorMixer", panel )
        enemyPopupClrText:SetParent( enemyPopupClrMix )
        panel:AddItem( enemyPopupClrMix )

        enemyPopupClrMix:SetConVarR( "cl_npcvoicechat_enemypopupcolor_r" )
        NPCVC.ClientSettings[ "cl_npcvoicechat_enemypopupcolor_r" ] = vcHostilePopupColorR

        enemyPopupClrMix:SetConVarG( "cl_npcvoicechat_enemypopupcolor_g" )
        NPCVC.ClientSettings[ "cl_npcvoicechat_enemypopupcolor_g" ] = vcHostilePopupColorG

        enemyPopupClrMix:SetConVarB( "cl_npcvoicechat_enemypopupcolor_b" )
        NPCVC.ClientSettings[ "cl_npcvoicechat_enemypopupcolor_b" ] = vcHostilePopupColorB

        if !vcUniqueEnemyPopupClr:GetBool() then
            enemyPopupClrMix:SetEnabled( false )
        end
        function enemyPopupClr:OnChange( value )
            enemyPopupClrMix:SetEnabled( value )
        end

        if !LocalPlayer():IsSuperAdmin() then 
            panel:Help( "" )
            return 
        end

        panel:Help( "------------------------------------------------------------" )
        local svText = panel:Help( "Server-Side (Admin Settings):" )
        svText:SetTextColor( serverColor )

        panel:Button( "Reset To Default", "sv_npcvoicechat_resetsettings" )

        AddSettingsPanel( panel, false, "CheckBox", "Enable NPC Voice Chat", "sv_npcvoicechat_enabled", "Allows to NPCs and nextbots to able to speak voicechat-like using voicelines" )

        panel:Help( "NPC Type Toggles:" )
        AddSettingsPanel( panel, false, "CheckBox", "Standard NPCs", "sv_npcvoicechat_allownpc" )
        if VJBASE_VERSION then AddSettingsPanel( panel, false, "CheckBox", "VJ Base SNPCs", "sv_npcvoicechat_allowvjbase" ) end
        if DrGBase then AddSettingsPanel( panel, false, "CheckBox", "DrGBase Nextbots", "sv_npcvoicechat_allowdrgbase" ) end
        AddSettingsPanel( panel, false, "CheckBox", "2D Chase (Sanic-like) Nextbots", "sv_npcvoicechat_allowsanic" )
        if sbNextbotsInstalled then AddSettingsPanel( panel, false, "CheckBox", "SB Advanced Nextbots", "sv_npcvoicechat_allowsbnextbots" ) end
        if TF2AIHats and TF2AIWeapons then AddSettingsPanel( panel, false, "CheckBox", "Team Fortress 2 Bots", "sv_npcvoicechat_allowtf2bots" ) end
        panel:Help( "------------------------------------------------------------" )

        AddSettingsPanel( panel, false, "CheckBox", "Ignore Gagged NPCs", "sv_npcvoicechat_ignoregaggednpcs", "If NPCs that are gagged by a spawnflag aren't allowed to speak until its removed" )
        AddSettingsPanel( panel, false, "CheckBox", "Slightly Delay Playing", "sv_npcvoicechat_slightdelay", "If there should be a slight delay before NPC plays its voiceline to simulate its reaction time" )
        AddSettingsPanel( panel, false, "CheckBox", "Use Actual Names", "sv_npcvoicechat_userealnames", "If NPCs should use their actual names instead of picking random nicknames")
        AddSettingsPanel( panel, false, "CheckBox", "Use Custom Profile Pictures", "sv_npcvoicechat_usecustompfps", "If NPCs are allowed to use custom profile pictures instead of their model's spawnmenu icon if any is available" )
        AddSettingsPanel( panel, false, "CheckBox", "Only User Profile Pictures", "sv_npcvoicechat_userpfpsonly", "If NPCs are only allowed to use user-placed profile pictures. If there are none of them, fallbacks to addon's profile pictures" )
        AddSettingsPanel( panel, false, "CheckBox", "Use NPC's Model Spawnicon", "sv_npcvoicechat_usemodelicons", "If NPC's profile pictures should first check for their model's spawnmenu icon to use as a one instead of the entity icon.\nNOTE: If the NPC was spawned before, you need to update the data for it's pfp to change" )

        AddSettingsPanel( panel, false, "NumSlider", "Force Speech Chance", "sv_npcvoicechat_forcespeechchance", "If above zero, will set every newly spawned NPC's speech chance to this value. Set to zero to disable", {
            max = 100
        } )

        local minPitch = AddSettingsPanel( panel, false, "NumSlider", "Min Voice Pitch", "sv_npcvoicechat_voicepitch_min", "The lowest pitch a NPC's voice can get upon spawning", {
            min = 10,
            max = 100
        } )
        local maxPitch = AddSettingsPanel( panel, false, "NumSlider", "Max Voice Pitch", "sv_npcvoicechat_voicepitch_max", "The highest pitch a NPC's voice can get upon spawning", {
            min = 100,
            max = 255
        } )

        function minPitch:OnValueChanged( value )
            maxPitch:SetMin( value )
        end
        function maxPitch:OnValueChanged( value )
            minPitch:SetMax( value )
        end
        
        AddSettingsPanel( panel, false, "NumSlider", "Speak Limit", "sv_npcvoicechat_speaklimit", "Controls the amount of NPCs that can use voicechat at once. Set to zero to disable", {
            max = 25
        } )
        AddSettingsPanel( panel, false, "CheckBox", "Limit Doesn't Affect Death", "sv_npcvoicechat_speaklimit_dontaffectdeath", "If the speak limit shouldn't affect NPCs that are playing their death voiceline" )

        AddSettingsPanel( panel, false, "CheckBox", "Speech Chance Affects Death", "sv_npcvoicechat_speechchanceaffectsdeathvoicelines", "If NPC's speech chance should also affect its playing of death voicelines." ) 

        AddSettingsPanel( panel, false, "CheckBox", "Save Voice Data Of Essential NPCs", "sv_npcvoicechat_savenpcdataonmapchange", "If essential NPCs from Half-Life campaigns should save their voicechat data. This will for example prevent them from having a different name when sometimes appearing and etc.\nRecommended to turn off when not playing any campaign!" ) 

        if LambdaVoiceProfiles then
            panel:Help( "Lambda-Related Stuff:" )
            AddSettingsPanel( panel, false, "CheckBox", "Use Lambda Players Nicknames", "sv_npcvoicechat_uselambdanames", "If NPCs should use nicknames from Lambda Players and its addons + modules instead" )
            AddSettingsPanel( panel, false, "CheckBox", "Use Lambda Players Voicelines", "sv_npcvoicechat_uselambdavoicelines", "If NPCs should use voicelines from Lambda Players and its addons + modules instead" )
            AddSettingsPanel( panel, false, "CheckBox", "Use Lambda Players Profile Pictures", "sv_npcvoicechat_uselambdapfppics", "If NPCs should use profile pictures from Lambda Players and its addons + modules instead" )
        end

        local svVoicePfps = GetComboBoxVoiceProfiles( panel, false, "sv_npcvoicechat_spawnvoiceprofile" )
        NPCVC.ServerSettings[ "sv_npcvoicechat_spawnvoiceprofile" ] = GetConVar( "sv_npcvoicechat_spawnvoiceprofile" )
        ColoredControlHelp( false, panel, "The Voice Profile the newly created NPC should be spawned with. Note: This will override every player's client option with this one\nConVar: sv_npcvoicechat_spawnvoiceprofile" )

        AddSettingsPanel( panel, false, "NumSlider", "Voice Profile Spawn Chance", "sv_npcvoicechat_randomvoiceprofilechance", "The chance the a NPC will use a random available Voice Profile as their voice profile after they spawn", {
            max = 100
        } )
        AddSettingsPanel( panel, false, "CheckBox", "Enable Profile Fallback", "sv_npcvoicechat_voiceprofilefallbacks", "If NPC with a voice profile should fallback to standard voicelines instead of playing nothing if its profile doesn't have a specified voice type in it" )

        net.Receive( "npcsqueakers_updatespawnmenu", function()
            UpdateVoiceProfiles()
            GetComboBoxVoiceProfiles( panel, clVoicePfps, "cl_npcvoicechat_spawnvoiceprofile" )
            GetComboBoxVoiceProfiles( panel, svVoicePfps, "sv_npcvoicechat_spawnvoiceprofile" )
        end )

        panel:Help( "------------------------------------------------------------" )

        panel:Button( "NPC Nickname Editor", "cl_npcvoicechat_panel_npcnicknames" )
        ColoredControlHelp( false, panel, "Opens a panel that allows you to add or remove nicknames that NPCs will spawn with." )

        panel:Button( "NPC Voice Chat Blacklist", "cl_npcvoicechat_panel_npcblacklist" )
        ColoredControlHelp( false, panel, "Opens a panel that allows you to blacklist a specific NPC class from using voicechat." )

        panel:Button( "NPC Voice Chat Whitelist", "cl_npcvoicechat_panel_npcwhitelist" )
        ColoredControlHelp( false, panel, "Opens a panel that allows you to whitelist a specific NPC class to use voicechat. Use this if for some reason your NPC didn't count as one or if it's nextbot." )

        panel:Button( "NPC-Specific Voice Profiles", "cl_npcvoicechat_panel_npcspecificvps" )
        ColoredControlHelp( false, panel, "Opens a panel that allows you to assign a voice profile to specific NPC class." )

        panel:Button( "Update Data", "sv_npcvoicechat_updatedata" )
        ColoredControlHelp( false, panel, "Updates and refreshes the nicknames, voicelines and other data required for NPC's proper voice chatting. You should always do it after adding or removing stuff" )
        
        panel:Help( "------------------------------------------------------------" )

        panel:Help( "You can add new voicelines, voice profiles, and profile pictures by doing following the steps below:" )
        panel:Help( "Profile Pictures:" )
        ColoredControlHelp( false, panel, "Go to this path in the game's root directory: 'garrysmod/materials/npcvcdata/custompfps'.\nPut your profile picture images there, but make sure that its format is either .jpg or .png" )
        panel:Help( "Voicelines:" )
        ColoredControlHelp( false, panel, "Go to or create this filepath in the game's root directory: 'garrysmod/sound/npcvoicechat/vo'.\nIn that directory create a folder with the name of your sound's voiceline type and put the soundfile there. The filename doesn't matter, but the sound must be in .wav, .mp3, or .ogg format, have a frequency of 44100Hz, and must be in mono channel.\nThere are currently 8 types of sounds: assist, death, witness, idle, taunt, panic, laugh, and kill" )
        panel:Help( "Voice Profiles:" )
        ColoredControlHelp( false, panel, "Go to or create this filepath in the game's root directory: 'garrysmod/sound/npcvoicechat/voiceprofiles'.\nIn that directory you create a folder with the name of voice profile. After that the steps are the same from the voicelines one" )

        panel:Help( "------------------------------------------------------------" )

        panel:Help( "Voiceline Type Toggles:" )
        AddSettingsPanel( panel, false, "CheckBox", "Idling", "sv_npcvoicechat_allowlines_idle" )
        AddSettingsPanel( panel, false, "CheckBox", "In-Combat Idling", "sv_npcvoicechat_allowlines_combatidle" )
        AddSettingsPanel( panel, false, "CheckBox", "Death", "sv_npcvoicechat_allowlines_death" )
        AddSettingsPanel( panel, false, "CheckBox", "Spot Enemy", "sv_npcvoicechat_allowlines_spotenemy" )
        AddSettingsPanel( panel, false, "CheckBox", "Kill Enemy", "sv_npcvoicechat_allowlines_killenemy" )
        AddSettingsPanel( panel, false, "CheckBox", "Witness Death", "sv_npcvoicechat_allowlines_witnessdeath" )
        AddSettingsPanel( panel, false, "CheckBox", "Assisted", "sv_npcvoicechat_allowlines_assist" )
        AddSettingsPanel( panel, false, "CheckBox", "Spot Danger", "sv_npcvoicechat_allowlines_spotdanger" )
        AddSettingsPanel( panel, false, "CheckBox", "Panic Conditions", "sv_npcvoicechat_allowlines_panicconds" )
        AddSettingsPanel( panel, false, "CheckBox", "Low On Health", "sv_npcvoicechat_allowlines_lowhealth" )

        panel:Help( "------------------------------------------------------------" )

        panel:Help( "Voiceline Type Directory Paths:" )
        ColoredControlHelp( false, panel, "Make sure to update the data after changing one of them!" )
        AddSettingsPanel( panel, false, "TextEntry", "Idle", "sv_npcvoicechat_snddir_idle" )
        AddSettingsPanel( panel, false, "TextEntry", "Taunt", "sv_npcvoicechat_snddir_taunt" )
        AddSettingsPanel( panel, false, "TextEntry", "Death", "sv_npcvoicechat_snddir_death" )
        AddSettingsPanel( panel, false, "TextEntry", "Kill", "sv_npcvoicechat_snddir_kill" )
        AddSettingsPanel( panel, false, "TextEntry", "Laugh", "sv_npcvoicechat_snddir_laugh" )
        AddSettingsPanel( panel, false, "TextEntry", "Witness", "sv_npcvoicechat_snddir_witness" )
        AddSettingsPanel( panel, false, "TextEntry", "Assist", "sv_npcvoicechat_snddir_assist" )
        AddSettingsPanel( panel, false, "TextEntry", "Panic", "sv_npcvoicechat_snddir_panic" )
        panel:Help( "" )
    end )
end

hook.Add( "AddToolMenuTabs", "NPCSqueakers_AddToolMenuTab", AddToolMenuTabs )
hook.Add( "PopulateToolMenu", "NPCSqueakers_PopulateToolMenu", PopulateToolMenu )