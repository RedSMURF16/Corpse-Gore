/*
*
*	Corpse Gore by RedSMURF
*
*
*	Description:
*
*	Cvars:
*       corpsegore_enable           - Enable or disable the plugin.
*       corpsegore_gib_knife        - Gib corpses killed with a knife.
*       corpsegore_gib_explosive    - Gib corpses killed by explosives.
*       corpsegore_break_velocity   - Velocity applied to flying gibs.
*       corpsegore_break_count      - Number of gibs spawned.
*       corpsegore_break_life       - Gib lifetime in seconds.
*       corpsegore_blood_color      - Blood color (195 - Yellow, 247 - Red).
*       corpsegore_blood_scale      - Blood effect scale.
*
*	Commands:
*       None
*
*	Changelog:
*       v1.0: Initial release.
*
*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN_VERSION              "1.1"
#define CORPSEGORE_KEY              981222
#define CORPSEGORE_PENDING          pev_iuser1
#define CORPSE_BREAK_FLESH          0x04
#define CORPSE_DMG_EXPLOSIVE        ((1 << 6) | (1 << 24))

#define CORPSE_BONES                36
#define CORPSE_PAD                  8.0
#define CORPSE_HEIGHT               1.0

new g_cvarEnable, g_cvarGibKnife, g_cvarGibExplosive, g_cvarBreakVelocity, g_cvarBreakCount, g_cvarBreakLife,
    g_cvarBloodColor, g_cvarBloodScale,
    bool:g_bEnable, bool:g_bGibKnife, bool:g_bGibExplosive, g_iBreakVelocity, g_iBreakCount, g_iBreakLife,
    g_iBloodColor, g_iBloodScale, g_iForwardCanGib

new g_iSprite, g_iSpriteSpray, g_iModelGibs, g_iMaxPlayers
new g_iDecal[2] = {204, 205}
new Float:g_fKnifeHit[33]
new g_szSoundKnife[] = "common/bodysplat.wav"
new g_szCN[] = "corpse_gore"

public plugin_init()
{
    register_plugin("Corpse Gore", PLUGIN_VERSION, "RedSMURF")
    register_cvar("RedSMURF_CorpseGore", PLUGIN_VERSION, FCVAR_SERVER | FCVAR_SPONLY)

    g_cvarEnable        = register_cvar("corpsegore_enable", "1")
    g_cvarGibKnife      = register_cvar("corpsegore_gib_knife", "1")
    g_cvarGibExplosive  = register_cvar("corpsegore_gib_explosive", "1")
    g_cvarBreakVelocity = register_cvar("corpsegore_break_velocity", "12")
    g_cvarBreakCount    = register_cvar("corpsegore_break_count", "12")
    g_cvarBreakLife     = register_cvar("corpsegore_break_life", "50")
    g_cvarBloodColor    = register_cvar("corpsegore_blood_color", "247")        // 195 - Yellow, 247 - Red
    g_cvarBloodScale    = register_cvar("corpsegore_blood_scale", "10")

    cvarCache()
    hook_cvar_change(g_cvarEnable,          "cvarUpdate")
    hook_cvar_change(g_cvarGibKnife,        "cvarUpdate")
    hook_cvar_change(g_cvarGibExplosive,    "cvarUpdate")
    hook_cvar_change(g_cvarBreakVelocity,   "cvarUpdate")
    hook_cvar_change(g_cvarBreakCount,      "cvarUpdate")
    hook_cvar_change(g_cvarBreakLife,       "cvarUpdate")
    hook_cvar_change(g_cvarBloodColor,      "cvarUpdate")
    hook_cvar_change(g_cvarBloodScale,      "cvarUpdate")

    register_message(get_user_msgid("ClCorpse"), "msgClCorpse")
    register_forward(FM_EmitSound, "fwdEmitSound")
    RegisterHam(Ham_TraceAttack, "info_target", "fwdTraceAttack")
    RegisterHam(Ham_TakeDamage, "info_target", "fwdTakeDamage")
    register_logevent("eventRoundStart", 2, "1=Round_Start")
    g_iForwardCanGib = CreateMultiForward("CorpseGore_CanGib", ET_STOP, FP_CELL)
    g_iMaxPlayers = get_maxplayers()
}

public plugin_precache()
{
    g_iSprite = engfunc(EngFunc_PrecacheModel, "sprites/blood.spr")
    g_iSpriteSpray = engfunc(EngFunc_PrecacheModel, "sprites/bloodspray.spr")
    g_iModelGibs = engfunc(EngFunc_PrecacheModel, "models/hgibs.mdl")
    precache_sound(g_szSoundKnife)
}

public cvarUpdate(pCvar, const OldValue[], const NewValue[])
{
    cvarCache()
}

public cvarCache()
{
    g_bEnable        = get_pcvar_num(g_cvarEnable) == 1
    g_bGibKnife      = get_pcvar_num(g_cvarGibKnife) == 1
    g_bGibExplosive  = get_pcvar_num(g_cvarGibExplosive) == 1
    g_iBreakVelocity = clamp(get_pcvar_num(g_cvarBreakVelocity), 0, 255)
    g_iBreakCount    = clamp(get_pcvar_num(g_cvarBreakCount), 0, 255)
    g_iBreakLife     = clamp(get_pcvar_num(g_cvarBreakLife), 0, 255)
    g_iBloodColor    = clamp(get_pcvar_num(g_cvarBloodColor), 0, 255)
    g_iBloodScale    = clamp(get_pcvar_num(g_cvarBloodScale), 0, 255)
}

public eventRoundStart()
{
    new iEnt = -1
    while ( (iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", g_szCN)) )
    {
        remove_task(iEnt)
        corpseGoreKill(iEnt)
    }
}

public msgClCorpse()
{
    if ( !g_bEnable )
        return PLUGIN_CONTINUE

    new szModel[32]
    get_msg_arg_string(1, szModel, charsmax(szModel))

    new Float:fOrigin[3], Float:fAngles[3]
    for ( new i; i < 3; i ++ )
    {
        fOrigin[i] = float(get_msg_arg_int(2 + i)) / 128.0
        fAngles[i] = get_msg_arg_float(5 + i)
    }

    corpseCreate(szModel, fOrigin, fAngles, get_msg_arg_int(9), get_msg_arg_int(10))
    return PLUGIN_HANDLED
}

public fwdEmitSound(id, iChannel, const szSample[], Float:fVol, Float:fAttn, iFlags, iPitch)
{
    if ( !g_bEnable
    || !(1 <= id <= g_iMaxPlayers)
    || get_gametime() - g_fKnifeHit[id] > 0.1
    || !equal(szSample, "weapons/knife_hitwall1.wav") )
        return FMRES_IGNORED

    engfunc(EngFunc_EmitSound, id, iChannel, g_szSoundKnife, fVol, fAttn, iFlags, iPitch)
    return FMRES_SUPERCEDE
}

public fwdTraceAttack(iEnt, iAttacker, Float:fDamage, Float:fDir[3], iTr, iBits)
{
    if ( !g_bEnable || !isCorpseGore(iEnt) || pev(iEnt, CORPSEGORE_PENDING) )
        return HAM_IGNORED

    if ( g_bGibKnife &&
    is_user_alive(iAttacker) &&
    get_user_weapon(iAttacker) == CSW_KNIFE )
    {
        g_fKnifeHit[iAttacker] = get_gametime()
        corpseGoreGib(iEnt)
    }
    else
    {
        new Float:fEnd[3]
        get_tr2(iTr, TR_vecEndPos, fEnd)
        corpseGoreBlood(fEnd)
    }

    return HAM_SUPERCEDE
}

public fwdTakeDamage(iEnt, iInflictor, iAttacker, Float:fDamage, iBits)
{
    if ( !g_bEnable || !isCorpseGore(iEnt) || !(iBits & CORPSE_DMG_EXPLOSIVE) )
        return HAM_IGNORED

    if ( g_bGibExplosive )
        corpseGoreGib(iEnt)

    return HAM_SUPERCEDE
}

public corpseGoreTask(iEnt)
{
    if ( !isCorpseGore(iEnt) || !pev(iEnt, CORPSEGORE_PENDING) )
    {
        remove_task(iEnt)
        return
    }

    if ( !corpseBlocked(iEnt) )
        corpseActivate(iEnt)
}

stock corpseCreate(const szModel[], const Float:fOrigin[3], const Float:fAngles[3], iSequence, iBody)
{
    new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
    if ( !pev_valid(iEnt) )
        return 0

    new szPath[96]
    formatex(szPath, charsmax(szPath), "models/player/%s/%s.mdl", szModel, szModel)

    set_pev(iEnt, pev_classname, g_szCN)
    set_pev(iEnt, pev_impulse, CORPSEGORE_KEY)
    set_pev(iEnt, CORPSEGORE_PENDING, 1)
    dllfunc(DLLFunc_Spawn, iEnt)
    engfunc(EngFunc_SetOrigin, iEnt, fOrigin)
    set_pev(iEnt, pev_angles, fAngles)
    set_pev(iEnt, pev_solid, SOLID_NOT)
    set_pev(iEnt, pev_movetype, MOVETYPE_NONE)
    engfunc(EngFunc_SetModel, iEnt, szPath)

    set_pev(iEnt, pev_body, iBody)
    set_pev(iEnt, pev_sequence, iSequence)
    set_pev(iEnt, pev_frame, 255.0)
    set_pev(iEnt, pev_framerate, 0.0)
    set_pev(iEnt, pev_animtime, get_gametime())

    corpseFitBox(iEnt)
    if ( corpseBlocked(iEnt) )
        set_task(0.1, "corpseGoreTask", iEnt, .flags = "b")
    else
        corpseActivate(iEnt)

    return iEnt
}

stock corpseActivate(iEnt)
{
    new Float:fOrigin[3]
    pev(iEnt, pev_origin, fOrigin)

    set_pev(iEnt, CORPSEGORE_PENDING, 0)
    set_pev(iEnt, pev_solid, SOLID_BBOX)
    set_pev(iEnt, pev_takedamage, DAMAGE_YES)
    engfunc(EngFunc_SetOrigin, iEnt, fOrigin)
    remove_task(iEnt)
}

stock bool:corpseBlocked(iEnt)
{
    new Float:fMin[3], Float:fMax[3], Float:fPlayerMin[3], Float:fPlayerMax[3]
    pev(iEnt, pev_absmin, fMin)
    pev(iEnt, pev_absmax, fMax)

    for ( new id = 1, bool:bOverlap; id <= g_iMaxPlayers; id ++ )
    {
        if ( !is_user_alive(id) )
            continue

        pev(id, pev_absmin, fPlayerMin)
        pev(id, pev_absmax, fPlayerMax)
        bOverlap = true
        for ( new i; i < 3; i ++ )
        {
            if ( fPlayerMin[i] >= fMax[i] || fPlayerMax[i] <= fMin[i] )
            {
                bOverlap = false
                break
            }
        }

        if ( bOverlap )
            return true
    }

    return false
}

stock corpseFitBox(iEnt)
{
    new Float:fOrigin[3], Float:fEnd[3], Float:fBone[3], Float:fAng[3]
    pev(iEnt, pev_origin, fOrigin)

    fEnd = fOrigin
    fEnd[2] -= 64.0
    engfunc(EngFunc_TraceLine, fOrigin, fEnd, IGNORE_MONSTERS, iEnt, 0)
    get_tr2(0, TR_vecEndPos, fEnd)

    new Float:fFloor = fEnd[2] - fOrigin[2]
    new Float:fMins[3], Float:fMaxs[3], bool:bFound
    for ( new i = 0; i < 2; i ++ )
    {
        fMins[i] = 9999.0
        fMaxs[i] = -9999.0
    }

    for ( new b; b < CORPSE_BONES; b ++ )
    {
        engfunc(EngFunc_GetBonePosition, iEnt, b, fBone, fAng)
        if ( get_distance_f(fBone, fOrigin) > 100.0 )
            continue

        for ( new i; i < 2; i ++ )
        {
            fMins[i] = floatmin(fMins[i], fBone[i] - fOrigin[i])
            fMaxs[i] = floatmax(fMaxs[i], fBone[i] - fOrigin[i])
        }

        bFound = true
    }

    for ( new i; i < 2; i ++ )
    {
        if ( bFound )
        {
            fMins[i] -= CORPSE_PAD
            fMaxs[i] += CORPSE_PAD
        }
        else
        {
            fMins[i] = -36.0
            fMaxs[i] = 36.0
        }
    }

    fMins[2] = fFloor
    fMaxs[2] = fFloor + CORPSE_HEIGHT
    engfunc(EngFunc_SetSize, iEnt, fMins, fMaxs)
    engfunc(EngFunc_SetOrigin, iEnt, fOrigin)
}

stock corpseGoreGib(iEnt)
{
    new Float:fMin[3], Float:fMax[3], Float:fPos[3], Float:fSize[3], iReturn
    pev(iEnt, pev_absmin, fMin)
    pev(iEnt, pev_absmax, fMax)

    fPos[0] = (fMin[0] + fMax[0]) * 0.5
    fPos[1] = (fMin[1] + fMax[1]) * 0.5
    fPos[2] = fMin[2] + 8.0
    fSize[0] = (fMax[0] - fMin[0]) * 0.25
    fSize[1] = (fMax[1] - fMin[1]) * 0.25
    fSize[2] = 8.0
    corpseGoreBlood(fPos)

    ExecuteForward(g_iForwardCanGib, iReturn, iEnt)
    if ( iReturn == PLUGIN_CONTINUE )
    {
        message_begin_f(MSG_PVS, SVC_TEMPENTITY, fPos)
        write_byte(TE_BREAKMODEL)
        write_coord_f(fPos[0])
        write_coord_f(fPos[1])
        write_coord_f(fPos[2])
        write_coord_f(fSize[0])
        write_coord_f(fSize[1])
        write_coord_f(fSize[2])
        write_coord_f(0.0)
        write_coord_f(0.0)
        write_coord_f(0.0)
        write_byte(random_num(g_iBreakVelocity - 2, g_iBreakVelocity + 2))
        write_short(g_iModelGibs)
        write_byte(random_num(g_iBreakCount - 3, g_iBreakCount + 3))
        write_byte(random_num(g_iBreakLife - 15, g_iBreakLife + 15))
        write_byte(CORPSE_BREAK_FLESH)
        message_end()

        corpseGoreDecals(fPos)
        corpseGoreKill(iEnt)
    }
}

stock corpseGoreDecals(const Float:fCenter[3])
{
    new Float:fStart[3], Float:fEnd[3], Float:fFraction

    fStart = fCenter
    fEnd = fStart
    fEnd[2] -= 24.0
    engfunc(EngFunc_TraceLine, fStart, fEnd, IGNORE_MONSTERS, 0, 0)
    get_tr2(0, TR_flFraction, fFraction)
    if ( fFraction >= 1.0 )
        return

    get_tr2(0, TR_vecEndPos, fEnd)

    message_begin_f(MSG_BROADCAST, SVC_TEMPENTITY, fEnd)
    write_byte(TE_WORLDDECAL)
    write_coord_f(fEnd[0])
    write_coord_f(fEnd[1])
    write_coord_f(fEnd[2])
    write_byte(g_iDecal[random_num(0, sizeof(g_iDecal) - 1)])
    message_end()
}

stock corpseGoreBlood(const Float:fPos[3])
{
    message_begin_f(MSG_PVS, SVC_TEMPENTITY, fPos)
    write_byte(TE_BLOODSPRITE)
    write_coord_f(fPos[0])
    write_coord_f(fPos[1])
    write_coord_f(fPos[2])
    write_short(g_iSpriteSpray)
    write_short(g_iSprite)
    write_byte(g_iBloodColor)
    write_byte(random_num(g_iBloodScale - 3, g_iBloodScale + 3))
    message_end()
}

stock isCorpseGore(iEnt)
{
    return pev_valid(iEnt) && pev(iEnt, pev_impulse) == CORPSEGORE_KEY
}

stock corpseGoreKill(iEnt)
{
    if ( pev_valid(iEnt) )
        engfunc(EngFunc_RemoveEntity, iEnt)
}