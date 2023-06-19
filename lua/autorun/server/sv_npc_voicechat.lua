local net = net
local ipairs = ipairs
local pairs = pairs
local RandomPairs = RandomPairs
local IsValid = IsValid
local SimpleTimer = timer.Simple
local random = math.random
local randomseed = math.randomseed
local string_sub = string.sub
local string_find = string.find
local Clamp = math.Clamp
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

local waterCheckTr = {}
local nextNPCSoundThink = 0
local transitionSaveNPCs = {
    [ "npc_dog" ] = true,
    [ "npc_alyx" ] = true,
    [ "npc_barney" ] = true,
    [ "npc_kleiner" ] = true,
    [ "npc_breen" ] = true,
    [ "npc_eli" ] = true,
    [ "npc_monk" ] = true,
    [ "npc_gman" ] = true,
    [ "npc_magnusson" ] = true,
    [ "npc_mossman" ] = true,
    [ "npc_odessa" ] = true,
    [ "npc_helicopter" ] = true,
    [ "monster_gman" ] = true
}
local noWepFearNPCs = {
    [ "npc_alyx" ] = true,
    [ "npc_barney" ] = true,
    [ "npc_citizen" ] = true,
    [ "npc_kleiner" ] = true,
    [ "npc_mossman" ] = true,
    [ "npc_eli" ] = true,
    [ "npc_eli" ] = true,
    [ "monster_scientist" ] = true
}
local dontFearNPCs = {
    [ "npc_zombie" ] = true,
    [ "npc_headcrab" ] = true,
    [ "npc_headcrab_fast" ] = true,
    [ "npc_headcrab_black" ] = true,
    [ "npc_fastzombie" ] = true,
    [ "npc_poisonzombie" ] = true,
    [ "npc_zombine" ] = true,
    [ "npc_zombie_torso" ] = true,
    [ "npc_fastzombie_torso" ] = true
}
local nonNPCNPCs = {
    [ "npc_bullseye" ] = true,
    [ "npc_enemyfinder" ] = true,
    [ "npc_furniture" ] = true,
    [ "controller_energy_ball" ] = true,
    [ "nihilanth_energy_ball" ] = true,
    [ "hornet" ] = true,
    [ "npc_cranedriver" ] = true,
    [ "cycler_actor" ] = true,
    [ "npc_launcher" ] = true,
    [ "obj_vj_bullseye" ] = true,
    [ "cycler" ] = true,
    [ "generic_actor" ] = true,
    [ "npc_vehicledriver" ] = true,
    [ "monster_furniture" ] = true,
    [ "animprop_generic" ] = true,
    [ "animprop_generic_physmodel" ] = true,
    [ "monster_generic" ] = true
}
local drownNPCs = {
    [ "npc_headcrab" ] = true,
    [ "npc_headcrab_black" ] = true,
    [ "npc_headcrab_fast" ] = true,
    [ "npc_rollermine" ] = true,
    [ "npc_antlion" ] = true
}
local noStateUseNPCs = {
    [ "npc_barnacle" ] = true,
    [ "npc_combinedropship" ] = true,
    [ "npc_helicopter" ] = true,
    [ "npc_combinegunship" ] = true,
    [ "npc_turret_ceiling" ] = true
}
local npcIconHeights = {
    [ "monster_turret" ] = -60,
    [ "monster_miniturret" ] = -60,
    [ "npc_barnacle" ] = -64,
    [ "monster_barnacle" ] = -64,
    [ "npc_combine_camera" ] = -70,
    [ "npc_turret_ceiling" ] = -70,
    [ "npc_manhack" ] = 24,
    [ "npc_cscanner" ] = 24,
    [ "npc_clawscanner" ] = 24,
    [ "monster_houndeye" ] = 58,
    [ "monster_bullchicken" ] = 58,
    [ "npc_helicopter" ] = 100,
    [ "npc_antlionguard" ] = 150,
    [ "npc_dog" ] = 128,
    [ "npc_combinegunship" ] = 128,
    [ "npc_combinedropship" ] = 240,
    [ "monster_bigmomma" ] = 240,
    [ "monster_gargantua" ] = 250
}
local hlsNPCs = {
    [ "monster_alien_grunt" ] = true,
    [ "monster_barnacle" ] = true,
    [ "monster_nihilanth" ] = true,
    [ "monster_tentacle" ] = true,
    [ "monster_alien_slave" ] = true,
    [ "monster_bigmomma" ] = true,
    [ "monster_bullchicken" ] = true,
    [ "monster_gargantua" ] = true,
    [ "monster_human_assassin" ] = true,
    [ "monster_babycrab" ] = true,
    [ "monster_human_grunt" ] = true,
    [ "monster_leech" ] = true,
    [ "monster_cockroach" ] = true,
    [ "monster_houndeye" ] = true,
    [ "monster_scientist" ] = true,
    [ "monster_snark" ] = true,
    [ "monster_zombie" ] = true,
    [ "monster_headcrab" ] = true,
    [ "monster_alien_controller" ] = true,
    [ "monster_barney" ] = true,
    [ "monster_turret" ] = true,
    [ "monster_miniturret" ] = true,
    [ "monster_sentry" ] = true
}
local defVoiceTypeDirs = { [ "idle" ] = "npcvoicechat/vo/idle", [ "witness" ] = "npcvoicechat/vo/witness", [ "death" ] = "npcvoicechat/vo/death", [ "panic" ] = "npcvoicechat/vo/panic", [ "taunt" ] = "npcvoicechat/vo/taunt", [ "kill" ] = "npcvoicechat/vo/kill", [ "laugh" ] = "npcvoicechat/vo/laugh", [ "assist" ] = "npcvoicechat/vo/assist" }
local ignoreGagTypes = {
    [ "death" ] = true,
    [ "panic" ] = true,
    [ "witness" ] = true
}

local aiDisabled = GetConVar( "ai_disabled" )
local ignorePlys = GetConVar( "ai_ignoreplayers" )

