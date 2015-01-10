BuildStoreMenu(client) {

	new Handle:menu					=	CreateMenu(BuildStoreHandle);
	
	decl String:text[512];
	Format(text, sizeof(text), "%T", "Store Header", client, SkyPoints[client]);
	SetMenuTitle(menu, text);
	decl String:Name[64];
	decl String:Name_Temp[64];
	decl String:pct[4];
	Format(pct, sizeof(pct), "%");

	new StoreCost					=	0;
	new Duration					=	0;
	new Float:ItemStrength			=	0.0;
	new Seconds						=	0;

	new Hours						=	0;
	new Minutes						=	0;

	new Amount						=	0;
	new Float:AmountMin				=	0.0;
	new Float:AmountMax				=	0.0;


	decl String:durationtext[512];

	new size						=	GetArraySize(a_Store);

	for (new i = 0; i < size; i++) {

		MenuKeys[client]			=	GetArrayCell(a_Store, i, 0);
		MenuValues[client]			=	GetArrayCell(a_Store, i, 1);
		MenuSection[client]			=	GetArrayCell(a_Store, i, 2);

		GetArrayString(Handle:MenuSection[client], 0, Name, sizeof(Name));

		Hours						=	0;
		Minutes						=	0;
		StoreCost		= StringToInt(GetKeyValue(MenuKeys[client], MenuValues[client], "store cost?"));
		Duration		= StringToInt(GetKeyValue(MenuKeys[client], MenuValues[client], "duration?"));
		ItemStrength	= StringToFloat(GetKeyValue(MenuKeys[client], MenuValues[client], "item strength?"));
		Amount			= StringToInt(GetKeyValue(MenuKeys[client], MenuValues[client], "amount?"));
		AmountMin		= StringToFloat(GetKeyValue(MenuKeys[client], MenuValues[client], "amount min?"));
		AmountMax		= StringToFloat(GetKeyValue(MenuKeys[client], MenuValues[client], "amount max?"));

		if (Duration == 0) Format(durationtext, sizeof(durationtext), "");
		else {

			while (Duration >= 3600) {

				Hours++;
				Duration -= 3600;
			}
			while (Duration >= 60) {

				Minutes++;
				Duration -= 60;
			}
			Format(durationtext, sizeof(durationtext), "%dH %dM %dS", Hours, Minutes, Duration);
		}
		Format(Name_Temp, sizeof(Name_Temp), "%T", Name, client);
		if (ItemStrength > 0.0) {

			decl String:Store_Player_Value[512];
			GetArrayString(Handle:a_Store_Player[client], i, Store_Player_Value, sizeof(Store_Player_Value));

			if (StringToInt(Store_Player_Value) < 1) Format(durationtext, sizeof(durationtext), "%s (%3.1f%s)", durationtext, ItemStrength * 100.0, pct);
			else {

				Seconds					=	StringToInt(Store_Player_Value);
				Hours					=	0;
				Minutes					=	0;
				while (Seconds >= 3600) {

					Hours++;
					Seconds -= 3600;
				}
				while (Seconds >= 60) {

					Minutes++;
					Seconds -= 60;
				}
				Format(durationtext, sizeof(durationtext), "%s (%3.1f%s)\n%dH %dM %dS", durationtext, ItemStrength * 100.0, pct, Hours, Minutes, Seconds);
			}
		}
		decl String:AmountText[64];
		Format(AmountText, sizeof(AmountText), "");
		if (AmountMax > AmountMin && AmountMax != 0) Format(AmountText, sizeof(AmountText), "%T", "Store Amount Range", client, RoundToFloor(AmountMin * CheckExperienceRequirement(client)), RoundToFloor(AmountMax * CheckExperienceRequirement(client)));
		else if (AmountMin > 0) Format(AmountText, sizeof(AmountText), "%T", "Store Amount Static", client, RoundToFloor(AmountMin * CheckExperienceRequirement(client)));
		else if (Amount > 0) Format(AmountText, sizeof(AmountText), "%T", "Store Amount Static", client, Amount);
		if (strlen(AmountText) >= 1) Format(AmountText, sizeof(AmountText), "(%s)", AmountText);
		Format(Name_Temp, sizeof(Name_Temp), "%T", "Store Option", client, Name_Temp, StoreCost, durationtext, AmountText);
		AddMenuItem(menu, Name_Temp, Name_Temp);
	}

	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 0);
}

