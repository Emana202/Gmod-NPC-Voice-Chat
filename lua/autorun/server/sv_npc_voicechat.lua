local net = net
local ipairs = ipairs
local pairs = pairs
local IsValid = IsValid
local SimpleTimer = timer.Simple
local random = math.random
local string_sub = string.sub
local Clamp = math.Clamp
local table_Empty = table.Empty
local cvarFlag = ( FCVAR_ARCHIVE + FCVAR_REPLICATED )
local RealTime = RealTime
local Rand = math.Rand
local ents_GetAll = ents.GetAll
local CurTime = CurTime
local ents_Create = ents.Create
local table_GetKeys = table.GetKeys
local table_Copy = table.Copy
local table_RemoveByValue = table.RemoveByValue
local FindInSphere = ents.FindInSphere
local IsSinglePlayer = game.SinglePlayer
local StoreEntityModifier = duplicator.StoreEntityModifier
local file_Exists = file.Exists
local file_Open = file.Open
local file_Find = file.Find
local JSONToTable = util.JSONToTable
local TableToJSON = util.TableToJSON

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
local voicelineDirs = { [ "idle" ] = "npcvoicechat/vo/idle/", [ "witness" ] = "npcvoicechat/vo/witness/", [ "death" ] = "npcvoicechat/vo/death/", [ "panic" ] = "npcvoicechat/vo/panic/", [ "taunt" ] = "npcvoicechat/vo/taunt/", [ "kill" ] = "npcvoicechat/vo/kill/", [ "laugh" ] = "npcvoicechat/vo/laugh/", [ "assist" ] = "npcvoicechat/vo/assist/" }