-- Dear god...
local defaultNames = { "Based Kleiner", "The Real Zeta Player", "Beta", "Generic Name 1", "Ze Uberman", "Q U A N T U M P H Y S I C S", "portable fridge", "Methman456", "i rdm kids for breakfast", "Cheese Adiction Therapist", "private hoovy", "Socks with Sandals", "Solar", "AdamYeBoi", "troll", "de_struction and de_fuse", "de_rumble", "decoymail", "Damian", "BrandontheREDSpy", "Braun", "brent13", "BrokentoothMarch", "BruH", "BudLightVirus", "Call of Putis", "CanadianBeaver", "Cake brainer", "cant scream in space", "CaptGravyBoness", "CaraKing09", "CarbonTugboat", "CastHalo", "cate", "ccdrago56", "cduncan05", "Chancellor_Ant", "Changthunderwang", "Charstorms", "Ch33kCLaper69", "Get Good Get Lmao Box", "Atomic", "Audrey", "Auxometer", "A Wise Author", "Awtrey516", "Aytx", "BabaBooey", "BackAlleyDealerMan", "BalieyeatsPizza", "ballzackmonster", "Banovinski", "bardochib", "BBaluka", "Bean man", "Bear", "Bearman_18", "beeflover100", "Albeon Stormhammer", "Andromedus", "Anilog", "Animus", "Sorry_an_Error_has_Occurred", "I am the Spy", "engineer gaming", "Ze Uberman", "Regret", "Sora", "Sky", "Scarf", "Graves", "bruh moment", "Garrys Mod employee", "i havent eaten in 69 days", "DOORSTUCK89", "PickUp That Can Cop", "Never gonna give you up", "if you are reading this, ur mom gay ", "The Lemon Arsonist", "Cave Johnson", "Chad", "Speedy", "Alan", "Alpha", "Bravo", "Delta", "Charlie", "Echo", "Foxtrot", "Golf", "Hotel", "India", "Juliet", "Kilo", "Lima", "Lina", "Mike", "November", "Oscar", "Papa", "Quebec", "Romeo", "Sierra", "Tango", "Uniform", "Victor", "Whiskey", "X-Ray", "Yankee", "Zulu", "Flare", "Brian", "Frank", "Blaze", "Rin", "Bolt", "runthemingesarecoming", "Brute", "Snare", "Matt", "Arc", "VeeVee", "Serv", "Manjaro", "Sentinal", "Night", "Cayde", "Ranger", "Coach", "Bob Ross", "Mossman", "Nova", "drop10kthisisamug2874", "NUCCCLLEEEEEOOOOOOON", "u mad", "TheAdminge", "Trace", "Kelly", "Marauder", "AVATAR", "Scout", "Mirage", "Spark", "Jolt", "Ghost", "Summer", "Breenisgay69", "Dr Breen", "Combino", "Beowulf", "Heavy Weapons Guy", "GodFather", "Cheaple", "Desmond the epic", "Despairaity", "Destroyer_V0", "Devout Buddhist", "DingoGorditas", "DiscoDodgeBall", "Doc Johnson", "Dogmeat Tactical Vest", "Dogboy", "D O I N K", "ThatMW2Squeaker", "EBOI BOI BOI BOI BOI BOI BOI", "Condescending Idiot", "CoolColton947", "CordingWater6", "Cpt_Core", "Crofty", "Crusader", "Ctoycat", "Cyclops", "Daddy_Debuff", "dallas", "DaLocust56", "Danny DeVito", "DaNub2038", "DarkNinjaD", "DarthHighGround", "DarthOobleck", "Dassault Mirage 2000C", "Davidb16", "D4rp_b0y", "Ruzzk1y", "SanicYT948", "sanitter", "Sanity", "Schutzhund", "scipion34", "Scotty2Hotty", "Seltzer", "Senior Cangrejo", "sfingers02", "Sharkgoat", "SharkyShark", "Shawty Like A Melody", "sh00shyb0i", "ShrekYeeter69", "Shrubster", "SirSamTheMan", "skinny peen", "Skulleewag395", "SleepingWarkat", "Sleipnlr", "Small PP Man", "SmortSocks", "Snapsro94", "Snipeshot556", "Snoot", "remember_no_russian", "Res", "ricefouboi", "rickymicdoo", "Rigatoni", "Robo7988143", "Rocketeer097", "Rollinwind", "rolltide10032", "Rome12310", "rushbuild", "mason the numbers what do they mean", "onin ring", "0nyx", "oofiet", "Orlorin_Foolofatook26", "pablo", "Paft_Dunk", "Panther0706", "Patrick", "PD53", "Pedro", "Peel1", "PenaPVP", "Penguan", "pepegonzalez2006", "Pescaxo", "phatty", "Piard", "Pickles", "Pigeon", "PilotJames007", "Pilotlily", "Piratenkapitan", "PixelG", "planewithnocanards", "platypus429", "Plumpotato47", "PM Prayuth", "poop_sock6969", "PollutionDieingPlanet", "Popsicle-Biscuit", "portable fridge", "Potatogamer555", "Prinz Eugen007", "PrivateWings", "PuercoVolador", "Purple Toyota AE87", "Pyromaniac", "B", "Quacker The Ducker", "Quadrapuds", "Obama", "obamas-last-name", "Aria", "0nE", "FluffySkunkBoy", "John117", "Kanye Bear", "NASCAR FAN 48", "Nightengale537", "Painini", "picklface", "Slavic_Chicken", "Snoucher", "Special", "wheatly_crab", "Yuri Kuroyanagi", "Doof", "Doritos Toasted Corn Tortilla Chips", "Doubletimes", "Dragon", "Adrian", "Umbreon-Kun", "Im happy :D", "Im Sad D:", "Dead Meme", "Kohan-Kun", "Juan", "Chunky Joe", "Slyblindfox", "Trump", "Ronald", "Kortex", "Kim Jack Off", "Aimlocked", "KloGuy", "Chucky", "Volcano", "Doge Mint", "JackTheRipper", "Just a Cardboard Box", "~Erim~", "muesli", "Saiko", "aoihitsuji", "Reayr1", "Mekako", "ddaydeath", "Str00kerX", "Yuki", "Rena.", "cOnFuSeD", "terminator YD", "Kylin", "Seki", "Osmund", "Botulism Betty", "miyuki", "Pway pway", "TKO | gag0!", "Styx", "/sng/", "OWO", "Kr@zZy", "c0rsair", "nexcor", "pr3st0", "663", "V0id", "Killing Frenzy", "Campers Death", "You make me Laugh", "killaura", "Violently Happy", "Make my Day", "Pissed Off", "Bloodlust", "b02fof", "Zap!", "Dredd", "Fuzzey", "Bucus", "mokku", "A Professional With Standards", "Archimedes!", "Glorified Toaster with Legs", "Yana", "Your pet turtle", "You smell bad", "You smell nice", "I'm real", "Let's make children", "chen y", "NotDuckie", "De_stroyed", "nabongS", "h8 exam", "Crazii", "i h8 myself", "jowak1n", "beyluta", "natty_the_great", "ernest_aj", "bored", "hambug | buying skins", "Kiwino", "farn", "hezzy", "misty :3", "taFFy", "Kei", "I love you", "Sasucky", "eisoptrophobia.", "Yzui", "VKDrummer", "GDliZy", "Schizo x.O", "Yowza", "Hikari", "Niltf", "Kiruh", "caKuma", "Inkou PM", "I wish i was dead", "iamsleepless", "Hackyou", "Sokiy", "Kairu", "hatihati", "tarumaru", "berthe", "MB295", "Jumo", "kirkimedes", "Souless", "LamZee", "Aya-Chan", "gvek", "El Jägermeister", "ikitakunai", "Meti ", "VyLenT", "AlesTA", "Remi", "FTruby", "Touka_", "henkyyi", "Nitrogen09", "moyazou", "chamaji", "ramjam18", "VyYui", "tsumiki", "__dd", "Jushy", "TANUKANA", "Aeyonna | loving you hurts", "Alux.", "Young Jager", "Exhausted Life", "A E S T H E T I C", "Thomas_", "Ross Scarlet", "sonamed", "kuben", "Loord", "pasha", "Neo", "GoodRifle", "alex", "xF", "tb", "karl", "Virgo", "Savage", "rita", "prom1se", "xiaoe", "karrigan", "ArcadioN", "Friis", "wazorN", "suraNga", "minet", "j$", "zonic H$", "trace", "ave", "Sunde ACEEE", "Maximus", "Snappi", "xone", "luffeb", "katulen", "Strangelet", "AllThatGlitters21", "BreakingNYC", "DancingCrazy351", "fish be like i spendz da sack", "Darkrogue20", "davedays", "DieAussenseiter", "DragonCharlz", "eddysson86", "ef12striker", "EllesGlitterGossip", "esmeedenters", "HeadsUpLisa | Lwoosers", "hotforwords", "Düktor", "IntelExtremeMasters", "Monarch5150", "mouzmovie", "LUlyuo", "NCIXcom", "RayWilliamJohnson", "RubberRoss ", "seductioncoach", "septinho", "soundlyawake", "Blacklegion104 ", "ICANHAZHEADSHOT ", "so4p | Lwoosers", "gg_legol4s3rZ7", "Dert", "HDstarcraft ", "Husky", "h0N123", "Da-MiGhtY 4357", "NetManiac", "Kyu >3<", ">PartiZan<", "K!110grAmm", "SchtandartenFuhrer", "mu1ti-K!ll", "=ZL0Y=", "HeadKilla ==(oo)=>", "dub", "Kara", "Mechano!d", "3v!LKilla", "viz0r", "MiXa", "DiGGeR", "=GRoMoZeKA=", "ZveroBoy", "ahl.", "bds.", "brunk", "ElemenT", "fisker", "goseY", "Potti", "Morda", "n0name| S>Keys B>Knives", "NiTron", "Normal Human", "xXSniper_MainXx", "Left Foot In", "Right Foot Out", "Left Handed", "Calcium", "Dinnerbone", "Terrible Terror", "Shoot Me", "Aquatic Mammal", "Poopy Joe", "Free Stuff?", "Needs More Salt", "Duck Feet", "Impossibly Epic", "Joe Mamma", "Catapult of Pain", "Drunk and Scottish", "Half Life 3", "The Last Chip", "Pete", "Mercedes Benz", "Vergil", "FriskyRisky", "Bad Cop", "PersonCake", "SoundAngels", "StrongChase", "Sultryla", "Switzersu", "TagzRip", "TalentCover", "Telemil", "Warrameha", "MrMuskyHusky", "ImBoosted", "PanzerKommandant|8thPanzer", "johnzeus19", "Dunnionringz", "The Helper", "annajnavarro", "Lévi", "Fat Whale", "God HATES you!", "vintige kratskrag", "Who?", "Demoman Takes Skill!", "DohnJoe", "Santa Claus Schoolgirl", "Botulism Betty", "Straight from botnames.txt!", "Blessed To Moonwalk", "Chris P. Bacon", "Consume your Calcium", "rubbedsaltwound", "Content Quality Control", "SpamCracker", "Alcohol + Poor Life Decisions", "salad", "i dont sleep", "Kritty Kat", "Headshot!", "Mini-Biscuits Rights Activist.", "I'm not gay, but $20 is $20", "Dr. Mantis Toboggan", "The Buttstaber", "2 FAST 4 U", "The Living Lawn Mower ", "Don't Fuckle With Shuckle", "Yolo Swaggins", "Suppository Breadcrumbs", "The Inhuman Scorch", "Honey I healed the Heavy", "Drinking + Driving", "spicy comments", "The Terrible Spicy Tea", "Thomas the Wank Engine", "Special Needs Engineer", "A Strange Festive Newt Gingrich", "A Sexually Attractive Cactus", "Swaghetti Yolonaise", "butt soup ", "Alcoholic Fat Guy", "Afraid Egg", "It's Legal in Japan", "I'm So Meta Even This Acronym.", "Unusual Foppish Boner", "Awkward Cuddle Boner", "A Distinctive lack of YOU!", "The Spanish Inquisition", "A Duck On Quack", "obesity related illness.", "ASS PANCAKES!", "Bodyshots Johnson", "Nein Lives.", "Dispenser (Target Practice)", "Country-Steak:Sauce", "Sock Full of Shame", "An overdose of French Toast", "One Kawaii MotherFucker", "Smokey Joe", "The Spicy Meatball.", "I Eat Toddlers", "Cunning Linguist", "3DayOldTeleportedBread", "Replay", "The Intense Hoovy Main", "?", "About_30_ninjas", "Ithoughtshewaslvl18 ", "404 GF not found  ", "IfIDiedIWasAFK ", "Jimmies Rustler", "go go gadget aimbot ", "Neil, Intergalactic Grandpa", "General Steiner", "Crazy Dewfus", "Sympatriotic", "doge", "Warmachine", "Diarrhea On Wheels", "Roasty my Toasty", "Steve Handjobs", "the hottest cheeto ever, man", "Imagine actually dying to WM1", "Vince makes you say Shamwow", "PyrosAreAssholes", "Hilarious Bread", "poo c", "19 year old virgin", "Parasitic watermelon", "Welcome to Costco", "Sick Marmalade, Grandpa ", "buttsaggington", "Mother Fucking Oedipus", "I wonder what cum taste likes", "Money, Hoes and Spaghetti-O's", "Mister Lister the Sister Fister", "Jonk", "Diet Cocaine", "Suspiciously Slow Scout", "Space Gandhi", "urine for a treat", "Delusional Arsonist", "Yung Micheal", "Old Man of America", "Spam & Heals Inc.", "yes_u_suck", "I_YELL_ALOT", "DroolTool", "A very fat man named Minh", "heavy from team fortress 5", "Cheesus Evangelionist", "Just a noob", "WetHitter", "Unsubscribe", "WeThePizza", "LactoseTheIntolerant", "MagicLOL", "getVACburned", "BeatdownMachine", "Such_A_Noob", "Balloonicorn", "Phosuphi", "BeardNoMore", "CutthroatChicken", "YourNameOnMySword", "BarryMcKackiner", "MyAxeYourFace", "Bagelofdeath", "Window Maker", "Rock8Man", "UsedFood", "beepbeepimajeep", "bitpull ", "PatMaximum", "you snoze you loze", "I_fap_twohanded", "DixonCider", "NoChildSupport", "Don't Shoot I'm a virgin ", "Pvt. Parts ", "BigD_McGee ", "McD'sHashbrown ", "SnackBitesWillRule ", "Stalin's Organ.", "BadUsernameSince2015", "NoDadNotTheBelt", "BrokenBoneBroker", "DontTouchThat", "InfinityLag", "NullPointer ", "FrankTheCrank", "Mexican't ", "HouseOfChards", "Playing TF2 on A Toaster", "noob", "SpawnOfChaos", "I'm a Nokia ", "Solid Steak", "Killavanilla", "Tactical Toast", "OmgMyNameWontFi ", "Does you has? ", "niche one ", "he ded lol", "Testicular Thorsion ", "you_sun_of_a_beach ", "that's DOCTOR noob 4u ", "hoehoehoe", "PonySlaystation ", "suck my clock", "Muffled Fart ", "ClickSwitch", "GarbageRubberBand", "PennyUnwise", "Kacktus ", "Propanetankhank ", "HeyimGey. ", "Lol a shaved donkey", "De_stroyed", "i h8 myself", "eisoptrophobia.", "Respect your mom", "I wish i was dead", "CakeStealer", "KinosaurusRex", "Maximus", "SpyCrab", "MassTenderizer", "ParrotGal75", "Mentlegen Terrorist", "La Baguette Faguette", "Soup Can", "Lewdest Robot", "Hella Thicc", "Foot Lover Berry", "Hell is NOT okay", "unnamed", "Player", "HereComesThePainTrain", "lololol", "Nope.avi", "Snipping Tool", "Fax Machine", "m0tiVACation", "Just a Cardboard Box", "xXDark_LordXx", "expee", "????????", "nWord", "NotAnEngineer", "KidFromSchool", "Phone", "OmqItswOOdy", "canon father", "dart invader", "FreeeeeIpad", "nonuts", "E", "Carl Johnson", "Big Smoke", "CritsAreFair", "A Commie", "Prankster_Gangster", "Dad", "im going to area51", "AliveFace", "CornCakes", "Morgan", "goD", "Scunts_Sux", "Bruh231", "nikolai.thegamer 2019", "Pixels", "Mark", "Jon", "Garfield", "a pay 2 play", "a free 2 play", "yeet", "ESP", "a bunch of 0s and 1s", "Hitscan", "LmaoBox", "I DIE !", "Barny", "Gordon Freeman", "Drunken Wretch", "No", "IDontHaveAName", "PewDiePie", "Water Sheep", "Sandvich", "Mega dumboon", "MetalLegend", "A girl", "LessCrits", "Mario", "Loogi", "Sven", "Joergen", "'Merica fok ye", "Serbia", "Fonsi", "Despacito", "Pussy Memes", "Hail", "Bird", "SuperNatural", "SomeBruh", "This Guy", "Soulfull", "Undead", "Vehicle", "210Hill", "Bush-Dog", "The Wall", "The Bitch", "FishFace", "BFG 9000", "Bushman", "LucksMan", "Totally a human", "Shadows", "Nuclear Fruitcake", "Gold Steel", "scooteroni", "Mr.Poot", "liveMeat", "TalkyFan", "miss appauling", "Blue Man", "Red Man", "Gray Man", "Oblivious Man", "Rebel", "Havana OOONANA", "superguy", "Abraham da great", "George chopdowninnocenttree", "Franklin Deez nutz", "a wizard", "What", "thats nacho cheeze", "lesbian", "Gay", "papa Pete", "SpookyMint", "keegasp00ks", "Shock" }