stock GiveClientStoreItem(client, pos) {



	decl String:slotvalue[64];

	new Duration		= 0;
	new Amount			= 0;
	new Float:AmountMin	= 0.0;
	new Float:AmountMax	= 0.0;

	decl String:ItemEffect[64];

	new Handle:Keys		= CreateArray(64);
	new Handle:Values	= CreateArray(64);

	Keys				= GetArrayCell(a_Store, pos, 0);
	Values				= GetArrayCell(a_Store, pos, 1);

	Duration		= StringToInt(GetKeyValue(Keys, Values, "duration?"));
	Format(ItemEffect, sizeof(ItemEffect), "%s", GetKeyValue(Keys, Values, "item effect?"));
	Amount			= StringToInt(GetKeyValue(Keys, Values, "amount?"));
	AmountMin		= StringToFloat(GetKeyValue(Keys, Values, "amount min?"));
	AmountMax		= StringToFloat(GetKeyValue(Keys, Values, "amount max?"));

	if (Duration > 0) {

		GetArrayString(a_Store_Player[client], pos, slotvalue, sizeof(slotvalue));
		Format(slotvalue, sizeof(slotvalue), "%d", StringToInt(slotvalue) + Duration);
		SetArrayString(a_Store_Player[client], pos, slotvalue);
	}
	if (FindCharInString(ItemEffect, 'r') != -1) {

		FreeUpgrades[client]								=	PlayerUpgradesTotal[client];
		PlayerUpgradesTotal[client] = 0;
		WipeTalentPoints(client);
	}
	if (FindCharInString(ItemEffect, 't') != -1) {

		FreeUpgrades[client]								+=	Amount;
	}
	if (FindCharInString(ItemEffect, 's') != -1) {

		SlatePoints[client]									+=	Amount;
	}
	if (FindCharInString(ItemEffect, 'e') != -1) {

		if (AmountMin > AmountMax) AmountMax					= AmountMin;
		if (AmountMin != AmountMax) AmountMin					= GetRandomFloat(AmountMin, AmountMax);
		ExperienceLevel[client]								+=	RoundToFloor(AmountMin * CheckExperienceRequirement(client));
		ExperienceOverall[client]							+=	RoundToFloor(AmountMin * CheckExperienceRequirement(client));
		if (ExperienceLevel[client] > CheckExperienceRequirement(client)) {

			ExperienceOverall[client] -= (ExperienceLevel[client] - CheckExperienceRequirement(client));
			ExperienceLevel[client] = CheckExperienceRequirement(client);
		}
	}
	CloseHandle(Keys);
	CloseHandle(Values);
}

