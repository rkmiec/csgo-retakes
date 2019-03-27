#include <sourcemod>
#include <cstrike>
#include <clientprefs>
#include "include/retakes.inc"
#include "retakes/generic.sp"

#pragma semicolon 1
#pragma newdecls required

#define MENU_TIME_LENGTH 15

char g_CTRifleChoice[MAXPLAYERS+1][WEAPON_STRING_LENGTH];
char g_TRifleChoice[MAXPLAYERS+1][WEAPON_STRING_LENGTH];
bool g_AwpChoice[MAXPLAYERS+1];
Handle g_hCTRifleChoiceCookie = INVALID_HANDLE;
Handle g_hTRifleChoiceCookie = INVALID_HANDLE;
Handle g_hAwpChoiceCookie = INVALID_HANDLE;

public Plugin myinfo = {
    name = "CS:GO Retakes: standard weapon allocator",
    author = "splewis",
    description = "Defines a simple weapon allocation policy and lets players set weapon preferences",
    version = PLUGIN_VERSION,
    url = "https://github.com/splewis/csgo-retakes"
};

public void OnPluginStart() {
    g_hCTRifleChoiceCookie = RegClientCookie("retakes_ctriflechoice", "", CookieAccess_Private);
    g_hTRifleChoiceCookie = RegClientCookie("retakes_triflechoice", "", CookieAccess_Private);
    g_hAwpChoiceCookie = RegClientCookie("retakes_awpchoice", "", CookieAccess_Private);
}

public void OnClientConnected(int client) {
    g_CTRifleChoice[client] = "m4a1";
    g_TRifleChoice[client] = "ak47";
    g_AwpChoice[client] = false;
}

public void Retakes_OnGunsCommand(int client) {
    GiveWeaponsMenu(client);
}

public void Retakes_OnWeaponsAllocated(ArrayList tPlayers, ArrayList ctPlayers, Bombsite bombsite) {
    WeaponAllocator(tPlayers, ctPlayers, bombsite);
}

/**
 * Updates client weapon settings according to their cookies.
 */
public void OnClientCookiesCached(int client) {
    if (IsFakeClient(client))
        return;
    char ctrifle[WEAPON_STRING_LENGTH];
    char trifle[WEAPON_STRING_LENGTH];
    GetClientCookie(client, g_hCTRifleChoiceCookie, ctrifle, sizeof(ctrifle));
    GetClientCookie(client, g_hTRifleChoiceCookie, trifle, sizeof(trifle));
    g_CTRifleChoice[client] = ctrifle;
    g_TRifleChoice[client] = trifle;
    g_AwpChoice[client] = GetCookieBool(client, g_hAwpChoiceCookie);
}
static void SetNadesT(char nades[NADE_STRING_LENGTH]) {
    int rand = GetRandomInt(0, 3);
    switch(rand) {
        case 0: nades = "m";
        case 1: nades = "s";
        case 2: nades = "f";
        case 3: nades = "h";
    }
}
static void SetNadesCT(char nades[NADE_STRING_LENGTH]) {
    int rand = GetRandomInt(0, 6);
    switch(rand) {
        case 0: nades = "i";
        case 1: nades = "sf";
        case 2: nades = "fs";
        case 3: nades = "hs";
        case 4: nades = "hf";
        case 5: nades = "ff";
        case 6: nades = "sf";
    }
}