util.AddNetworkString( "npcsqueakers_playsound" )
util.AddNetworkString( "npcsqueakers_sndduration" )
util.AddNetworkString( "npcsqueakers_updatespawnmenu" )
util.AddNetworkString( "npcsqueakers_resetsettings" )
util.AddNetworkString( "npcsqueakers_writedata" )
util.AddNetworkString( "npcsqueakers_requestdata" )
util.AddNetworkString( "npcsqueakers_returndata" )

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
local vcAllowVJBase             = CreateConVar( "sv_npcvoicechat_allowvjbase", "1", cvarFlag, "If VJ Base SNPCs are allowed to use voicechat", 0, 1 )
local vcAllowDrGBase            = CreateConVar( "sv_npcvoicechat_allowdrgbase", "1", cvarFlag, "If DrGBase nextbots are allowed to use voicechat", 0, 1 )
local vcAllowSanics             = CreateConVar( "sv_npcvoicechat_allowsanic", "1", cvarFlag, "If 2D nextbots like Sanic or Obunga are allowed to use voicechat", 0, 1 )
local vcAllowSBNextbots         = CreateConVar( "sv_npcvoicechat_allowsbnextbots", "1", cvarFlag, "If SB Advanced Nextbots like the Terminator are allowed to use voicechat", 0, 1 )
local vcAllowTF2Bots            = CreateConVar( "sv_npcvoicechat_allowtf2bots", "1", cvarFlag, "If bots from Team Fortress 2 are allowed to use voicechat", 0, 1 )
local vcUseModelIcon            = CreateConVar( "sv_npcvoicechat_usemodelicons", "0", cvarFlag, "If NPC's profile pictures should first check for their model's spawnmenu icon to use as a one instead of the entity icon", 0, 1 )
local vcUseCustomPfps           = CreateConVar( "sv_npcvoicechat_usecustompfps", "0", cvarFlag, "If NPCs are allowed to use custom profile pictures instead of their spawnmenu icons", 0, 1 )
local vcUserPfpsOnly            = CreateConVar( "sv_npcvoicechat_userpfpsonly", "0", cvarFlag, "If NPCs are only allowed to use profile pictures that are placed by players", 0, 1 )
local vcIgnoreGagged            = CreateConVar( "sv_npcvoicechat_ignoregaggednpcs", "0", cvarFlag, "If NPCs that are gagged by the map or other means aren't allowed to play voicelines until ungagged", 0, 1 )
local vcSlightDelay             = CreateConVar( "sv_npcvoicechat_slightdelay", "1", cvarFlag, "If there should be a slight delay before NPC plays its voiceline to simulate its reaction time", 0, 1 )
local vcUseRealNames            = CreateConVar( "sv_npcvoicechat_userealnames", "1", cvarFlag, "If NPCs should use their actual names instead of picking random nicknames", 0, 1 )
local vcPitchMin                = CreateConVar( "sv_npcvoicechat_voicepitch_min", "95", cvarFlag, "The highest pitch a NPC's voice can get upon spawning", 0, 255 )
local vcPitchMax                = CreateConVar( "sv_npcvoicechat_voicepitch_max", "105", cvarFlag, "The lowest pitch a NPC's voice can get upon spawning", 0, 255 )
local vcSpeakLimit              = CreateConVar( "sv_npcvoicechat_speaklimit", "0", cvarFlag, "Controls the amount of NPCs that can use voicechat at once. Set to zero to disable", 0 )
local vcLimitAffectsDeath       = CreateConVar( "sv_npcvoicechat_speaklimit_dontaffectdeath", "1", cvarFlag, "If the speak limit shouldn't affect NPCs that are playing their death voiceline", 0, 1 )
local vcForceSpeechChance       = CreateConVar( "sv_npcvoicechat_forcespeechchance", "0", cvarFlag, "If above zero, will set every newly spawned NPC's speech chance to this value. Set to zero to disable", 0, 100 )
local vcSpeakChanceAffectDeath  = CreateConVar( "sv_npcvoicechat_speakchanceaffectsdeath", "1", cvarFlag, "If NPC's speech chance should also affect its playing of death voicelines. Note that they will always play the voiceline if they were talking during their death", 0, 1 )
local vcSaveNPCDataOnMapChange  = CreateConVar( "sv_npcvoicechat_savenpcdataonmapchange", "0", cvarFlag, "If essential NPCs from Half-Life campaigns should save their voicechat data. This will for example prevent them from having a different name when appearing after map change and etc.", 0, 1 )

