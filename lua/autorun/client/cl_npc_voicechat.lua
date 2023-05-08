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
local vcPlayDist        = CreateClientConVar( "cl_npcvoicechat_playdistance", "250", nil, nil, "Controls how far the NPC voices can be clearly heard from. Requires global voicechat to be disabled", 0 )
local vcShowIcon        = CreateClientConVar( "cl_npcvoicechat_showvoiceicon", "1", nil, nil, "If a voice icon should appear above NPC while they're speaking?", 0, 1 )
local vcShowPopups      = CreateClientConVar( "cl_npcvoicechat_showpopups", "1", nil, nil, "Allows to draw and display a voicechat popup when NPCs are currently speaking", 0, 1 )
local vcPopupDist       = CreateClientConVar( "cl_npcvoicechat_popupdisplaydist", "0", nil, nil, "How close should the NPC be for its voice popup to show up? Set to zero to show up regardless of distance", 0 )
local vcPopupFadeTime   = CreateClientConVar( "cl_npcvoicechat_popupfadetime", "2", nil, nil, "Time in seconds needed for popup to fadeout after stopping playing or being out of range", 0, 5 )
local vcPopupDrawPfp    = CreateClientConVar( "cl_npcvoicechat_popupdrawpfp", "1", nil, nil, "If the NPC's voice popup should draw its profile picture", 0, 1 )

local vcPopupColorR     = CreateClientConVar( "cl_npcvoicechat_popupcolor_r", "0", nil, nil, "The red color of voice popup when the NPC is using it", 0, 255 )
local vcPopupColorG     = CreateClientConVar( "cl_npcvoicechat_popupcolor_g", "255", nil, nil, "The green color of voice popup when the NPC is using it", 0, 255 )
local vcPopupColorB     = CreateClientConVar( "cl_npcvoicechat_popupcolor_b", "0", nil, nil, "The blue color of voice popup when the NPC is using it", 0, 255 )

CreateClientConVar( "cl_npcvoicechat_spawnvoiceprofile", "", nil, true, "The Voice Profile your newly created NPC should be spawned with. Note: This will only work if there's no voice profile specified serverside" )

NPCVC_SoundEmitters         = NPCVC_SoundEmitters or {}
NPCVC_VoicePopups           = {}
NPCVC_VoiceProfiles         = {}
NPCVC_CachedMaterials       = NPCVC_CachedMaterials or {}
NPCVC_CachedNamePhrases     = NPCVC_CachedNamePhrases or {}

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

local function GetSoundSource( ent )
    local netFunc, srcEnt = ent.GetSoundSource
    if netFunc then
        srcEnt = netFunc( ent )
    else
        srcEnt = ent:GetNW2Entity( "npcsqueakers_soundsrc", NULL )
    end
    return srcEnt, netFunc