-- Dear god...
local defaultNames = { "Based Kleiner", "The Real Zeta Player", "Beta", "Generic Name 1", "Ze Uberman", "Q U A N T U M P H Y S I C S", "portable fridge", "Methman456", "i rdm kids for breakfast", "Cheese Adiction Therapist", "private hoovy", "Socks with Sandals", "Solar", "AdamYeBoi", "troll", "de_struction and de_fuse", "de_rumble", "decoymail", "Damian", "BrandontheREDSpy", "Braun", "brent13", "BrokentoothMarch", "BruH", "BudLightVirus", "Call of Putis", "CanadianBeaver", "Cake brainer", "cant scream in space", "CaptGravyBoness", "CaraKing09", "CarbonTugboat", "CastHalo", "cate", "ccdrago56", "cduncan05", "Chancellor_Ant", "Changthunderwang", "Charstorms", "Ch33kCLaper69", "Get Good Get Lmao Box", "Atomic", "Audrey", "Auxometer", "A Wise Author", "Awtrey516", "Aytx", "BabaBooey", "BackAlleyDealerMan", "BalieyeatsPizza", "ballzackmonster", "Banovinski", "bardochib", "BBaluka", "Bean man", "Bear", "Bearman_18", "beeflover100", "Albeon Stormhammer", "Andromedus", "Anilog", "Animus", "Sorry_an_Error_has_Occurred", "I am the Spy", "engineer gaming", "Ze Uberman", "Regret", "Sora", "Sky", "Scarf", "Graves", "bruh moment", "Garrys Mod employee", "i havent eaten in 69 days", "DOORSTUCK89", "PickUp That Can Cop", "Never gonna give you up", "if you are reading this, ur mom gay ", "The Lemon Arsonist", "Cave Johnson", "Chad", "Speedy", "Alan", "Alpha", "Bravo", "Delta", "Charlie", "Echo", "Foxtrot", "Golf", "Hotel", "India", "Juliet", "Kilo", "Lima", "Lina", "Mike", "November", "Oscar", "Papa", "Quebec", "Romeo", "Sierra", "Tango", "Uniform", "Victor", "Whiskey", "X-Ray", "Yankee", "Zulu", "Flare", "Brian", "Frank", "Blaze", "Rin", "Bolt", "runthemingesarecoming", "Brute", "Snare", "Matt", "Arc", "VeeVee", "Serv", "Manjaro", "Sentinal", "Night", "Cayde", "Ranger", "Coach", "Bob Ross", "Mossman", "Nova", "drop10kthisisamug2874", "NUCCCLLEEEEEOOOOOOON", "u mad", "TheAdminge", "Trace", "Kelly", "Marauder", "AVATAR", "Scout", "Mirage", "Spark", "Jolt", "Ghost", "Summer", "Breenisgay69", "Dr Breen", "Combino", "Beowulf", "Heavy Weapons Guy", "GodFather", "Cheaple", "Desmond the epic", "Despairaity", "Destroyer_V0", "Devout Buddhist", "DingoGorditas", "DiscoDodgeBall", "Doc Johnson", "Dogmeat Tactical Vest", "Dogboy", "D O I N K", "ThatMW2Squeaker", "EBOI BOI BOI BOI BOI BOI BOI", "Condescending Idiot", "CoolColton947", "CordingWater6", "Cpt_Core", "Crofty", "Crusader", "Ctoycat", "Cyclops", "Daddy_Debuff", "dallas", "DaLocust56", "Danny DeVito", "DaNub2038", "DarkNinjaD", "DarthHighGround", "DarthOobleck", "Dassault Mirage 2000C", "Davidb16", "D4rp_b0y", "Ruzzk1y", "SanicYT948", "sanitter", "Sanity", "Schutzhund", "scipion34", "Scotty2Hotty", "Seltzer", "Senior Cangrejo", "sfingers02", "Sharkgoat", "SharkyShark", "Shawty Like A Melody", "sh00shyb0i", "ShrekYeeter69", "Shrubster", "SirSamTheMan", "skinny peen", "Skulleewag395", "SleepingWarkat", "Sleipnlr", "Small PP Man", "SmortSocks", "Snapsro94", "Snipeshot556", "Snoot", "remember_no_russian", "Res", "ricefouboi", "rickymicdoo", "Rigatoni", "Robo7988143", "Rocketeer097", "Rollinwind", "rolltide10032", "Rome12310", "rushbuild", "mason the numbers what do they mean", "onin ring", "0nyx", "oofiet", "Orlorin_Foolofatook26", "pablo", "Paft_Dunk", "Panther0706", "Patrick", "PD53", "Pedro", "Peel1", "PenaPVP", "Penguan", "pepegonzalez2006", "Pescaxo", "phatty", "Piard", "Pickles", "Pigeon", "PilotJames007", "Pilotlily", "Piratenkapitan", "PixelG", "planewithnocanards", "platypus429", "Plumpotato47", "PM Prayuth", "poop_sock6969", "PollutionDieingPlanet", "Popsicle-Biscuit", "portable fridge", "Potatogamer555", "Prinz Eugen007", "PrivateWings", "PuercoVolador", "Purple Toyota AE87", "Pyromaniac", "B", "Quacker The Ducker", "Quadrapuds", "Obama", "obamas-last-name", "Aria", "0nE", "FluffySkunkBoy", "John117", "Kanye Bear", "NASCAR FAN 48", "Nightengale537", "Painini", "picklface", "Slavic_Chicken", "Snoucher", "Special", "wheatly_crab", "Yuri Kuroyanagi", "Doof", "Doritos Toasted Corn Tortilla Chips", "Doubletimes", "Dragon", "Adrian", "Umbreon-Kun", "Im happy :D", "Im Sad D:", "Dead Meme", "Kohan-Kun", "Juan", "Chunky Joe", "Slyblindfox", "Trump", "Ronald", "Kortex", "Kim Jack Off", "Aimlocked", "KloGuy", "Chucky", "Volcano", "Doge Mint", "JackTheRipper", "Just a Cardboard Box", "~Erim~", "muesli", "Saiko", "aoihitsuji", "Reayr1", "Mekako", "ddaydeath", "Str00kerX", "Yuki", "Rena.", "cOnFuSeD", "terminator YD", "Kylin", "Seki", "Osmund", "Botulism Betty", "miyuki", "Pway pway", "TKO | gag0!", "Styx", "/sng/", "OWO", "Kr@zZy", "c0rsair", "nexcor", "pr3st0", "663", "V0id", "Killing Frenzy", "Campers Death", "You make me Laugh", "killaura", "Violently Happy", "Make my Day", "Pissed Off", "Bloodlust", "b02fof", "Zap!", "Dredd", "Fuzzey", "Bucus", "mokku", "A Professional With Standards", "Archimedes!", "Glorified Toaster with Legs", "Yana", "Your pet turtle", "You smell bad", "You smell nice", "I'm real", "Let's make children", "chen y", "NotDuckie", "De_stroyed", "nabongS", "h8 exam", "Crazii", "i h8 myself", "jowak1n", "beyluta", "natty_the_great", "ernest_aj", "bored", "hambug | buying skins", "Kiwino", "farn", "hezzy", "misty :3", "taFFy", "Kei", "I love you", "Sasucky", "eisoptrophobia.", "Yzui", "VKDrummer", "GDliZy", "Schizo x.O", "Yowza", "Hikari", "Niltf", "Kiruh", "caKuma", "Inkou PM", "I wish i was dead", "iamsleepless", "Hackyou", "Sokiy", "Kairu", "hatihati", "tarumaru", "berthe", "MB295", "Jumo", "kirkimedes", "Souless", "LamZee", "Aya-Chan", "gvek", "El Jägermeister", "ikitakunai", "Meti ", "VyLenT", "AlesTA", "Remi", "FTruby", "Touka_", "henkyyi", "Nitrogen09", "moyazou", "chamaji", "ramjam18", "VyYui", "tsumiki", "__dd", "Jushy", "TANUKANA", "Aeyonna | loving you hurts", "Alux.", "Young Jager", "Exhausted Life", "A E S T H E T I C", "Thomas_", "Ross Scarlet", "sonamed", "kuben", "Loord", "pasha", "Neo", "GoodRifle", "alex", "xF", "tb", "karl", "Virgo", "Savage", "rita", "prom1se", "xiaoe", "karrigan", "ArcadioN", "Friis", "wazorN", "suraNga", "minet", "j$", "zonic H$", "trace", "ave", "Sunde ACEEE", "Maximus", "Snappi", "xone", "luffeb", "katulen", "Strangelet", "AllThatGlitters21", "BreakingNYC", "DancingCrazy351", "fish be like i spendz da sack", "Darkrogue20", "davedays", "DieAussenseiter", "DragonCharlz", "eddysson86", "ef12striker", "EllesGlitterGossip", "esmeedenters", "HeadsUpLisa | Lwoosers", "hotforwords", "Düktor", "IntelExtremeMasters", "Monarch5150", "mouzmovie", "LUlyuo", "NCIXcom", "RayWilliamJohnson", "RubberRoss ", "seductioncoach", "septinho", "soundlyawake", "Blacklegion104 ", "ICANHAZHEADSHOT ", "so4p | Lwoosers", "gg_legol4s3rZ7", "Dert", "HDstarcraft ", "Husky", "h0N123", "Da-MiGhtY 4357", "NetManiac", "Kyu >3<", ">PartiZan<", "K!110grAmm", "SchtandartenFuhrer", "mu1ti-K!ll", "=ZL0Y=", "HeadKilla ==(oo)=>", "dub", "Kara", "Mechano!d", "3v!LKilla", "viz0r", "MiXa", "DiGGeR", "=GRoMoZeKA=", "ZveroBoy", "ahl.", "bds.", "brunk", "ElemenT", "fisker", "goseY", "Potti", "Morda", "n0name| S>Keys B>Knives", "NiTron", "Normal Human", "xXSniper_MainXx", "Left Foot In", "Right Foot Out", "Left Handed", "Calcium", "Dinnerbone", "Terrible Terror", "Shoot Me", "Aquatic Mammal", "Poopy Joe", "Free Stuff?", "Needs More Salt", "Duck Feet", "Impossibly Epic", "Joe Mamma", "Catapult of Pain", "Drunk and Scottish", "Half Life 3", "The Last Chip", "Pete", "Mercedes Benz", "Vergil", "FriskyRisky", "Bad Cop", "PersonCake", "SoundAngels", "StrongChase", "Sultryla", "Switzersu", "TagzRip", "TalentCover", "Telemil", "Warrameha", "MrMuskyHusky", "ImBoosted", "PanzerKommandant|8thPanzer", "johnzeus19", "Dunnionringz", "The Helper", "annajnavarro", "Lévi", "Fat Whale", "God HATES you!", "vintige kratskrag", "Who?", "Demoman Takes Skill!", "DohnJoe", "Santa Claus Schoolgirl", "Botulism Betty", "Straight from botnames.txt!", "Blessed To Moonwalk", "Chris P. Bacon", "Consume your Calcium", "rubbedsaltwound", "Content Quality Control", "SpamCracker", "Alcohol + Poor Life Decisions", "salad", "i dont sleep", "Kritty Kat", "Headshot!", "Mini-Biscuits Rights Activist.", "I'm not gay, but $20 is $20", "Dr. Mantis Toboggan", "The Buttstaber", "2 FAST 4 U", "The Living Lawn Mower ", "Don't Fuckle With Shuckle", "Yolo Swaggins", "Suppository Breadcrumbs", "The Inhuman Scorch", "Honey I healed the Heavy", "Drinking + Driving", "spicy comments", "The Terrible Spicy Tea", "Thomas the Wank Engine", "Special Needs Engineer", "A Strange Festive Newt Gingrich", "A Sexually Attractive Cactus", "Swaghetti Yolonaise", "butt soup ", "Alcoholic Fat Guy", "Afraid Egg", "It's Legal in Japan", "I'm So Meta Even This Acronym.", "Unusual Foppish Boner", "Awkward Cuddle Boner", "A Distinctive lack of YOU!", "The Spanish Inquisition", "A Duck On Quack", "obesity related illness.", "ASS PANCAKES!", "Bodyshots Johnson", "Nein Lives.", "Dispenser (Target Practice)", "Country-Steak:Sauce", "Sock Full of Shame", "An overdose of French Toast", "One Kawaii MotherFucker", "Smokey Joe", "The Spicy Meatball.", "I Eat Toddlers", "Cunning Linguist", "3DayOldTeleportedBread", "Replay", "The Intense Hoovy Main", "?", "About_30_ninjas", "Ithoughtshewaslvl18 ", "404 GF not found  ", "IfIDiedIWasAFK ", "Jimmies Rustler", "go go gadget aimbot ", "Neil, Intergalactic Grandpa", "General Steiner", "Crazy Dewfus", "Sympatriotic", "doge", "Warmachine", "Diarrhea On Wheels", "Roasty my Toasty", "Steve Handjobs", "the hottest cheeto ever, man", "Imagine actually dying to WM1", "Vince makes you say Shamwow", "PyrosAreAssholes", "Hilarious Bread", "poo c", "19 year old virgin", "Parasitic watermelon", "Welcome to Costco", "Sick Marmalade, Grandpa ", "buttsaggington", "Mother Fucking Oedipus", "I wonder what cum taste likes", "Money, Hoes and Spaghetti-O's", "Mister Lister the Sister Fister", "Jonk", "Diet Cocaine", "Suspiciously Slow Scout", "Space Gandhi", "urine for a treat", "Delusional Arsonist", "Yung Micheal", "Old Man of America", "Spam & Heals Inc.", "yes_u_suck", "I_YELL_ALOT", "DroolTool", "A very fat man named Minh", "heavy from team fortress 5", "Cheesus Evangelionist", "Just a noob", "WetHitter", "Unsubscribe", "WeThePizza", "LactoseTheIntolerant", "MagicLOL", "getVACburned", "BeatdownMachine", "Such_A_Noob", "Balloonicorn", "Phosuphi", "BeardNoMore", "CutthroatChicken", "YourNameOnMySword", "BarryMcKackiner", "MyAxeYourFace", "Bagelofdeath", "Window Maker", "Rock8Man", "UsedFood", "beepbeepimajeep", "bitpull ", "PatMaximum", "you snoze you loze", "I_fap_twohanded", "DixonCider", "NoChildSupport", "Don't Shoot I'm a virgin ", "Pvt. Parts ", "BigD_McGee ", "McD'sHashbrown ", "SnackBitesWillRule ", "Stalin's Organ.", "BadUsernameSince2015", "NoDadNotTheBelt", "BrokenBoneBroker", "DontTouchThat", "InfinityLag", "NullPointer ", "FrankTheCrank", "Mexican't ", "HouseOfChards", "Playing TF2 on A Toaster", "noob", "SpawnOfChaos", "I'm a Nokia ", "Solid Steak", "Killavanilla", "Tactical Toast", "OmgMyNameWontFi ", "Does you has? ", "niche one ", "he ded lol", "Testicular Thorsion ", "you_sun_of_a_beach ", "that's DOCTOR noob 4u ", "hoehoehoe", "PonySlaystation ", "suck my clock", "Muffled Fart ", "ClickSwitch", "GarbageRubberBand", "PennyUnwise", "Kacktus ", "Propanetankhank ", "HeyimGey. ", "Lol a shaved donkey", "De_stroyed", "i h8 myself", "eisoptrophobia.", "Respect your mom", "I wish i was dead", "CakeStealer", "KinosaurusRex", "Maximus", "SpyCrab", "MassTenderizer", "ParrotGal75", "Mentlegen Terrorist", "La Baguette Faguette", "Soup Can", "Lewdest Robot", "Hella Thicc", "Foot Lover Berry", "Hell is NOT okay", "unnamed", "Player", "HereComesThePainTrain", "lololol", "Nope.avi", "Snipping Tool", "Fax Machine", "m0tiVACation", "Just a Cardboard Box", "xXDark_LordXx", "expee", "????????", "nWord", "NotAnEngineer", "KidFromSchool", "Phone", "OmqItswOOdy", "canon father", "dart invader", "FreeeeeIpad", "nonuts", "E", "Carl Johnson", "Big Smoke", "CritsAreFair", "A Commie", "Prankster_Gangster", "Dad", "im going to area51", "AliveFace", "CornCakes", "Morgan", "goD", "Scunts_Sux", "Bruh231", "nikolai.thegamer 2019", "Pixels", "Mark", "Jon", "Garfield", "a pay 2 play", "a free 2 play", "yeet", "ESP", "a bunch of 0s and 1s", "Hitscan", "LmaoBox", "I DIE !", "Barny", "Gordon Freeman", "Drunken Wretch", "No", "IDontHaveAName", "PewDiePie", "Water Sheep", "Sandvich", "Mega dumboon", "MetalLegend", "A girl", "LessCrits", "Mario", "Loogi", "Sven", "Joergen", "'Merica fok ye", "Serbia", "Fonsi", "Despacito", "Pussy Memes", "Hail", "Bird", "SuperNatural", "SomeBruh", "This Guy", "Soulfull", "Undead", "Vehicle", "210Hill", "Bush-Dog", "The Wall", "The Bitch", "FishFace", "BFG 9000", "Bushman", "LucksMan", "Totally a human", "Shadows", "Nuclear Fruitcake", "Gold Steel", "scooteroni", "Mr.Poot", "liveMeat", "TalkyFan", "miss appauling", "Blue Man", "Red Man", "Gray Man", "Oblivious Man", "Rebel", "Havana OOONANA", "superguy", "Abraham da great", "George chopdowninnocenttree", "Franklin Deez nutz", "a wizard", "What", "thats nacho cheeze", "lesbian", "Gay", "papa Pete", "SpookyMint", "keegasp00ks", "Shock" }