local vcUseLambdaVoicelines     = CreateConVar( "sv_npcvoicechat_uselambdavoicelines", "0", cvarFlag, "If NPCs should use voicelines from Lambda Players and its addons + modules instead" )
local vcUseLambdaPfpPics        = CreateConVar( "sv_npcvoicechat_uselambdapfppics", "0", cvarFlag, "If NPCs should use profile pictures from Lambda Players and its addons + modules instead" )
local vcUseLambdaNicknames      = CreateConVar( "sv_npcvoicechat_uselambdanames", "0", cvarFlag, "If NPCs should use nicknames from Lambda Players and its addons + modules instead" )
local vcVoiceProfile            = CreateConVar( "sv_npcvoicechat_spawnvoiceprofile", "", cvarFlag, "The Voice Profile the newly created NPC should be spawned with. Note: This will override every player's client option with this one" )
local vcVoiceProfileChance      = CreateConVar( "sv_npcvoicechat_randomvoiceprofilechance", "0", cvarFlag, "The chance the a NPC will use a random available Voice Profile as their voice profile after they spawn" )
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
    local _, voicePfpDirs = file_Find( "sound/" .. path .. "/*", "GAME" )
    if !voicePfpDirs then return end
    
    for _, voicePfp in ipairs( voicePfpDirs ) do
        for voiceType, _ in pairs( defVoiceTypeDirs ) do 
            local voiceTypePath = path .. "/" .. voicePfp .. "/" .. voiceType
            local voicelines = file_Find( "sound/" .. voiceTypePath .. "/*", "GAME" )
            if !voicelines or #voicelines == 0 then continue end

            NPCVC.VoiceProfiles[ voicePfp ] = ( NPCVC.VoiceProfiles[ voicePfp ] or {} )
            NPCVC.VoiceProfiles[ voicePfp ][ voiceType ] = {}

            for _, voiceline in ipairs( voicelines ) do
                table_insert( NPCVC.VoiceProfiles[ voicePfp ][ voiceType ], voiceTypePath .. "/" .. voiceline )
            end
        end
    end
