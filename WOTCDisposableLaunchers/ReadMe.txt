Created by Iridar

More info here: https://patreon.com/Iridar/

todo
- validate slot
- combat knife ignored as a melee weapon

### Information for Reference:

Template names for actual Disposable Launchers
IRI_RPG_CV
IRI_RPG_MG
IRI_RPG_BM

Template names for items you see in the armory inventory
IRI_RPG_CV_Utility
IRI_RPG_CV_Secondary
IRI_RPG_CV_Heavy

IRI_RPG_MG_Utility
IRI_RPG_MG_Secondary
IRI_RPG_MG_Heavy

IRI_RPG_BM_Utility
IRI_RPG_BM_Secondary
IRI_RPG_BM_Heavy

### Inventory Setup

Ideally, I would like Disposable Rocket Launchers (DRLs) to be mutually exclusive with each other. So you can carry only one launcher per soldier.
I would also like to make it impossible to equip a Utility DRL alongside an offensive grenade in another Utility Slot.
At the same time, ideally it should be possible to equip a Secondary / Heavy versions of DRL alongside a grenade in a Utility Slot, cuz why not? Normal Heavy Weapons allow it.

Unfortunately, for the purposes of UniqueEquip, the WeaponCat is checked at all ONLY if the ItemCat is NOT UniqueEquip.

Basically this means I can either make ALL DRLs to be ONLY mutually exclusive with each other
Or to make ALL DRLs to be mutually exclusive with ALL offensive grenades. 

It's not possible to make only SOME DRLs mutually exclusive with grenades while making them mutually exclusive with ALL DRLs.

So you have several options here:

1) The default configuration: 

All DRLs are made mutually exclusive with offensive grenades through ItemCat. 
The WeaponCat here matters only for the Secondary DRL so that Grenadiers can equp it.

- These two fields decide categories for the DRLs themselves that get equipped in the hidden Highlander inventory slot.
This slot is ignored for the purposes of UniqueEquip categories, so they only matter for the purposes of Breakthroughs.
RPG_ItemCat = "weapon"
RPG_WeaponCat = "heavy"

- These are categories for the items that you equip on your soldiers in the Armory.
RPG_Utility_ItemCat = "grenade"
RPG_Utility_WeaponCat = "iri_disposable_launcher"

RPG_Secondary_ItemCat = "grenade"
RPG_Secondary_WeaponCat = "iri_disposable_launcher"

RPG_Heavy_ItemCat = "grenade"
RPG_Heavy_WeaponCat = "iri_disposable_launcher"

2) Alternative configuration

Here the Utility DRL will be mutually exclusive with offensive grenades in Utility Slots through ItemCat.
And Secondary / Heavy DRLs will be mutually exclusive with each other through Weapon Cat.

However, in some cases you will be able to equip a Utility DRL alongside a Heavy / Secondary DRL.

RPG_Utility_ItemCat = "grenade"
RPG_Utility_WeaponCat = "iri_disposable_launcher"

RPG_Secondary_ItemCat = "weapon"
RPG_Secondary_WeaponCat = "iri_disposable_launcher"

RPG_Heavy_ItemCat = "weapon"
RPG_Heavy_WeaponCat = "iri_disposable_launcher"


--------------


[h1]FEATURES[/h1]

This mod adds three tiers of single-shot Disposable Rocket Launchers (DRLs). They offer a heavier alternative to [b]Frag Grenades[/b] - they deal more damage and can be used at longer ranges, but they can miss the targeted area and [b]scatter[/b]. 

Rocket scatter scales with soldier's Aim, and it gets worse if you fire the DRL with only one action remaining.

[h1]REQUIREMENTS[/h1]

[url=https://steamcommunity.com/workshop/filedetails/?id=1134256495][b]X2 WOTC Community Highlander[/b][/url] is required.

Safe to add mid-campaign, but I don't recommend doing it during a tactical mission just in case.

[h1]HOW TO ACQUIRE[/h1]

Conventional launchers are available from the start in infinite quantities. They are then upgraded in [b]Proving Grounds[/b]: [b]Alien Grenade[/b] project will unlock magnetic tier, and [b]Advanced Explosives[/b] project will unlock beam tier.

[h1]HOW TO USE[/h1]

[b]Utility Slot[/b] - any soldier class can carry a Disposable Launcher in a Utility Slot, however that comes with certain penalties and restrictions:[list]
[*] -1 Mobility
[*] +20% Detection Radius
[*] Cannot carry offensive grenades in other Utility Slots. 
[*] Penalties are removed once the Launcher is fired and disposed of.
[*] Disposable Launchers cannot be carried in Grenade-only slots.[/list]
[b]Heavy Weapon Slot[/b] - any soldier can carry a Disposable Launcher in Heavy Weapon slot without any penalties or restrictions.

[b]Secondary Weapon Slot[/b] - Grenadiers can carry a Disposable Launcher as a Secondary Weapon. If you have [b][url=https://steamcommunity.com/sharedfiles/filedetails/?id=1533060800]Open Class Weapon Restrictions[/url][/b] mod, all classes that can use a Grenade Launcher as a secondary weapon will be able to carry a Disposable Launcher in that slot as well.

You're allowed to carry only one Disposable Rocket Launcher per soldier.

[h1]KNOWN ISSUES[/h1]

Sometimes some soldiers become unable to equip a DRL, showing the error message that the soldier already has a DRL equipped. If that happens, use this console command:
[code]UnequipDisposableLaunchers[/code]
For best results, use this command twice in a row. It will unequip DRLs from all soldiers in your campaign. Probably shouldn't use this command while you have someone with a DRL on a Covert Action.

[h1]CONFIGURATION[/h1]

The mod is [i][b]highly[/b][/i] configurable through:

[code]..\steamapps\workshop\content\268500\1626184587\Config\XComDisposableLaunchers.ini[/code]

[h1]COMPATIBILITY[/h1]

Should be compatible with almost anything.

[h1]CREDITS[/h1]

The Magnetic and Beam launchers are ported from PlanetSide 2. They are owned by Daybreak Games Company, and will be removed at their request.

Thanks to E3245 for his koalified help with PS2 textures and the authentic AT4 model.

Thanks to Beaglerush for his consultations on the mod balance and demo-ing the mod during his XCOM 2 streams, which you can [b][url=https://www.twitch.tv/beagsandjam]watch here[/url][/b].

Thanks to Pavonis Interactive for their rocket scatter code, and to Favid for bringing it over from LW2 to WOTC.

This mod was made possible by my wonderful supporters on Patreon. The theme of the mod was chosen by them with a vote, and their feedback helped shape the mod.

Please consider [b][url=https://www.patreon.com/Iridar]supporting me on patreon[/url][/b] so I can afford the time to make more awesome mods.