public void WeaponAllocator(ArrayList tPlayers, ArrayList ctPlayers, Bombsite bombsite) {
    int tCount = GetArraySize(tPlayers);
    int ctCount = GetArraySize(ctPlayers);

    char primary[WEAPON_STRING_LENGTH];
    char secondary[WEAPON_STRING_LENGTH];
    char nades[NADE_STRING_LENGTH];
    int health = 100;
    int kevlar = 100;
    bool helmet = true;
    bool kit = true;

    bool giveTAwp = true;
    bool giveCTAwp = true;

    for (int i = 0; i < tCount; i++) {
        int client = GetArrayCell(tPlayers, i);

        kevlar = 0;
        helmet = false;

        if (giveTAwp && g_AwpChoice[client]) {
            primary = "weapon_awp";
            giveTAwp = false;
        } else if(StrEqual(g_TRifleChoice[client], "sg556", true)) {
            primary = "weapon_sg556";
            kevlar = 100;
        } else if(StrEqual(g_TRifleChoice[client], "galil", true)) {
            primary = "weapon_galilar";
            kevlar = 100;
            helmet = true;
        } else {
            primary = "weapon_ak47";
            kevlar = 100;
        }
        secondary = "weapon_p250";
        health = 100;
        kit = false;
        SetNadesT(nades);
        Retakes_SetPlayerInfo(client, primary, secondary, nades, health, kevlar, helmet, kit);
    }

    for (int i = 0; i < ctCount; i++) {
        int client = GetArrayCell(ctPlayers, i);

        kevlar = 0;
        helmet = false;

        if (giveCTAwp && g_AwpChoice[client]) {
            primary = "weapon_awp";
            giveCTAwp = false;
        } else if (StrEqual(g_CTRifleChoice[client], "m4a1_silencer", true)) {
            primary = "weapon_m4a1_silencer";
            kevlar = 100;
        } else if (StrEqual(g_CTRifleChoice[client], "m4a1", true)) {
            primary = "weapon_m4a1";
            kevlar = 100;
        } else if (StrEqual(g_CTRifleChoice[client], "famas", true)) {
            primary = "weapon_famas";
            kevlar = 100;
            helmet = true;
        } else {
            primary = "weapon_aug";
            kevlar = 100;
        }
        secondary = "weapon_p250";
        kit = true;
        health = 100;
        SetNadesCT(nades);
        Retakes_SetPlayerInfo(client, primary, secondary, nades, health, kevlar, helmet, kit);
    }
}

public void GiveWeaponsMenu(int client) {
    Handle menu = CreateMenu(MenuHandler_CTRifle);
    SetMenuTitle(menu, "Select a CT rifle:");
    AddMenuItem(menu, "m4a1", "M4A4");
    AddMenuItem(menu, "m4a1_silencer", "M4A1-S");
    AddMenuItem(menu, "famas", "FAMAS");
    AddMenuItem(menu, "aug", "AUG");
    DisplayMenu(menu, client, MENU_TIME_LENGTH);
}

public int MenuHandler_CTRifle(Handle menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_Select) {
        int client = param1;
        char choice[WEAPON_STRING_LENGTH];
        GetMenuItem(menu, param2, choice, sizeof(choice));
        g_CTRifleChoice[client] = choice;
        SetClientCookie(client, g_hCTRifleChoiceCookie, choice);
        TRifleMenu(client);
    } else if (action == MenuAction_End) {
        CloseHandle(menu);
    }
}

public void TRifleMenu(int client) {
    Handle menu = CreateMenu(MenuHandler_TRifle);
    SetMenuTitle(menu, "Select a T rifle:");
    AddMenuItem(menu, "ak47", "AK-47");
    AddMenuItem(menu, "sg556", "SG-556");
    AddMenuItem(menu, "galilar", "Galil");
    DisplayMenu(menu, client, MENU_TIME_LENGTH);
}

public int MenuHandler_TRifle(Handle menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_Select) {
        int client = param1;
        char choice[WEAPON_STRING_LENGTH];
        GetMenuItem(menu, param2, choice, sizeof(choice));
        g_TRifleChoice[client] = choice;
        SetClientCookie(client, g_hTRifleChoiceCookie, choice);
        GiveAwpMenu(client);
    } else if (action == MenuAction_End) {
        CloseHandle(menu);
    }
}

public void GiveAwpMenu(int client) {
    Handle menu = CreateMenu(MenuHandler_AWP);
    SetMenuTitle(menu, "Allow yourself to receive AWPs?");
    AddMenuBool(menu, true, "Yes");
    AddMenuBool(menu, false, "No");
    DisplayMenu(menu, client, MENU_TIME_LENGTH);
}

public int MenuHandler_AWP(Handle menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_Select) {
        int client = param1;
        bool allowAwps = GetMenuBool(menu, param2);
        g_AwpChoice[client] = allowAwps;
        SetCookieBool(client, g_hAwpChoiceCookie, allowAwps);
    } else if (action == MenuAction_End) {
        CloseHandle(menu);
    }
}