end

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

        local srcEnt = GetSoundSource( ent )
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
            voicePopup.Entity = ent
            voicePopup.Sound = snd
            voicePopup.LastPlayPos = playPos
        else
            local pfpPic, pfpMat = vcData.ProfilePicture
            if pfpPic then
                pfpMat = NPCVC_CachedMaterials[ pfpPic ]
                if pfpMat == nil then pfpMat = Material( pfpPic ) end
                if pfpMat and pfpMat:IsError() then pfpMat = nil end
                NPCVC_CachedMaterials[ pfpPic ] = ( pfpMat or false )
            end

            local nickName = vcData.Nickname
            if vcData.UsesRealName then
                local nickPhrase = NPCVC_CachedNamePhrases[ nickName ]
                if !nickPhrase then
                    nickPhrase = GetPhrase( nickName )
                    NPCVC_CachedNamePhrases[ nickName ] = nickPhrase
                end
                nickName = nickPhrase
            end
            if #nickName > 24 then 
                nickName = string_sub( nickName, 0, 22 ) .. "..." 
            end

            NPCVC_VoicePopups[ entIndex ] = {
                Nick = nickName,
                Entity = ent,
                Sound = snd,
                LastPlayPos = playPos,
                ProfilePicture = pfpMat,
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
        local srcEnt, netFunc = ( IsValid( ent ) and GetSoundSource( ent ) )

        if !IsValid( ent ) or !IsValid( snd ) or snd:GetState() == GMOD_CHANNEL_STOPPED or netFunc and !IsValid( srcEnt ) and ent:GetRemoveOnNoSource() then
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
            local srcEnt = GetSoundSource( ent )
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

        DrawText( vcData.Nick, "GModNotify", drawX + 43.5, drawY + 9, popup_BaseClr, TEXT_ALIGN_LEFT )
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

hook.Add( "Tick", "NPCSqueakers_UpdateSounds", UpdateSounds )
hook.Add( "PreDrawEffects", "NPCSqueakers_DrawVoiceIcons", DrawVoiceIcons )
hook.Add( "HUDPaint", "NPCSqueakers_DrawVoiceChat", DrawVoiceChat )
hook.Add( "CreateClientsideRagdoll", "NPCSqueakers_OnCreateClientsideRagdoll", OnCreateClientsideRagdoll )

------------------------------------------------------------------------------------------------------------

NPCVC_ClientSettings    = NPCVC_ClientSettings or {}
NPCVC_ServerSettings    = NPCVC_ServerSettings or {}

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
        
        local iconMat = NPCVC_CachedMaterials[ class ]
        if !iconMat then
            iconMat = Material( "entities/" .. class .. ".png" )
            if iconMat:IsError() then iconMat = Material( "vgui/entities/" .. class ) end
        end
        if iconMat != false and !iconMat:IsError() then 
            npcImg:SetMaterial( iconMat )
        end
        NPCVC_CachedMaterials[ class ] = ( iconMat or false ) 

        local npcName = vgui_Create( "DLabel", npcPanel )
        local prettyName = ( npcList[ class ] and npcList[ class ].Name )
        npcName:SetText( prettyName or class )
        npcName:Dock( TOP )

        function npcImg:DoClick()
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
            for vp, prefix in SortedPairsByValue( NPCVC_VoiceProfiles ) do
                vpSelection:AddChoice( prefix .. vp, vp )
            end

            local doneButton = vgui_Create( "DButton", vpSelectFrame )
            doneButton:Dock( BOTTOM )
            doneButton:SetText( "Done" )

            function doneButton:DoClick()
                local vpName, vpSelected = vpSelection:GetSelected()
                if vpSelected and #vpSelected != 0 then 
                    PlaySound( "buttons/button15.wav" )
                    notification_AddLegacy( "Successfully assigned " .. prettyName .. "'s voice profile to " .. vpName .. "!", 0, 4 )

                    npcListPanel:AddLine( ( prettyName and prettyName .. " (" .. class .. ")" or class ), vpSelected, class )
                    npcPanel:Remove()
                    changedSomething = true
                end

                vpSelectFrame:Remove()
            end
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
        AddNPCPanel( line:GetColumnText( 3 ) )
        self:RemoveLine( id )
        changedSomething = true
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
            if !listData then continue end

            local prettyName = listData.Name
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

    local npcList = list_Get( "NPC" )
    local changedSomething = false

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

        local iconMat = NPCVC_CachedMaterials[ class ]
        if !iconMat then
            iconMat = Material( "entities/" .. class .. ".png" )
            if iconMat:IsError() then iconMat = Material( "vgui/entities/" .. class ) end
        end
        if iconMat != false and !iconMat:IsError() then 
            npcImg:SetMaterial( iconMat )
        end
        NPCVC_CachedMaterials[ class ] = ( iconMat or false ) 

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
        AddNPCPanel( line:GetColumnText( 2 ) )
        self:RemoveLine( id )
        changedSomething = true
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
            if !listData then continue end

            local prettyName = listData.Name
            npcListPanel:AddLine( ( prettyName and prettyName .. " (" .. class .. ")" or class ), class )

            for _, npcPanel in pairs( npcIconLayout:GetChildren() ) do
                if npcPanel:GetNPC() == class then npcPanel:Remove() break end 
            end
        end
    end )
end

local function ResetClientSettings( ply )
    for _, cvar in pairs( NPCVC_ClientSettings ) do cvar:SetString( cvar:GetDefault() ) end
end

local function ResetServerSettings( ply )
    if !ply:IsSuperAdmin() then return end

    net.Start( "npcsqueakers_resetsettings" )
        net.WriteUInt( table.Count( NPCVC_ServerSettings ), 6 )
        for cvarName, _ in pairs( NPCVC_ServerSettings ) do
            net.WriteString( cvarName )
        end
    net.SendToServer()
end

