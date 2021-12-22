#include <sourcemod>
#include <sdktools_functions>
#include <sdkhooks>
#include <cstrike>
#include <warden>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "[JB] - CTSaklambaç", 
	author = "ByDexter", 
	description = "", 
	version = "1.0", 
	url = "https://steamcommunity.com/id/ByDexterTR - ByDexter#5494"
};

int Sure = -1;
bool Oyun = false;
bool Buldu[65] = { false, ... };
bool Bulundu[65] = { false, ... };
int Gereken = 0;

#define LoopClientsValid(%1) for (int %1 = 1; %1 <= MaxClients; %1++) if (IsValidClient(%1))

public void OnPluginStart()
{
	RegConsoleCmd("sm_ctsaklan", Command_CTSaklan, "");
	RegConsoleCmd("sm_ctsaklan0", Command_CTSaklan0, "");
	RegAdminCmd("ctsaklambac_flag", Flag_Saklambac, ADMFLAG_ROOT, "");
	LoopClientsValid(i)
	{
		OnClientPostAdminCheck(i);
	}
}

public void OnMapStart()
{
	Sure = -1;
	Oyun = false;
}

public void OnClientPostAdminCheck(int client)
{
	Buldu[client] = false;
	Bulundu[client] = false;
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action Flag_Saklambac(int client, int args)
{
	ReplyToCommand(client, "[SM] Bu komuta erişiminiz var.");
	return Plugin_Handled;
}

public Action Command_CTSaklan(int client, int args)
{
	if (warden_iswarden(client) || CheckCommandAccess(client, "ctsaklambac_flag", ADMFLAG_ROOT))
	{
		if (args != 1)
		{
			ReplyToCommand(client, "[SM] Kullanım: sm_ctsaklan <Saniye>");
			return Plugin_Handled;
		}
		
		if (Oyun)
		{
			ReplyToCommand(client, "[SM] Oyun zaten oynanıyor, durdurmak için: \x04!ctsaklan0");
			return Plugin_Handled;
		}
		
		char amount[20];
		GetCmdArg(1, amount, 20);
		Sure = StringToInt(amount);
		if (Sure < 1)
			Sure = 1;
		
		if (Sure > 120)
			Sure = 120;
		
		PrintToChatAll("[SM] \x10%N \x01CT Saklambaçı başlattı.", client);
		char format[128];
		Format(format, 128, "! <font color='#FFA500'>%d saniye sonra CT Saklambaçı başlayacak</font> !", Sure);
		Gereken = 0;
		LoopClientsValid(i)
		{
			if (GetClientTeam(i) == 2)
			{
				CS_RespawnPlayer(i);
				DarkenScreen(i, true);
				SetEntityMoveType(i, MOVETYPE_NONE);
				Buldu[i] = false;
			}
			else if (GetClientTeam(i) == 3)
			{
				CS_RespawnPlayer(i);
				DarkenScreen(i, false);
				SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
				Bulundu[i] = false;
				Gereken++;
			}
			ShowStatusMessage(i, format, 2);
		}
		CreateTimer(1.0, Suresay, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		Oyun = true;
		return Plugin_Handled;
	}
	else
	{
		ReplyToCommand(client, "[SM] Bu komuta erişiminiz yok.");
		return Plugin_Handled;
	}
}

public Action Command_CTSaklan0(int client, int args)
{
	if (warden_iswarden(client) || CheckCommandAccess(client, "ctsaklambac_flag", ADMFLAG_ROOT))
	{
		if (!Oyun)
		{
			ReplyToCommand(client, "[SM] Oyun zaten aktif değil");
			return Plugin_Handled;
		}
		
		LoopClientsValid(i)
		{
			DarkenScreen(i, false);
			SetEntityMoveType(i, MOVETYPE_WALK);
			if (GetClientTeam(i) == 2)
			{
				Buldu[i] = false;
			}
			else if (GetClientTeam(i) == 3)
			{
				SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
				Bulundu[i] = false;
			}
		}
		PrintToChatAll("[SM] \x10%N \x01CT Saklambaç oynu durduruldu.", client);
		Oyun = false;
		return Plugin_Handled;
	}
	else
	{
		ReplyToCommand(client, "[SM] Bu komuta erişiminiz yok.");
		return Plugin_Handled;
	}
}

public Action Suresay(Handle timer, any data)
{
	if (!Oyun || Sure == -1)
		return Plugin_Stop;
	
	Sure--;
	if (Sure <= 0)
	{
		Sure = -1;
		LoopClientsValid(i)
		{
			DarkenScreen(i, false);
			if (GetClientTeam(i) == 2)
			{
				SetEntityMoveType(i, MOVETYPE_WALK);
			}
			else if (GetClientTeam(i) == 3)
			{
				SetEntityMoveType(i, MOVETYPE_NONE);
				SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
			}
			ShowStatusMessage(i, "! <font color='#FFA500'>CT'ye hasar verenler kazanır</font> !", 2);
		}
		return Plugin_Stop;
	}
	
	char format[128];
	Format(format, 128, "! <font color='#FFA500'>%d saniye sonra CT Saklambaçı başlayacak</font> !", Sure);
	LoopClientsValid(i)
	{
		ShowStatusMessage(i, format, 2);
	}
	return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (Oyun && IsValidClient(victim) && IsValidClient(attacker) && GetClientTeam(victim) == 3 && GetClientTeam(attacker) == 2)
	{
		if (!Bulundu[victim])
		{
			if (!Buldu[attacker])
			{
				Buldu[attacker] = true;
				Bulundu[victim] = true;
				CS_RespawnPlayer(victim);
				SetEntProp(victim, Prop_Data, "m_takedamage", 0, 1);
				SetEntityMoveType(victim, MOVETYPE_WALK);
				PrintToChatAll("[SM] \x10%N\x01, \x10%N \x01faresini saklandığı delikte buldu.", attacker, victim);
				Gereken--;
				if (Gereken <= 0)
				{
					PrintToChat(attacker, "[SM] \x06Tebrikler saklanan CT oyuncusunu buldunuz!");
					PrintToChatAll("[SM] Sonuncu CT oyuncusunda bulundu, \x10bulamayanlar kaybetti :C");
					LoopClientsValid(i)
					{
						if (IsPlayerAlive(i) && GetClientTeam(i) == 2 && !Buldu[i])
						{
							ForcePlayerSuicide(i);
						}
					}
				}
				else
				{
					PrintToChatAll("[SM] Bulunmayan CT Sayısı: \x0F%d", Gereken);
				}
			}
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

bool IsValidClient(int client, bool nobots = false)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
	{
		return false;
	}
	return IsClientInGame(client);
}

void DarkenScreen(int client, bool dark)
{
	Handle hFadeClient = StartMessageOne("Fade", client);
	PbSetInt(hFadeClient, "duration", 1);
	PbSetInt(hFadeClient, "hold_time", 3);
	if (!dark)
	{
		PbSetInt(hFadeClient, "flags", 0x0010);
	}
	else
	{
		PbSetInt(hFadeClient, "flags", 0x0008);
	}
	PbSetColor(hFadeClient, "clr", { 0, 0, 0, 255 } );
	EndMessage();
}

void ShowStatusMessage(int client, const char[] message = NULL_STRING, int hold = 1)
{
	if (!IsFakeClient(client))
	{
		Event show_survival_respawn_status = CreateEvent("show_survival_respawn_status");
		if (show_survival_respawn_status != null)
		{
			show_survival_respawn_status.SetString("loc_token", message);
			show_survival_respawn_status.SetInt("duration", hold);
			show_survival_respawn_status.SetInt("userid", -1);
			show_survival_respawn_status.FireToClient(client);
			show_survival_respawn_status.Cancel();
		}
	}
} 