public BuildStoreHandle(Handle:menu, MenuAction:action, client, slot) {

	if (action == MenuAction_Select) {

		decl String:key[64];

		decl String:slotvalue[64];


		new StoreCost				=	0;
		new Duration				=	0;
		new Amount					=	0;
		new Float:AmountMin			=	0.0;
		new Float:AmountMax			=	0.0;
		decl String:ItemEffect[64];

		MenuKeys[client]			=	GetArrayCell(a_Store, slot, 0);
		MenuValues[client]			=	GetArrayCell(a_Store, slot, 1);

		StoreCost		= StringToInt(GetKeyValue(MenuKeys[client], MenuValues[client], "store cost?"));
		Duration		= StringToInt(GetKeyValue(MenuKeys[client], MenuValues[client], "duration?"));
		Format(ItemEffect, sizeof(ItemEffect), "%s", GetKeyValue(MenuKeys[client], MenuValues[client], "item effect?"));
		Amount			= StringToInt(GetKeyValue(MenuKeys[client], MenuValues[client], "amount?"));
		AmountMin		= StringToFloat(GetKeyValue(MenuKeys[client], MenuValues[client], "amount min?"));
		AmountMax		= StringToFloat(GetKeyValue(MenuKeys[client], MenuValues[client], "amount max?"));

		if (SkyPoints[client] >= StoreCost && GetArraySize(a_Store_Player[client]) == GetArraySize(a_Store)) {

			SkyPoints[client] -= StoreCost;
			if (Duration > 0) {

				GetArrayString(a_Store_Player[client], slot, slotvalue, sizeof(slotvalue));
				Format(slotvalue, sizeof(slotvalue), "%d", StringToInt(slotvalue) + Duration);
				SetArrayString(a_Store_Player[client], slot, slotvalue);
			}
			if (FindCharInString(ItemEffect, 'r') != -1) {

				FreeUpgrades[client]								+=	PlayerUpgradesTotal[client];
				PlayerUpgradesTotal[client]							=	0;
				WipeTalentPoints(client);
			}
			if (FindCharInString(ItemEffect, 't') != -1) {

				FreeUpgrades[client]								+=	Amount;
			}
			if (FindCharInString(ItemEffect, 's') != -1) {

				SlatePoints[client]									+=	Amount;
			}
			if (FindCharInString(ItemEffect, 'e') != -1) {

				if (AmountMin > AmountMax) AmountMax					= AmountMin;
				if (AmountMin != AmountMax) AmountMin					= GetRandomFloat(AmountMin, AmountMax);
				ExperienceLevel[client]								+=	RoundToFloor(AmountMin * CheckExperienceRequirement(client));
				ExperienceOverall[client]							+=	RoundToFloor(AmountMin * CheckExperienceRequirement(client));
				if (ExperienceLevel[client] > CheckExperienceRequirement(client)) {

					ExperienceOverall[client] -= (ExperienceLevel[client] - CheckExperienceRequirement(client));
					ExperienceLevel[client] = CheckExperienceRequirement(client);
				}
			}
			if (FindCharInString(ItemEffect, 'b') != -1) {

				new pos = -1;
				
				while (Amount > 0) {

					pos = -1;
					pos = IsStoreChance(client, client);
					if (pos >= 0) AwardStoreItems(client, client, pos);
					else {

						pos = -1;
						pos = IsLockedTalentChance(client);
						if (pos >= 0) AwardLockedTalentItems(client, pos);
					}
					if (pos != -1) Amount--;
				}
			}
		}
		else if (GetArraySize(a_Store_Player[client]) != GetArraySize(a_Store)) {

			GetClientAuthString(client, key, sizeof(key));
			LoadStoreData(client, key);
		}
		BuildStoreMenu(client);
	}
	else if (action == MenuAction_End) {

		CloseHandle(menu);
	}
}

stock bool:ValidItemClients() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && !IsFakeClient(i) && !HasBoosterTime(i)) return true;
	}
	return false;
}

stock RemoveStoreTime(client) {

	decl String:key[64];
	decl String:PlayerValue[64];

	new size								= GetArraySize(a_Store);
	if (!b_IsLoadingStore[client] && GetArraySize(a_Store_Player[client]) != size) {

		GetClientAuthString(client, key, sizeof(key));
		LoadStoreData(client, key);
		return;				// If their data hasn't loaded for the store, we skip them.
	}
	if (b_IsLoadingStore[client]) return;		// If their data is currently loading, we skip them.
	for (new i = 0; i < size; i++) {

		StoreTimeKeys[client]				= GetArrayCell(a_Store, i, 0);
		StoreTimeValues[client]				= GetArrayCell(a_Store, i, 1);

		if (StringToInt(GetKeyValue(StoreTimeKeys[client], StoreTimeValues[client], "duration?")) > 0) {

			GetArrayString(a_Store_Player[client], i, PlayerValue, sizeof(PlayerValue));
			if (StringToInt(PlayerValue) > 0) {

				Format(PlayerValue, sizeof(PlayerValue), "%d", StringToInt(PlayerValue) - 1);
				SetArrayString(a_Store_Player[client], i, PlayerValue);
			}
		}
	}
}

stock bool:HasBoosterTime(client) {

	decl String:key[64];
	decl String:val[64];
	decl String:pva[64];

	new size			= GetArraySize(a_Store);
	if (!b_IsLoadingStore[client] || GetArraySize(a_Store_Player[client]) != size) {

		GetClientAuthString(client, key, sizeof(key));
		LoadStoreData(client, key);
		return true;
	}
	if (b_IsLoadingStore[client]) return true;
	new size2			= 0;
	for (new i = 0; i < size; i++) {

		BoosterKeys[client]		= GetArrayCell(a_Store, i, 0);
		BoosterValues[client]	= GetArrayCell(a_Store, i, 1);
		size2					= GetArraySize(BoosterKeys[client]);

		for (new ii = 0; ii < size2; ii++) {

			GetArrayString(BoosterKeys[client], ii, key, sizeof(key));
			GetArrayString(BoosterValues[client], ii, val, sizeof(val));

			if (StrEqual(key, "duration?") && StringToInt(val) > 0) {

				GetArrayString(a_Store_Player[client], i, pva, sizeof(pva));
				if (StringToInt(pva) > 0) return true;
			}
		}
	}
	return false;
}