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