end

local function UpdateData( ply )
    if ply and IsValid( ply ) and !ply:IsSuperAdmin() then return end

    local names = file_Read( "npcvoicechat/names.json", "DATA" )
    if !names then
        NPCVC.NickNames = defaultNames
        file_Write( "npcvoicechat/names.json", TableToJSON( defaultNames ) )
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
        local snds = file_Find( "sound/" .. sndDir .. "*", "GAME" )
        if !snds or #snds == 0 then continue end

        local lineTbl = {}
        for _, snd in ipairs( snds ) do lineTbl[ #lineTbl + 1 ] = sndDir .. snd end
        NPCVC.VoiceLines[ voiceType ] = lineTbl
    end

    table_Empty( NPCVC.ProfilePictures )
    local pfpPics = file_Find( "materials/npcvcdata/profilepics/*", "GAME" )
    if pfpPics and #pfpPics > 0 then
        for _, pfpPic in ipairs( pfpPics ) do
            NPCVC.ProfilePictures[ #NPCVC.ProfilePictures + 1 ] = "npcvcdata/profilepics/" .. pfpPic
        end
    end

    table_Empty( NPCVC.UserPFPs )
    pfpPics = file_Find( "materials/npcvcdata/custompfps/*", "GAME" )
    if pfpPics and #pfpPics > 0 then
        for _, pfpPic in ipairs( pfpPics ) do
            NPCVC.UserPFPs[ #NPCVC.UserPFPs + 1 ] = "npcvcdata/custompfps/" .. pfpPic
        end
    end

    table_Empty( NPCVC.VoiceProfiles )
    AddVoiceProfile( "npcvoicechat/voiceprofiles" )
    AddVoiceProfile( "lambdaplayers/voiceprofiles" )
    AddVoiceProfile( "zetaplayer/custom_vo" )

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
    if self.IsDrGNextbot and IsValid( ragdoll ) then
        local sndEmitter = self:GetNW2Entity( "npcsqueakers_sndemitter" )
        if IsValid( sndEmitter ) then sndEmitter:SetSoundSource( ragdoll ) end
    end
    return ragdoll
end

local function GetVoiceLine( ent, voiceType )
    local voiceTbl

    local voicePfp = NPCVC.VoiceProfiles[ ent.NPCVC_VoiceProfile ]
    if voicePfp then
        voiceTbl = voicePfp[ voiceType ]
    else
        local voicelineTbl = ( ( LambdaVoiceLinesTable and vcUseLambdaVoicelines:GetBool() ) and LambdaVoiceLinesTable or NPCVC.VoiceLines ) 
        voiceTbl = voicelineTbl[ voiceType ]
    end
    if ( !voiceTbl or #voiceTbl == 0 ) and ( !voicePfp or !vcVoiceProfileFallback:GetBool() ) then return end

    local realTime = RealTime()
    randomseed( ent:EntIndex() + ent:GetCreationID() + os_time() + realTime )

    for _, voiceLine in RandomPairs( voiceTbl ) do
        local useTime = NPCVC.LastUsedLines[ voiceLine ]
        if useTime then
            if realTime > useTime then
                NPCVC.LastUsedLines[ voiceLine ] = nil
            else
                continue
            end
        else
            NPCVC.LastUsedLines[ voiceLine ] = ( realTime + 600 )
        end

        return voiceLine
    end

    return voiceTbl[ random( #voiceTbl ) ]
end

function NPCVC:PlayVoiceLine( npc, voiceType, dontDeleteOnRemove, isInput )
    if !npc.NPCVC_Initialized or npc.NPCVC_IsKilled and voiceType != "death" or NPCVC.NPCBlacklist[ npc:GetClass() ] then return end
    if voiceType != "laugh" and NPCVC:IsCurrentlySpeaking( npc, "laugh" ) then return end
    if npc.LastPathingInfraction and !vcAllowSanics:GetBool() then return end
    if npc.SBAdvancedNextBot and !vcAllowSBNextbots:GetBool() then return end
    if npc.MNG_TF2Bot and !vcAllowTF2Bots:GetBool() then return end
    if npc.IsDrGNextbot and ( npc:IsPossessed() or !vcAllowDrGBase:GetBool() ) then return end
    if npc.IsVJBaseSNPC then
        if npc.VJ_IsBeingControlled or npc:GetState() != 0 or !vcAllowVJBase:GetBool() then return end
    elseif npc:IsNPC() and !vcAllowNPCs:GetBool() then 
        return 
    end
    if !ignoreGagTypes[ voiceType ] and vcIgnoreGagged:GetBool() and npc:HasSpawnFlags( SF_NPC_GAG ) then return end

    local oldEmitter = npc:GetNW2Entity( "npcsqueakers_sndemitter" )
    if !NPCVC.TalkingNPCs[ oldEmitter ] and ( voiceType != "death" or !vcLimitAffectsDeath:GetBool() ) then
        local speakLimit = vcSpeakLimit:GetInt()
        if speakLimit > 0 and table_Count( NPCVC.TalkingNPCs ) >= speakLimit then return end
    end

    local sndName = GetVoiceLine( npc, voiceType )
    if !sndName then return end

    local sndEmitter = ents_Create( "npc_vc_sndemitter" )
    if !IsValid( sndEmitter ) then return end

    sndEmitter:SetPos( npc:GetPos() )
    sndEmitter:SetOwner( npc )
    sndEmitter.DontRemoveEntity = dontDeleteOnRemove
    sndEmitter:Spawn()

    local enemyPlyData = npc.NPCVC_EnemyPlayers
    if !enemyPlyData or CurTime() > enemyPlyData.UpdateTime then
        enemyPlyData = { UpdateTime = ( CurTime() + 30 ) }

        for _, ply in ipairs( GetHumans() ) do
            if NPCVC:GetDispositionOfNPC( npc, ply ) != D_HT then continue end
            enemyPlyData[ ply ] = true
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
        EnemyPlayers = enemyPlyData
    }

    SimpleTimer( ( ( IsSinglePlayer() and isInput != true ) and 0 or 0.1 ), function()
        net.Start( "npcsqueakers_playsound" )
            net.WriteString( sndName )
            net.WriteTable( vcData )
            net.WriteFloat( !vcSlightDelay:GetBool() and 0 or Rand( 0.0, 0.75 ) )
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

function NPCVC:IsCurrentlySpeaking( npc, voiceType )
    if voiceType and npc.NPCVC_LastVoiceLine != voiceType then return false end
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

local function GetNPCProfilePicture( npc )
    if vcUseCustomPfps:GetBool() then
        if vcUseLambdaPfpPics:GetBool() and #Lambdaprofilepictures != 0 then
            return Lambdaprofilepictures[ random( #Lambdaprofilepictures ) ]
        else
            local pfpPics = NPCVC.ProfilePictures
            local userPfps = NPCVC.UserPFPs
            if #userPfps != 0 then
                if vcUserPfpsOnly:GetBool() then
                    pfpPics = userPfps
                else
                    pfpPics = table_Merge( pfpPics, userPfps )
                end
            end
            if #pfpPics != 0 then return pfpPics[ random( #pfpPics ) ] end
        end
    end

    local npcClass = npc:GetClass()
    local npcModel = npc:GetModel()

    local cacheType = npcModel
    local profilePic = NPCVC.CachedNPCPfps[ cacheType ]
    if !profilePic then
        cacheType = npcClass
        profilePic = NPCVC.CachedNPCPfps[ cacheType ]
    end

    if profilePic == nil or profilePic != false then
        -- Least deranged man's code
        local iconName, iconMat
        if vcUseModelIcon:GetBool() then 
            if npcModel and #npcModel != 0 then
                iconName = "spawnicons/".. string_sub( npcModel, 1, #npcModel - 4 ).. ".png"
                iconMat = Material( iconName )
            end

            if iconMat:IsError() then
                iconName = "entities/" .. npcClass .. ".png"
                iconMat = Material( iconName )

                if iconMat:IsError() then
                    iconName = "entities/" .. npcClass .. ".jpg"
                    iconMat = Material( iconName )

                    if iconMat:IsError() then
                        iconName = "vgui/entities/" .. npcClass
                        iconMat = Material( iconName )
                    end
                end
            end
        else
            iconName = "entities/" .. npcClass .. ".png"
            iconMat = Material( iconName )

            if iconMat:IsError() then
                iconName = "entities/" .. npcClass .. ".jpg"
                iconMat = Material( iconName )

                if iconMat:IsError() then
                    iconName = "vgui/entities/" .. npcClass
                    iconMat = Material( iconName )

                    if npcModel and #npcModel != 0 and iconMat:IsError() then
                        iconName = "spawnicons/".. string_sub( npcModel, 1, #npcModel - 4 ).. ".png"
                        iconMat = Material( iconName )
                    end
                end
            end
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

    for _, npc in ipairs( FindInSphere( entPos, 1500 ) ) do
        if npc == ent or !IsValid( npc ) or !npc.NPCVC_Initialized or random( 1, 100 ) > npc.NPCVC_SpeechChance or npc:GetInternalVariable( "m_lifeState" ) != 0 or ( random( 1, 3 ) != 1 and NPCVC:IsCurrentlySpeaking( npc ) ) then continue end

        local locAttacker = attacker
        if npc:GetClass() == "reckless_kleiner" and attacker == npc:GetParent() then
            locAttacker = npc
        end

        if locAttacker == npc then
            if killLines and npc.NPCVC_LastValidEnemy == ent and !NPCVC:IsCurrentlySpeaking( npc, "laugh" ) and !NPCVC:IsCurrentlySpeaking( npc, "kill" ) then
                NPCVC:PlayVoiceLine( npc, ( random( 1, 5 ) == 1 and "laugh" or "kill" ) )
                continue
            end
        elseif attackPos and random( 1, 2 ) != 1 then
            if ( locAttacker == ent or locAttacker:IsWorld() or NPCVC:GetDispositionOfNPC( locAttacker, ent ) == D_LI ) and !NPCVC:IsCurrentlySpeaking( npc, "laugh" ) then
                NPCVC:PlayVoiceLine( npc, "laugh" )
                continue
            end

            if assistLines and !NPCVC:IsCurrentlySpeaking( npc, "assist" ) and NPCVC:GetDispositionOfNPC( npc, locAttacker ) != D_HT and attackPos:DistToSqr( npc:GetPos() ) <= 1000000 then
                local isEnemy = ( npc.NPCVC_LastValidEnemy == ent )
                if !isEnemy and npc:IsNPC() then
                    for _, knownEne in ipairs( npc:GetKnownEnemies() ) do
                        isEnemy = ( knownEne == ent )
                        if isEnemy then break end
                    end
                end
                if isEnemy then
                    NPCVC:PlayVoiceLine( npc, "assist" )
                    continue
                end
            end

            local entDisp = NPCVC:GetDispositionOfNPC( npc, ent )
            if entDisp >= 3 and entPos:DistToSqr( npc:GetPos() ) <= ( !npc:Visible( ent ) and 40000 or 4000000 ) and !NPCVC:IsCurrentlySpeaking( npc, "panic" ) and !NPCVC:IsCurrentlySpeaking( npc, "witness" ) then
                NPCVC:PlayVoiceLine( npc, ( random( 1, 3 ) == 1 and "panic" or "witness" ) )
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
        npc.NPCVC_NextIdleSpeak = ( CurTime() + Rand( 0, 15 ) )
        npc.NPCVC_NextDangerSoundTime = 0
        if npc.NPCVC_Initialized then return end

        local npcClass = npc:GetClass()
        local whitelistVoice = NPCVC.NPCWhitelist[ npcClass ]
        if !whitelistVoice then
            if !npc.IsGmodZombie and !npc.MNG_TF2Bot and !npc.SBAdvancedNextBot and !npc.IsDrGNextbot and !npc.IV04NextBot and !npc.LastPathingInfraction and npcClass != "reckless_kleiner" and npcClass != "npc_antlion_grub" and ( !npc:IsNPC() or nonNPCNPCs[ npcClass ] or string_find( npcClass, "bullseye" ) ) then return end
            if IsBasedOn( npcClass, "animprop_generic" ) or IsBasedOn( npcClass, "animprop_generic_physmodel" ) then return end
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

        if npc.LastPathingInfraction then
            npc.NPCVC_VoiceIconHeight = 138
            npc.NPCVC_VoiceVolumeScale = 2
        else
            local height = ( npcIconHeights[ npcClass ] or ( npc:OBBMaxs().z + 10 )  )
            npc.NPCVC_VoiceIconHeight = height
            npc.NPCVC_VoiceVolumeScale = Clamp( ( abs( height ) / 72 ), 0.66, 2.5 )
        end

        if !npc.NPCVC_IsDuplicated then
            local speechChance = vcForceSpeechChance:GetInt()
            if speechChance == 0 then speechChance = random( 0, 100 ) end
            npc.NPCVC_SpeechChance = speechChance
            
            local voicePitch = random( vcPitchMin:GetInt(), vcPitchMax:GetInt() )
            npc.NPCVC_VoicePitch = voicePitch
            
            local nickName
            if vcUseRealNames:GetBool() then
                nickName = "#" .. npcClass
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

            if mapSavedData and transitionSaveNPCs[ npcClass ] then
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
                    if vcAllowLines_SpotDanger:GetBool() and !NPCVC:IsCurrentlySpeaking( npc, "panic" ) and !NPCVC:IsCurrentlySpeaking( npc, "witness" ) then
                        NPCVC:PlayVoiceLine( npc, "witness" or "panic" )
                    end
                elseif random( 1, 100 ) <= npc.NPCVC_SpeechChance and !NPCVC:IsCurrentlySpeaking( npc ) then
                    if sdSet == "MedicReceiveHeal" and vcAllowLines_Assist:GetBool() then
                        NPCVC:PlayVoiceLine( npc, "assist" )
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

    if ( random( 1, 100 ) <= npc.NPCVC_SpeechChance or !vcSpeakChanceAffectDeath:GetBool() or NPCVC:IsCurrentlySpeaking( npc ) ) and vcAllowLines_Death:GetBool() then
        NPCVC:PlayVoiceLine( npc, "death", true, isInput )
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
    if !owner.NPCVC_Initialized then return end
    local sndEmitter = owner:GetNW2Entity( "npcsqueakers_sndemitter" )
    if IsValid( sndEmitter ) then sndEmitter:SetSoundSource( ragdoll ) end
end

local function OnServerThink()
    local curTime = CurTime()
    if curTime < nextNPCSoundThink then return end

    nextNPCSoundThink = ( curTime + 0.1 )
    if aiDisabled:GetBool() then return end

    for _, npc in ipairs( ents_GetAll() ) do
        if !IsValid( npc ) or !npc.NPCVC_Initialized then continue end
        
        local npcClass = npc:GetClass()
        if npcClass == "monster_leech" and npc:GetInternalVariable( "m_takedamage" ) == 0 then
            return
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
                    elseif curState == NPC_STATE_COMBAT and vcAllowLines_SpotEnemy:GetBool() then
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
        elseif npcClass == "npc_antlion_grub" then
            local curState = npc:GetInternalVariable( "m_State" )

            if npc:GetInternalVariable( "m_takedamage" ) == 0 then
                if npc.NPCVC_LastState != -1 then
                    npc.NPCVC_LastState = -1
                    OnNPCKilled( npc, nil, nil )
                end
            else
                local curState = npc:GetInternalVariable( "m_State" )
                if random( 1, 100 ) <= npc.NPCVC_SpeechChance then
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
                    local barnacled = npc:IsEFlagSet( EFL_IS_BEING_LIFTED_BY_BARNACLE )
                    if !barnacled then
                        local curAct = npc:GetSequenceActivityName( npc:GetSequence() )
                        barnacled = ( curAct == "ACT_BARNACLE_PULL" or curAct == "ACT_BARNACLE_CHEW" or curAct == "ACT_BARNACLE_CHOMP" )
                    end

                    local isPurelyPanic = vcAllowLines_PanicCond:GetBool()
                    local stopSpeech = ( rolledSpeech == true )
                    if isPurelyPanic then
                        isPurelyPanic = ( barnacled or npc:IsOnFire() or npc:IsPlayerHolding() and !npc:GetInternalVariable( "m_bHackedByAlyx" ) or npc:IsNPC() and ( npc:GetInternalVariable( "m_nFlyMode" ) == 6 or ( npc:GetCurrentSchedule() + 1000000000 ) == GetScheduleID( "SCHED_ANTLION_FLIP" ) ) )

                        local engineStallT = npc:GetInternalVariable( "m_flEngineStallTime" )
                        if !isPurelyPanic and engineStallT then isPurelyPanic = ( engineStallT > 0.5 ) end

                        if !isPurelyPanic then
                            local phys = npc:GetPhysicsObject()
                            if IsValid( phys ) and phys:GetVelocity():Length() >= 500 and IsValidProp( npc:GetModel() ) then
                                isPurelyPanic = true
                                stopSpeech = true
                            end
                        end

                        if !isPurelyPanic and drownNPCs[ npcClass ] then
                            waterCheckTr.start = npc:WorldSpaceCenter()
                            waterCheckTr.endpos = ( waterCheckTr.start + npc:GetVelocity() )
                            waterCheckTr.filter = npc
                            waterCheckTr.collisiongroup = npc:GetCollisionGroup()

                            isPurelyPanic = ( band( PointContents( TraceLine( waterCheckTr ).HitPos ), CONTENTS_WATER ) != 0 )
                        end
                    end

                    if isPurelyPanic then
                        if !NPCVC:IsCurrentlySpeaking( npc, "panic" ) then
                            NPCVC:PlayVoiceLine( npc, "panic" )
                        end

                        if barnacled then
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
                            if !isPanicking and !npc.IsVJBaseSNPC and npc:IsNPC() then
                                isPanicking = ( IsValid( curEnemy ) and ( noWepFearNPCs[ npcClass ] and !IsValid( npc:GetActiveWeapon() ) or NPCVC:GetDispositionOfNPC( npc, curEnemy ) == D_FR and ( !dontFearNPCs[ curEnemy:GetClass() ] or npc:GetPos():DistToSqr( curEnemy:GetPos() ) <= 200 ) ) )
                            end
                            if !isPanicking then
                                isPanicking = ( npc.NoWeapon_UseScaredBehavior and !IsValid( npc:GetActiveWeapon() ) )
                            end

                            if curEnemy == lastEnemy and IsValid( lastEnemy ) and ( ( curTime - npc.NPCVC_LastSeenEnemyTime ) >= 15 or npc:GetPos():DistToSqr( curEnemy:GetPos() ) > 2250000 ) then
                                combatLine = "idle"
                            elseif isPanicking or lowHP and random( 1, ( 6 * ( lowHP / ( npc:Health() / npc:GetMaxHealth() ) ) ) ) == 1 then
                                if curEnemy.LastPathingInfraction or npc:GetPos():DistToSqr( curEnemy:GetPos() ) <= 250000 or npc:Visible( curEnemy ) then
                                    combatLine = "panic"
                                else 
                                    combatLine = "idle"
                                end
                            end
                        end

                        if !npc.IsVJBaseSNPC and curTime >= npc.NPCVC_NextDangerSoundTime and vcAllowLines_SpotDanger:GetBool() and npc:IsNPC() and !NPCVC:IsCurrentlySpeaking( npc, "panic" ) and !NPCVC:IsCurrentlySpeaking( npc, "witness" ) and ( npc:HasCondition( 50 ) or npc:HasCondition( 57 ) ) then
                            NPCVC:PlayVoiceLine( npc, "panic" )
                            npc.NPCVC_NextDangerSoundTime = ( curTime + 5 )
                        elseif npc:IsNPC() and !npc.IsVJBaseSNPC and !hlsNPCs[ npcClass ] and npcClass != "npc_barnacle" and npcClass != "reckless_kleiner" and ( !noStateUseNPCs[ npcClass ] or npcClass == "npc_turret_ceiling" and !npc:GetInternalVariable( "m_bActive" ) ) then
                            local curState = npc:GetNPCState()

                            if rolledSpeech then
                                if curState != npc.NPCVC_LastState then
                                    if curState == NPC_STATE_COMBAT and !IsValid( lastEnemy ) and vcAllowLines_SpotEnemy:GetBool() and !NPCVC:IsCurrentlySpeaking( npc, "taunt" ) and !NPCVC:IsCurrentlySpeaking( npc, "panic" ) then
                                        NPCVC:PlayVoiceLine( npc, combatLine )
                                    end
                                elseif curTime >= npc.NPCVC_NextIdleSpeak and !NPCVC:IsCurrentlySpeaking( npc ) then
                                    if curState == NPC_STATE_COMBAT and IsValid( curEnemy ) then
                                        if vcAllowLines_CombatIdle:GetBool() then
                                            NPCVC:PlayVoiceLine( npc, combatLine )
                                        end
                                    elseif ( curState == NPC_STATE_IDLE or curState == NPC_STATE_ALERT ) and vcAllowLines_Idle:GetBool() then
                                        NPCVC:PlayVoiceLine( npc, "idle" )
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
                                    if IsValid( curEnemy ) and !IsValid( lastEnemy ) and vcAllowLines_SpotEnemy:GetBool() and !NPCVC:IsCurrentlySpeaking( npc, "taunt" ) and !NPCVC:IsCurrentlySpeaking( npc, "panic" ) then
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
                if npc:Visible( curEnemy ) then npc.NPCVC_LastSeenEnemyTime = curTime end
            end
        end

        if curTime >= npc.NPCVC_NextIdleSpeak then
            npc.NPCVC_NextIdleSpeak = ( curTime + Rand( 0, 15 ) )
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

    if input == "BecomeRagdoll" then
        OnNPCKilled( ent, activator, caller, true )
        return
    end

    if input == "Kill" and hlsNPCs[ ent:GetClass() ] then -- HL:S NPCs only >:(
        OnNPCKilled( ent, activator, caller )
    end
end

local function OnPropBreak( attacker, prop )
    if !IsValid( prop ) or !prop.NPCVC_Initialized or NPCVC:IsCurrentlySpeaking( prop, "death" ) then return end
    OnNPCKilled( prop, attacker )
end

local function OnServerShutDown()
    if !vcSaveNPCDataOnMapChange:GetBool() then
        local mapSavedNPCs = file_Read( "npcvoicechat/mapsavednpcs.json", "DATA" )
        if mapSavedNPCs then file_Delete( "npcvoicechat/mapsavednpcs.json" ) end
    elseif NPCVC.MapTransitionNPCs then
        file_Write( "npcvoicechat/mapsavednpcs.json", TableToJSON( NPCVC.MapTransitionNPCs ) )
    end
end

hook.Add( "OnEntityCreated", "NPCSqueakers_OnEntityCreated", OnEntityCreated )
hook.Add( "PlayerSpawnedNPC", "NPCSqueakers_OnPlayerSpawnedNPC", OnPlayerSpawnedNPC )
hook.Add( "OnNPCKilled", "NPCSqueakers_OnNPCKilled", OnNPCKilled )
hook.Add( "PlayerDeath", "NPCSqueakers_OnPlayerDeath", OnPlayerDeath )
hook.Add( "CreateEntityRagdoll", "NPCSqueakers_OnCreateEntityRagdoll", OnCreateEntityRagdoll )
hook.Add( "Think", "NPCSqueakers_OnServerThink", OnServerThink )
hook.Add( "PostEntityTakeDamage", "NPCSqueakers_OnPostEntityTakeDamage", OnPostEntityTakeDamage )
hook.Add( "AcceptInput", "NPCSqueakers_OnAcceptInput", OnAcceptInput )
hook.Add( "PropBreak", "NPCSqueakers_OnPropBreak", OnPropBreak )
hook.Add( "ShutDown", "NPCSqueakers_OnServerShutDown", OnServerShutDown )
hook.Add( "InitPostEntity", "NPCSqueakers_OnMapInitialized", UpdateData )