concommand.Add( "cl_npcvoicechat_panel_npcspecificvps", OpenClassSpecificVPs )
concommand.Add( "cl_npcvoicechat_panel_npcblacklist", OpenNPCBlacklisting )
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
        for vp, prefix in SortedPairsByValue( NPCVC_VoiceProfiles ) do
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
        elseif type == "CheckBox" then
            setting = panel:CheckBox( label, convar )
        end
        if helpText then ColoredControlHelp( client, panel, helpText ) end

        local cvar = GetConVar( convar )
        if client then
            NPCVC_ClientSettings[ convar ] = cvar
        else
            NPCVC_ServerSettings[ convar ] = cvar
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
        NPCVC_ClientSettings[ #NPCVC_ClientSettings + 1 ] = GetConVar( "cl_npcvoicechat_spawnvoiceprofile" )
        ColoredControlHelp( true, panel, "The Voice Profile your newly created NPC should be spawned with. Note: This will only work if there's no voice profile specified serverside" )

        AddSettingsPanel( panel, true, "CheckBox", "Global Voice Chat", "cl_npcvoicechat_globalvoicechat", "If NPC's voice chat can be heard globally and not in 3D" )
        AddSettingsPanel( panel, true, "CheckBox", "Display Voice Icon", "cl_npcvoicechat_showvoiceicon", "If a voice icon should appear above NPC while they're speaking or using voicechat" )
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
        NPCVC_ClientSettings[ "cl_npcvoicechat_popupcolor_r" ] = GetConVar( "cl_npcvoicechat_popupcolor_r" )

        popupColor:SetConVarG( "cl_npcvoicechat_popupcolor_g" )
        NPCVC_ClientSettings[ "cl_npcvoicechat_popupcolor_g" ] = GetConVar( "cl_npcvoicechat_popupcolor_g" )

        popupColor:SetConVarB( "cl_npcvoicechat_popupcolor_b" )
        NPCVC_ClientSettings[ "cl_npcvoicechat_popupcolor_b" ] = GetConVar( "cl_npcvoicechat_popupcolor_b" )

        ColoredControlHelp( true, panel, "\nThe color of the voice popup when it's liten up by NPC's voice volume" )

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

        AddSettingsPanel( panel, false, "CheckBox", "Ignore Gagged NPCs", "sv_npcvoicechat_ignoregagged", "If NPCs that are gagged by a spawnflag aren't allowed to speak until its removed" )
        AddSettingsPanel( panel, false, "CheckBox", "Slightly Delay Playing", "sv_npcvoicechat_slightdelay", "If there should be a slight delay before NPC plays its voiceline to simulate its reaction time" )
        AddSettingsPanel( panel, false, "CheckBox", "Use Actual Names", "sv_npcvoicechat_userealnames", "If NPCs should use their actual names instead of picking random nicknames")
        AddSettingsPanel( panel, false, "CheckBox", "Use Custom Profile Pictures", "sv_npcvoicechat_usecustompfps", "If NPCs are allowed to use custom profile pictures instead of their model's spawnmenu icon if any is available" )

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
        AddSettingsPanel( panel, false, "CheckBox", "Limit Doesn't Affect Death and Panic", "sv_npcvoicechat_speaklimit_dontaffectdeathpanic", "If the speak limit shouldn't affect NPCs that are playing their death or panicking voicelines" )

        if LambdaVoiceProfiles then
            panel:Help( "Lambda-Related Stuff:" )
            AddSettingsPanel( panel, false, "CheckBox", "Use Lambda Players Nicknames", "sv_npcvoicechat_uselambdanames", "If NPCs should use nicknames from Lambda Players and its addons + modules instead" )
            AddSettingsPanel( panel, false, "CheckBox", "Use Lambda Players Voicelines", "sv_npcvoicechat_uselambdavoicelines", "If NPCs should use voicelines from Lambda Players and its addons + modules instead" )
            AddSettingsPanel( panel, false, "CheckBox", "Use Lambda Players Profile Pictures", "sv_npcvoicechat_uselambdapfppics", "If NPCs should use profile pictures from Lambda Players and its addons + modules instead" )
        end

        local svVoicePfps = GetComboBoxVoiceProfiles( panel, false, "sv_npcvoicechat_spawnvoiceprofile" )
        NPCVC_ServerSettings[ "sv_npcvoicechat_spawnvoiceprofile" ] = GetConVar( "sv_npcvoicechat_spawnvoiceprofile" )
        ColoredControlHelp( false, panel, "The Voice Profile the newly created NPC should be spawned with. Note: This will override every player's client option with this one" )

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
        
        panel:Button( "NPC Voice Chat Blacklist", "cl_npcvoicechat_panel_npcblacklist" )
        ColoredControlHelp( false, panel, "Opens a panel that allows you to blacklist a specific NPC class from using voicechat." )

        panel:Button( "NPC-Specific Voice Profiles", "cl_npcvoicechat_panel_npcspecificvps" )
        ColoredControlHelp( false, panel, "Opens a panel that allows you to assign a voice profile to specific NPC class." )

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
        panel:Help( "" )
    end )
end

hook.Add( "AddToolMenuTabs", "NPCSqueakers_AddToolMenuTab", AddToolMenuTabs )
hook.Add( "PopulateToolMenu", "NPCSqueakers_PopulateToolMenu", PopulateToolMenu )