NPCVC_NickNames = NPCVC_NickNames or {}
NPCVC_VoiceLines = NPCVC_VoiceLines or {}
NPCVC_ProfilePictures = NPCVC_ProfilePictures or {}

util.AddNetworkString( "npcsqueakers_playsound" )
util.AddNetworkString( "npcsqueakers_sndduration" )
util.AddNetworkString( "npcsqueakers_updatespawnmenu" )

net.Receive( "npcsqueakers_sndduration", function()
    local ent = net.ReadEntity()
    if IsValid( ent ) then ent.SpeechPlayTime = ( RealTime() + net.ReadFloat() ) end
end )

duplicator.RegisterEntityModifier( "NPC VoiceChat - NPC's Voice Data", function( ply, ent, data )
    ent.NPCVC_IsDuplicated = true
    ent.NPCVC_SpeechChance = data.SpeechChance
    ent.NPCVC_VoicePitch = data.VoicePitch
    ent.NPCVC_Nickname = data.NickName
    ent.NPCVC_ProfilePicture = data.ProfilePicture
    ent.NPCVC_VoiceProfile = data.VoiceProfile
    ent.NPCVC_PfpBackgroundColor = data.PfpBackgroundColor
end )

file.CreateDir( "npcvoicechat" )

local function UpdateData( ply )
    if IsValid( ply ) and !ply:IsSuperAdmin() then return end

    local nameTbl
    local names = file_Open( "npcvoicechat/names.json", "r", "DATA" )
    if !names then
        names = file_Open( "npcvoicechat/names.json", "w", "DATA" )
        if names then names:Write( TableToJSON( defaultNames ) ); names:Close() end
    else
        nameTbl = names:Read( names:Size() )
        names:Close()
    end
    NPCVC_NickNames = ( nameTbl and  JSONToTable( nameTbl ) or defaultNames )

    table_Empty( NPCVC_VoiceLines )
    for voiceType, sndDir in pairs( voicelineDirs ) do
        local lineTbl = {}
        local snds = file_Find( "sound/" .. sndDir .. "*", "GAME" )
        for _, snd in ipairs( snds ) do lineTbl[ #lineTbl + 1 ] = sndDir .. snd end
        NPCVC_VoiceLines[ voiceType ] = lineTbl
    end

    table_Empty( NPCVC_ProfilePictures )
    local pfpPics = file_Find( "materials/npcvcdata/profilepics/*", "GAME" )
    for _, pfpPic in ipairs( pfpPics ) do
        NPCVC_ProfilePictures[ #NPCVC_ProfilePictures + 1 ] = "npcvcdata/profilepics/" .. pfpPic
    end

    net.Start( "npcsqueakers_updatespawnmenu" )
    net.Broadcast()
end

UpdateData()
concommand.Add( "sv_npcvoicechat_updatedata", UpdateData, nil, "Updates and refreshes the nicknames, voicelines and other data required for NPC's proper voice chatting" )

local vcEnabled                 = CreateConVar( "sv_npcvoicechat_enabled", "1", cvarFlag, "Allows to NPCs and nextbots to able to speak voicechat-like using Lambda Players' voicelines", 0, 1 )
local vcAllowNPCs               = CreateConVar( "sv_npcvoicechat_allownpc", "1", cvarFlag, "If standart NPCs or the ones that are based on them like ANP are allowed to use voicechat", 0, 1 )
local vcAllowVJBase             = CreateConVar( "sv_npcvoicechat_allowvjbase", "1", cvarFlag, "If VJ Base SNPCs are allowed to use voicechat", 0, 1 )
local vcAllowDrGBase            = CreateConVar( "sv_npcvoicechat_allowdrgbase", "1", cvarFlag, "If DrGBase nextbots are allowed to use voicechat", 0, 1 )
local vcAllowSanics             = CreateConVar( "sv_npcvoicechat_allowsanic", "1", cvarFlag, "If 2D nextbots like Sanic or Obunga are allowed to use voicechat", 0, 1 )
local vcUseCustomPfps           = CreateConVar( "sv_npcvoicechat_usecustompfps", "1", cvarFlag, "If NPCs are allowed to use custom profile pictures instead of their model's spawnmenu icon", 0, 1 )
local vcIgnoreGagged            = CreateConVar( "sv_npcvoicechat_ignoregagged", "1", cvarFlag, "If NPCs that are gagged aren't allowed to play voicelines until ungagged", 0, 1 )
local vcSlightDelay             = CreateConVar( "sv_npcvoicechat_slightdelay", "1", cvarFlag, "If there should be a slight delay before NPC plays its voiceline to simulate its reaction time", 0, 1 )
local vcPitchMin                = CreateConVar( "sv_npcvoicechat_voicepitch_min", "100", cvarFlag, "The highest pitch a NPC's voice can get upon spawning", 10, 100 )
local vcPitchMax                = CreateConVar( "sv_npcvoicechat_voicepitch_max", "100", cvarFlag, "The lowest pitch a NPC's voice can get upon spawning", 100, 255 )

local vcUseLambdaVoicelines     = CreateConVar( "sv_npcvoicechat_uselambdavoicelines", "0", cvarFlag, "If NPCs should use voicelines from Lambda Players and its addons + modules instead" )
local vcUseLambdaPfpPics        = CreateConVar( "sv_npcvoicechat_uselambdapfppics", "0", cvarFlag, "If NPCs should use profile pictures from Lambda Players and its addons + modules instead" )
local vcUseLambdaNicknames      = CreateConVar( "sv_npcvoicechat_uselambdanames", "0", cvarFlag, "If NPCs should use nicknames from Lambda Players and its addons + modules instead" )
local vcLambdaVoicePfp          = CreateConVar( "sv_npcvoicechat_lambdavoicepfp", "", cvarFlag, "Lambda Voice Profile the newly created NPC should be spawned with. Note: This will override every player's client option with this one" )
local vcLambdaVoicePfpChance    = CreateConVar( "sv_npcvoicechat_lambdavoicepfp_spawnchance", "0", cvarFlag, "The chance the a NPC will use a random available Lambda Voice Profile as their voice profile after they spawn" )

local vcAllowLines_Idle         = CreateConVar( "sv_npcvoicechat_allowlines_idle", "1", cvarFlag, "If NPCs are allowed to play voicelines  while they are not in-combat", 0, 1 )
local vcAllowLines_CombatIdle   = CreateConVar( "sv_npcvoicechat_allowlines_combatidle", "1", cvarFlag, "If NPCs are allowed to play voicelines while they are in-combat", 0, 1 )
local vcAllowLines_Death        = CreateConVar( "sv_npcvoicechat_allowlines_death", "1", cvarFlag, "If NPCs are allowed to play voicelines when they get killed", 0, 1 )
local vcAllowLines_SpotEnemy    = CreateConVar( "sv_npcvoicechat_allowlines_spotenemy", "1", cvarFlag, "If NPCs are allowed to play voicelines when they first spot their enemy", 0, 1 )
local vcAllowLines_KillEnemy    = CreateConVar( "sv_npcvoicechat_allowlines_killenemy", "1", cvarFlag, "If NPCs are allowed to play voicelines when kill their enemy", 0, 1 )
local vcAllowLines_AllyDeath    = CreateConVar( "sv_npcvoicechat_allowlines_allydeath", "1", cvarFlag, "If NPCs are allowed to play voicelines when one of their allies gets killed", 0, 1 )
local vcAllowLines_Assist       = CreateConVar( "sv_npcvoicechat_allowlines_assist", "1", cvarFlag, "If NPCs are allowed to play voicelines when they get assisted by someone in some way, like one of their allies kills their enemy", 0, 1 )
local vcAllowLines_SpotDanger   = CreateConVar( "sv_npcvoicechat_allowlines_spotdanger", "1", cvarFlag, "If NPCs are allowed to play voicelines when they spot a danger like grenade and etc.", 0, 1 )
local vcAllowLines_CatchOnFire  = CreateConVar( "sv_npcvoicechat_allowlines_catchonfire", "1", cvarFlag, "If NPCs are allowed to play voicelines when they catch on fire.", 0, 1 )
local vcAllowLines_LowHealth    = CreateConVar( "sv_npcvoicechat_allowlines_lowhealth", "1", cvarFlag, "If NPCs are allowed to play voicelines when they are low on health.", 0, 1 )

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

local function GetVoiceLine( ent, voiceType )
    local voicePfp = ( LambdaVoiceProfiles and LambdaVoiceProfiles[ ent.NPCVC_VoiceProfile ] )
    if voicePfp then
        local voiceTbl = voicePfp[ voiceType ]
        if voiceTbl and #voiceTbl != 0 then
            return voiceTbl[ random( #voiceTbl ) ]
        end
    end

    local voicelineTbl = ( ( LambdaVoiceProfiles and vcUseLambdaVoicelines:GetBool() ) and LambdaVoiceProfiles or NPCVC_VoiceLines ) 
    local voiceTbl = voicelineTbl[ voiceType ]
    return voiceTbl[ random( #voiceTbl ) ]
end

local function PlaySoundFile( npc, voiceType, dontDeleteOnRemove )
    if !npc.NPCVC_Initialized then return end
    if npc.LastPathingInfraction and !vcAllowSanics:GetBool() then return end
    if npc.IsDrGNextbot and ( npc:IsPossessed() or !vcAllowDrGBase:GetBool() ) then return end
    if npc.IsVJBaseSNPC then
        if npc.VJ_IsBeingControlled or npc:GetState() != 0 or !vcAllowVJBase:GetBool() then return end
    elseif npc:IsNPC() and !vcAllowNPCs:GetBool() then 
        return 
    end
    if vcIgnoreGagged:GetBool() and npc:HasSpawnFlags( SF_NPC_GAG ) then return end

    local sndEmitter = ents_Create( "npc_vc_sndemitter" )
    sndEmitter:SetPos( npc:GetPos() )
    sndEmitter:SetOwner( npc )
    sndEmitter.DontRemoveEntity = dontDeleteOnRemove
    sndEmitter:Spawn()

    local sndName = GetVoiceLine( npc, voiceType )
    local vcData = {
        Emitter = sndEmitter,
        EntIndex = npc:GetCreationID(),
        Pitch = npc.NPCVC_VoicePitch,
        IconHeight = npc.NPCVC_VoiceIconHeight,
        VolumeMult = npc.NPCVC_VoiceVolumeScale,
        Nickname = npc.NPCVC_Nickname,
        ProfilePicture = npc.NPCVC_ProfilePicture
    }
    local pfpBgClr = npc.NPCVC_PfpBackgroundColor
    if pfpBgClr then vcData.PfpBackgroundColor = pfpBgClr end

    local playDelay = ( IsSinglePlayer() and 0 or 0.1 )
    if vcSlightDelay:GetBool() then playDelay = ( random( ( playDelay * 10 ), 5 ) / 10 ) end
    SimpleTimer( playDelay, function()
        net.Start( "npcsqueakers_playsound" )
            net.WriteString( sndName )
            net.WriteTable( vcData )
        net.Broadcast()
    end )

    local oldEmitter = npc:GetNW2Entity( "npcsqueakers_sndemitter" )
    if IsValid( oldEmitter ) then oldEmitter:Remove() end

    npc.NPCVC_LastVoiceLine = voiceType
    npc:SetNW2Entity( "npcsqueakers_sndemitter", sndEmitter )
end

local function IsSpeaking( npc, voiceType )
    if voiceType and npc.NPCVC_LastVoiceLine != voiceType then return false end
    local sndEmitter = npc:GetNW2Entity( "npcsqueakers_sndemitter" )
    return ( IsValid( sndEmitter ) and RealTime() <= sndEmitter.SpeechPlayTime )
end

local function GetAvailableNickname()
    local nameListTbl = ( ( LambdaPlayerNames and vcUseLambdaNicknames:GetBool() ) and LambdaPlayerNames or NPCVC_NickNames )

    local nameListCopy = table_Copy( nameListTbl )
    for _, v in ipairs( ents_GetAll() ) do
        if !IsValid( v ) or !v.NPCVC_Initialized and !v.IsLambdaPlayer then continue end
        table_RemoveByValue( nameListCopy, ( v.IsLambdaPlayer and v:GetLambdaName() or v.NPCVC_Nickname ) )
    end

    local rndName = nameListCopy[ random( #nameListCopy ) ]
    return ( rndName and rndName or nameListTbl[ random( #nameListTbl ) ] )
end

local function CheckNearbyNPCOnDeath( ent, attacker )
    local entPos = ent:GetPos()

    local attackPos
    if IsValid( attacker ) and ( attacker:IsPlayer() or attacker:IsNPC() or attacker:IsNextBot() ) then
        attackPos = attacker:GetPos()
    end

    for _, npc in ipairs( FindInSphere( entPos, 1500 ) ) do
        if npc == ent or !IsValid( npc ) or !npc.NPCVC_Initialized or npc.LastPathingInfraction or random( 1, 100 ) > npc.NPCVC_SpeechChance or IsSpeaking( npc ) then continue end

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

        npc.NPCVC_Initialized = true
        npc.NPCVC_LastEnemy = NULL
        npc.NPCVC_IsLowHealth = false
        npc.NPCVC_WasOnFire = false
        npc.NPCVC_IsSelfDestructing = false
        npc.NPCVC_LastState = -1
        npc.NPCVC_LastTakeDamageTime = 0
        npc.NPCVC_LastSeenEnemyTime = 0
        npc.NPCVC_NextIdleSpeak = ( CurTime() + Rand( 3, 8 ) )
        npc.NPCVC_NextDangerSoundTime = 0
        npc.NPCVC_LastVoiceLine = ""

        if !npc.LastPathingInfraction then
            local height = npc:OBBMaxs().z
            npc.NPCVC_VoiceIconHeight = ( height + 10 )
            npc.NPCVC_VoiceVolumeScale = Clamp( ( height / 72 ), 0.5, 2.5 )
        else
            npc.NPCVC_VoiceIconHeight = 138
            npc.NPCVC_VoiceVolumeScale = 2
        end

        if !npc.NPCVC_IsDuplicated then
            local speechChance = random( 0, 100 )
            npc.NPCVC_SpeechChance = speechChance
            
            local voicePitch = random( vcPitchMin:GetInt(), vcPitchMax:GetInt() )
            npc.NPCVC_VoicePitch = voicePitch
            
            local openName = GetAvailableNickname()
            npc.NPCVC_Nickname = openName

            local profilePic, pfpBgClr
            if vcUseCustomPfps:GetBool() then
                if vcUseLambdaPfpPics:GetBool() and #Lambdaprofilepictures != 0 then
                    profilePic = Lambdaprofilepictures[ random( #Lambdaprofilepictures ) ]
                elseif #NPCVC_ProfilePictures != 0 then
                    profilePic = NPCVC_ProfilePictures[ random( #NPCVC_ProfilePictures ) ]
                end
            end
            if !profilePic then
                pfpBgClr = Color( random( 0, 255 ), random( 0, 255 ), random( 0, 255 ) )

                local mdlDir = npc:GetModel()
                mdlDir = ( mdlDir and "spawnicons/".. string_sub( mdlDir, 1, #mdlDir - 4 ).. ".png"  )
                if mdlDir and file_Exists( "materials/" .. mdlDir, "GAME" ) then profilePic = mdlDir end
            end
            npc.NPCVC_ProfilePicture = profilePic
            npc.NPCVC_PfpBackgroundColor = pfpBgClr

            local voicePfp
            if LambdaVoiceProfiles then
                voicePfp = vcLambdaVoicePfp:GetString()
                if #voicePfp == 0 then 
                    if random( 1, 100 ) <= vcLambdaVoicePfpChance:GetInt() then
                        local voicePfps = table_GetKeys( LambdaVoiceProfiles ) 
                        voicePfp = voicePfps[ random( #voicePfps ) ]
                    else
                        voicePfp = nil
                    end
                else
                    npc.NPCVC_IsVoiceProfileServerside = true
                end
            end
            npc.NPCVC_VoiceProfile = voicePfp

            StoreEntityModifier( npc, "NPC VoiceChat - NPC's Voice Data", {
                SpeechChance = speechChance,
                VoicePitch = voicePitch,
                NickName = openName,
                ProfilePicture = profilePic,
                VoiceProfile = voicePfp,
                PfpBackgroundColor = pfpBgClr
            } )
        end

        if npc.IsVJBaseSNPC then
            local old_PlaySoundSystem = npc.PlaySoundSystem

            function npc:PlaySoundSystem( sdSet, customSd, sdType )
                if sdSet == "OnDangerSight" or sdSet == "OnGrenadeSight" and vcAllowLines_SpotDanger:GetBool() then
                    PlaySoundFile( npc, "panic" )
                elseif random( 1, 100 ) <= npc.NPCVC_SpeechChance and !IsSpeaking( npc ) then
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
        if !IsValid( npc ) or !npc.NPCVC_Initialized or npc.NPCVC_IsDuplicated or npc.NPCVC_IsVoiceProfileServerside then return end

        local voicePfp = ply:GetInfo( "cl_npcvoicechat_lambdavoicepfp" )
        if !voicePfp or #voicePfp == 0 then return end
        
        npc.NPCVC_VoiceProfile = voicePfp

        StoreEntityModifier( npc, "NPC VoiceChat - NPC's Voice Data", {
            SpeechChance = npc.NPCVC_SpeechChance,
            VoicePitch = npc.NPCVC_VoicePitch,
            NickName = npc.NPCVC_Nickname,
            ProfilePicture = npc.NPCVC_ProfilePicture,
            VoiceProfile = voicePfp,
            PfpBackgroundColor = npc.NPCVC_PfpBackgroundColor
        } )
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
        if !IsValid( npc ) or !npc.NPCVC_Initialized then continue end

        if npc:GetClass() == "npc_turret_floor" then 
            local selfDestructing = npc:GetInternalVariable( "m_bSelfDestructing" )
            if !selfDestructing then 
                local curState = npc:GetNPCState()
                local lastState = npc.NPCVC_LastState
                if curState != lastState then
                    if lastState == NPC_STATE_DEAD then
                        PlaySoundFile( npc, "assist" )
                    elseif curState == NPC_STATE_DEAD then
                        PlaySoundFile( npc, "panic" )
                    elseif curState == NPC_STATE_COMBAT then
                        PlaySoundFile( npc, "taunt" )
                    end
                end
                npc.NPCVC_LastState = curState

                local curEnemy = npc:GetEnemy()
                local lastEnemy = npc.NPCVC_LastEnemy
                if curEnemy != lastEnemy and IsValid( curEnemy ) then
                    PlaySoundFile( npc, "taunt" )
                end
                npc.NPCVC_LastEnemy = curEnemy
            elseif !npc.NPCVC_IsSelfDestructing then
                npc.NPCVC_IsSelfDestructing = true

                SimpleTimer( Rand( 0.8, 1.25 ), function()
                    if !IsValid( npc ) then return end
                    PlaySoundFile( npc, "panic" )
                end )

                SimpleTimer( Rand( 2, 3.5 ), function()
                    if !IsValid( npc ) then return end
                    PlaySoundFile( npc, "death" )
                end )
            end
        else
            local curEnemy
            local rolledSpeech = ( random( 1, 100 ) <= npc.NPCVC_SpeechChance )

            if npc.LastPathingInfraction then
                curEnemy = npc.CurrentTarget

                local isVisible = false
                local lastSeenTime = npc.NPCVC_LastSeenEnemyTime
                if !IsValid( curEnemy ) then
                    npc.NPCVC_LastSeenEnemyTime = 0
                elseif npc:GetRangeSquaredTo( curEnemy ) <= 1000000 and npc:Visible( curEnemy ) then
                    isVisible = true
                    npc.NPCVC_LastSeenEnemyTime = curTime
                end

                if rolledSpeech then
                    if lastSeenTime == 0 and isVisible and vcAllowLines_SpotEnemy:GetBool() then
                        PlaySoundFile( npc, "taunt" )
                    elseif curTime >= npc.NPCVC_NextIdleSpeak and !IsSpeaking( npc ) then
                        if ( curTime - npc.NPCVC_LastSeenEnemyTime ) <= 5 and IsValid( curEnemy ) then
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
                if onFire and !npc.NPCVC_WasOnFire and vcAllowLines_CatchOnFire:GetBool() then
                    PlaySoundFile( npc, "panic" )
                end
                npc.NPCVC_WasOnFire = onFire

                local lowHP = npc.NPCVC_IsLowHealth
                if !lowHP then
                    local hpThreshold = Rand( 0.2, 0.5 )
                    if npc:Health() <= ( npc:GetMaxHealth() * hpThreshold ) then
                        npc.NPCVC_IsLowHealth = hpThreshold

                        if rolledSpeech and ( curTime - npc.NPCVC_LastTakeDamageTime ) <= 5 and vcAllowLines_LowHealth:GetBool() then
                            PlaySoundFile( npc, "panic" )
                        end
                    end
                elseif npc:Health() > ( npc:GetMaxHealth() * lowHP ) then
                    npc.NPCVC_IsLowHealth = false
                end

                curEnemy = npc:GetEnemy()
                local lastEnemy = npc.NPCVC_LastEnemy
                local isPanicking = ( npc.NPCVC_WasOnFire or !npc.IsDrGNextbot and IsValid( curEnemy ) and curEnemy.LastPathingInfraction )
                if npc.IsVJBaseSNPC or npc.IsDrGNextbot then
                    if rolledSpeech then
                        if !isPanicking then
                            isPanicking = ( isPanicking or ( npc.NoWeapon_UseScaredBehavior and !IsValid( npc:GetActiveWeapon() ) ) )
                        end

                        local spotLine = ( ( !isPanicking and ( !lowHP or random( 1, 4 ) != 1 ) ) and "taunt" or "panic" )                            
                        if curEnemy != lastEnemy then
                            if IsValid( curEnemy ) and !IsValid( lastEnemy ) and vcAllowLines_SpotEnemy:GetBool() then
                                PlaySoundFile( npc, spotLine )
                            end
                        elseif curTime >= npc.NPCVC_NextIdleSpeak and !IsSpeaking( npc ) then
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
                    if curTime >= npc.NPCVC_NextDangerSoundTime and ( npc:HasCondition( 50 ) or npc:HasCondition( 57 ) or npc:HasCondition( 58 ) ) and vcAllowLines_SpotDanger:GetBool() then
                        PlaySoundFile( npc, "panic" )
                        npc.NPCVC_NextDangerSoundTime = ( curTime + 5 )
                    end

                    local curState = npc:GetNPCState()
                    if rolledSpeech then
                        if !isPanicking then
                            isPanicking = ( IsValid( curEnemy ) and ( noWepFearNPCs[ npc:GetClass() ] and !IsValid( npc:GetActiveWeapon() ) or npc:Disposition( curEnemy ) == D_FR ) )
                        end

                        local spotLine = ( ( !isPanicking and ( !lowHP or random( 1, 3 ) != 1 ) ) and "taunt" or "panic" )                            
                        if curState != npc.NPCVC_LastState then
                            if curState == NPC_STATE_COMBAT and !IsValid( lastEnemy ) and vcAllowLines_SpotEnemy:GetBool() then
                                PlaySoundFile( npc, spotLine )
                            end
                        elseif curTime >= npc.NPCVC_NextIdleSpeak and !IsSpeaking( npc ) then
                            if curState == NPC_STATE_COMBAT then
                                if vcAllowLines_CombatIdle:GetBool() then
                                    PlaySoundFile( npc, spotLine )
                                end
                            elseif ( curState == NPC_STATE_IDLE or curState == NPC_STATE_ALERT ) and vcAllowLines_Idle:GetBool() then
                                PlaySoundFile( npc, "idle" )
                            end
                        end
                    end
                    npc.NPCVC_LastState = curState
                end
            end

            npc.NPCVC_LastEnemy = curEnemy
            if curTime >= npc.NPCVC_NextIdleSpeak then
                npc.NPCVC_NextIdleSpeak = ( curTime + Rand( 3, 8 ) )
            end
        end
    end
end

local function OnPostEntityTakeDamage( ent, dmginfo, tookDamage )
    if !tookDamage or !ent.NPCVC_Initialized then return end
    ent.NPCVC_LastTakeDamageTime = CurTime()
end

hook.Add( "OnEntityCreated", "NPCSqueakers_OnEntityCreated", OnEntityCreated )
hook.Add( "PlayerSpawnedNPC", "NPCSqueakers_OnPlayerSpawnedNPC", OnPlayerSpawnedNPC )
hook.Add( "OnNPCKilled", "NPCSqueakers_OnNPCKilled", OnNPCKilled )
hook.Add( "PlayerDeath", "NPCSqueakers_OnPlayerDeath", OnPlayerDeath )
hook.Add( "CreateEntityRagdoll", "NPCSqueakers_OnCreateEntityRagdoll", OnCreateEntityRagdoll )
hook.Add( "Think", "NPCSqueakers_OnServerThink", OnServerThink )
hook.Add( "PostEntityTakeDamage", "NPCSqueakers_OnPostEntityTakeDamage", OnPostEntityTakeDamage )