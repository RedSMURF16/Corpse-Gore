/*
*
*	Dynamite Trap by RedSMURF
*
*
*	Description:
*
*	Cvars:
*		None
*
*	Commands:
*       say /dt                     "Opens the Dynamite Trap menu."
*       say_team /dt                "Opens the Dynamite Trap menu."
*       dt_reload                   "Reloads the configuration file."
*
*	Changelog:
*       v1.0: Initial release.
*
*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <xs>

#if !defined MAX_PLAYERS
    #define MAX_PLAYERS 32
#endif

#if !defined MAX_VALUE_LENGTH
    #define MAX_VALUE_LENGTH 64
#endif

#if !defined MAX_RESOURCE_PATH_LENGTH
    #define MAX_RESOURCE_PATH_LENGTH 128
#endif

#if !defined MAX_FILE_CELL_SIZE
    #define MAX_FILE_CELL_SIZE 192
#endif

#if !defined MAX_PLATFORM_PATH_LENGTH
    #define MAX_PLATFORM_PATH_LENGTH 256
#endif

#define MAX_ENT                     32
#define ADMIN_ACCESS                ADMIN_RCON
#define PDATA_NEXT_ATTACK           83
#define XO_CBASEPLAYER              5
#define XO_CBASEPLAYERWEAPON        4
#define DYNAMITE_KEY                912441
#define DYNAMITE_ARRAY_ITEM         pev_iuser1
#define DYNAMITE_OWNER              pev_iuser1
#define DYNAMITE_SEQ_UP             0
#define DYNAMITE_SEQ_DOWN           1
#define SOUND_NAV                   "buttons/blip1.wav"
#define SOUND_REMOVE                "buttons/button10.wav"
#define SOUND_ALERT                 "buttons/bell1.wav"

new const PLUGIN_VERSION[]          = "1.0"
new const Float:DELAY_ON_CONNECT    = 1.0
new const Float:DELAY_ON_LOAD       = 1.0
new const ERROR_FILE[]              = "DynamiteTrap_ERRORS.log"

enum
{
    SECTION_NONE,
    SECTION_MAIN_SETTINGS,
    SECTION_DYNAMITE
}

enum
{
    DTYPE_INT,
    DTYPE_FLOAT,
    DTYPE_FLAGS,
    DTYPE_ARRAY_STRING,
    DTYPE_ARRAY_SOUND,
    DTYPE_STRING_MODEL,
    DTYPE_STRING_SOUND,
    DTYPE_STRING_MODEL_ID
}

enum
{
    FLAG_SHAKE              = (1 << 0),

    FLAG_SHOW               = (1 << 1),
    FLAG_GHOST              = (1 << 2),
    FLAG_GROUND             = (1 << 3),
    FLAG_ACTIVE             = (1 << 4),
    FLAG_PENDING            = (1 << 5),
    FLAG_TRIGGER            = (1 << 6),
    FLAG_EXPLODE            = (1 << 7),
    FLAG_LOCK               = (1 << 8)
}

enum
{
    ENTITY_TRIGGER,
    ENTITY_DYNAMITE
}

enum
{
    ROTATE_MODE_PITCH,
    ROTATE_MODE_YAW,
    ROTATE_MODE_ROLL
}

enum
{
    TEAM_NONE,
    TEAM_T,
    TEAM_CT,
    TEAM_BOTH
}

enum
{
    SIZE_SMALL,
    SIZE_MEDIUM,
    SIZE_LARGE
}

enum
{
    TARGET_GHOST,
    TARGET_SELECT,
    TARGET_HIDE,
    TARGET_CLEAR
}

enum _:MAIN_SETTINGS
{
    SETTING_DEFAULT_SPRITE_EXPLOSION,
    Array:SETTING_DEFAULT_SOUND_TRIGGER,
    SETTING_DEFAULT_FLAGS,
    SETTING_DEFAULT_TEAM,
    Float:SETTING_DEFAULT_FRAMERATE,
    SETTING_DEFAULT_EXPLOSION_FRAMERATE,
    Float:SETTING_DEFAULT_EXPLOSION_DAMAGE[2],
    Float:SETTING_DEFAULT_EXPLOSION_RADIUS,
    SETTING_DEFAULT_EXPLOSION_DAMAGE_TYPE,
    Float:SETTING_DEFAULT_EXPLOSION_DELAY[2],
    SETTING_DEFAULT_EXPLOSION_FLAGS,
    SETTING_DEFAULT_EXPLOSION_TEAM,
    Float:SETTING_DEFAULT_COOLDOWN[2],
    Float:SETTING_DEFAULT_SHAKE_DISTANCE,
    SETTING_DEFAULT_SHAKE_AMPLITUDE,
    SETTING_DEFAULT_SHAKE_FREQUENCY,
    SETTING_DEFAULT_SHAKE_DURATION,
    bool:SETTING_KILL_WORLD,
    bool:SETTING_MORE_DAMAGE_FOR_CLOSE,

    SETTING_MODEL_TRIGGER[MAX_RESOURCE_PATH_LENGTH],
    SETTING_MODEL_DYNAMITE_SMALL[MAX_RESOURCE_PATH_LENGTH],
    SETTING_MODEL_DYNAMITE_MEDIUM[MAX_RESOURCE_PATH_LENGTH],
    SETTING_MODEL_DYNAMITE_LARGE[MAX_RESOURCE_PATH_LENGTH],
    Float:SETTING_MINS_TRIGGER[3],
    Float:SETTING_MAXS_TRIGGER[3],
    Float:SETTING_MINS_DYNAMITE_SMALL[3],
    Float:SETTING_MAXS_DYNAMITE_SMALL[3],
    Float:SETTING_MINS_DYNAMITE_MEDIUM[3],
    Float:SETTING_MAXS_DYNAMITE_MEDIUM[3],
    Float:SETTING_MINS_DYNAMITE_LARGE[3],
    Float:SETTING_MAXS_DYNAMITE_LARGE[3],

    bool:SETTING_DYNAMITE_LOAD,
    Float:SETTING_DYNAMITE_CHECK,
    Float:SETTING_DYNAMITE_TASK,
    Float:SETTING_OFFSET_BASE,
    Float:SETTING_OFFSET[2],
    Float:SETTING_OFFSET_STEP,
    SETTING_GHOST_ALPHA,
    Float:SETTING_ROTATION_STEP
}

enum _:DYNAMITE
{
    DYNAMITE_ID_TRIGGER,
    Array:DYNAMITE_ID_DYNAMITE,
    DYNAMITE_ID_COUNT,
    DYNAMITE_ITEM,
    DYNAMITE_FLAGS,
    DYNAMITE_TEAM,
    Array:DYNAMITE_SIZE,
    DYNAMITE_ACTIVATOR,
    DYNAMITE_NAME[MAX_VALUE_LENGTH],
    DYNAMITE_MODEL[MAX_RESOURCE_PATH_LENGTH],
    DYNAMITE_LAST_ID,
    DYNAMITE_LAST_SIZE,
    Float:DYNAMITE_LAST_ORIGIN[3],
    Float:DYNAMITE_LAST_ANGLES[3],

    Float:DYNAMITE_ORIGIN_TRIGGER[3],
    Float:DYNAMITE_ANGLES_TRIGGER[3],
    Array:DYNAMITE_ORIGIN_DYNAMITE,
    Array:DYNAMITE_ANGLES_DYNAMITE,
    Float:DYNAMITE_MINS[3],
    Float:DYNAMITE_MAXS[3],
    DYNAMITE_SPRITE_EXPLOSION,

    Float:DYNAMITE_EXPLOSION_DAMAGE[2],
    Float:DYNAMITE_EXPLOSION_RADIUS,
    DYNAMITE_EXPLOSION_DAMAGE_TYPE,
    Float:DYNAMITE_EXPLOSION_DELAY[2],
    DYNAMITE_EXPLOSION_FLAGS,
    DYNAMITE_EXPLOSION_TEAM,
    Float:DYNAMITE_COOLDOWN[2],
    Float:DYNAMITE_SHAKE_DISTANCE,
    DYNAMITE_SHAKE_AMPLITUDE,
    DYNAMITE_SHAKE_FREQUENCY,
    DYNAMITE_SHAKE_DURATION,

    Float:DYNAMITE_NEXT_EXPLOSION,
    Float:DYNAMITE_NEXT_ACTIVE
}

enum _:PLAYER_DATA
{
    PDATA_DYNAMITE_GHOST,
    PDATA_DYNAMITE_MENU,
    bool:PDATA_DYNAMITE_ACTION,
    PDATA_ROTATE_MODE,
    PDATA_ROTATE_SIZE,
    Float:PDATA_OFFSET,
    Float:PDATA_NEXT_OFFSET,

    PDATA_MENU_TYPE,
    bool:PDATA_MENU_TRACE
}

enum
{
    SOUND_MENU_NAV,
    SOUND_MENU_REMOVE,
    SOUND_MENU_ALERT
}

enum
{
    MENU_ROOT,
    MENU_CREATE,
    MENU_EDIT,
    MENU_REMOVE,
    MENU_SHOW,
    MENU_STATUS,
    MENU_ROTATE_TRIGGER,
    MENU_ROTATE_DYNAMITE
}

enum
{
    ROOT_CREATE,
    ROOT_EDIT,
    ROOT_REMOVE,
    ROOT_SAVE,

    ROOT_NOCLIP = 5,
    ROOT_GODMODE
}

enum
{
    EDIT_SHOW,
    EDIT_STATUS
}

enum
{
    REMOVE_NEXT,
    REMOVE_BACK,

    REMOVE_CURRENT = 3,
    REMOVE_ALL
}

enum
{
    SHOW_NEXT,
    SHOW_BACK,

    SHOW_CURRENT = 3,
    SHOW_ALL_SHOW,
    SHOW_ALL_HIDE
}

enum
{
    STATUS_NEXT,
    STATUS_BACK,

    STATUS_CURRENT = 3,
    STATUS_ALL_ENABLE,
    STATUS_ALL_DISABLE
}

enum
{
    ROTATE_TRIGGER_UP,
    ROTATE_TRIGGER_DOWN,

    ROTATE_TRIGGER_GROUND = 3,
    ROTATE_TRIGGER_MODE,
    ROTATE_TRIGGER_PLACE
}

enum
{
    ROTATE_DYNAMITE_UP,
    ROTATE_DYNAMITE_DOWN,

    ROTATE_DYNAMITE_MODE = 3,
    ROTATE_DYNAMITE_SIZE,
    ROTATE_DYNAMITE_ADD,
    ROTATE_DYNAMITE_FINISH
}

new Float:g_fDirections[][] =
{
    {-1.0, 0.0, 0.0},
    {1.0, 0.0, 0.0},
    {0.0, -1.0, 0.0},
    {0.0, 1.0, 0.0},
    {0.0, 0.0, -1.0},
    {0.0, 0.0, 1.0}
}

new g_szMenuHandler[][MAX_VALUE_LENGTH] =
{
    "menuHandlerRoot",
    "menuHandlerCreate",
    "menuHandlerEdit",
    "menuHandlerRemove",
    "menuHandlerShow",
    "menuHandlerStatus",
    "menuHandlerRotateTrigger",
    "menuHandlerRotateDynamite"
}

new g_szCN[] = "dynamiteTrap"

new Array:g_aDynamite,
    Array:g_aDynamiteConfig,
    g_eSettings[MAIN_SETTINGS],
    g_ePlayerData[MAX_PLAYERS + 1][PLAYER_DATA],
    bool:g_bFileWasRead, g_iActivePlayers,
    HamHook:g_iFwdUse, HamHook:g_iFwdObjectCaps, HamHook:g_iFwdPreThink, HamHook:g_iFwdKilled,
    g_iDynamite, g_iDynamiteConfig, g_iScreenShake,
    g_iMaxPlayers

new const g_iColorActive[] = { 0, 255, 0 }
new const g_iColorInactive[] = { 255, 0, 0 }
new g_szRotateMode[][] = {"DYNAMITE_ROTATE_PITCH", "DYNAMITE_ROTATE_YAW", "DYNAMITE_ROTATE_ROLL"}
new g_szRotateSize[][] = {"DYNAMITE_ROTATE_SMALL", "DYNAMITE_ROTATE_MEDIUM", "DYNAMITE_ROTATE_LARGE"}

public plugin_init()
{
    register_plugin("Dynamite Trap", PLUGIN_VERSION, "RedSMURF")
    register_cvar("RedSMURF_DynamiteTrap", PLUGIN_VERSION, ADMIN_ACCESS)

    register_clcmd("say /dt",       "cmdMenu", ADMIN_ACCESS, "-- Opens the Dynamite Trap menu.")
    register_clcmd("say_team /dt",  "cmdMenu", ADMIN_ACCESS, "-- Opens the Dynamite Trap menu.")
    register_concmd("dt_reload",  "cmdReload", ADMIN_ACCESS, "-- Reloads the configuration file")
    register_dictionary("DynamiteTrap.txt")

    g_iFwdUse = RegisterHam(Ham_Use, "info_target", "fwdUse")
    g_iFwdObjectCaps = RegisterHam(Ham_ObjectCaps, "info_target", "fwdObjectCaps")
    g_iFwdPreThink = RegisterHam(Ham_Player_PreThink, "player", "fwdPreThink")
    g_iFwdKilled = RegisterHam(Ham_Killed, "player", "fwdKilled", 1)
    g_iScreenShake = get_user_msgid("ScreenShake")
    register_logevent("eventRoundStart", 2, "1=Round_Start")
    DisableForward()
    DisableDynamite()

    dynamiteInit()
    g_iMaxPlayers = get_maxplayers()
}

public plugin_precache()
{
    g_aDynamite = ArrayCreate(DYNAMITE)
    g_aDynamiteConfig = ArrayCreate(DYNAMITE)
    g_eSettings[SETTING_DEFAULT_SOUND_TRIGGER] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)

    ReadFile()
}

public plugin_end()
{
    new eDynamite[DYNAMITE]
    for ( new i = 0; i < ArraySize(g_aDynamite); i ++ )
    {
        ArrayGetArray(g_aDynamite, i, eDynamite)
        ArrayDestroy(eDynamite[DYNAMITE_SIZE])
        ArrayDestroy(eDynamite[DYNAMITE_ID_DYNAMITE])
        ArrayDestroy(eDynamite[DYNAMITE_ORIGIN_DYNAMITE])
        ArrayDestroy(eDynamite[DYNAMITE_ANGLES_DYNAMITE])
    }

    ArrayDestroy(g_aDynamite)
    ArrayDestroy(g_aDynamiteConfig)
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_SOUND_TRIGGER])
}

public cmdMenu(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    dynamiteSound(id, SOUND_MENU_NAV)
    dynamiteMenu(id, MENU_ROOT)
    return PLUGIN_HANDLED
}

public cmdReload(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    ReadFile()
    console_print(id, "The configuration file has been reloaded successfully !")

    return PLUGIN_HANDLED
}

public eventRoundStart()
{
    dynamiteReset()
}

ReadFile()
{
    if ( g_bFileWasRead )
    {
        for ( new id = 1; id <= g_iMaxPlayers; id ++ )
            if ( is_user_connected(id) )
                UpdateData(id)

        ArrayClear(g_aDynamiteConfig)
        g_iDynamiteConfig = 0
    }

    new szFile[MAX_RESOURCE_PATH_LENGTH], iFile
    get_configsdir(szFile, charsmax(szFile))
    add(szFile, charsmax(szFile), "/DynamiteTrap.ini")
    iFile = fopen(szFile, "rt")

    if ( !iFile )
    {
        set_fail_state("An error occured during the opening of the configuration file !")
    }

    new szData[MAX_FILE_CELL_SIZE],
        szKey[MAX_VALUE_LENGTH], szValue[MAX_VALUE_LENGTH],
        eDynamite[DYNAMITE], iSection = SECTION_NONE, iLine, iPos

    while( !feof(iFile) )
    {
        iLine ++
        fgets(iFile, szData, charsmax(szData))
        trim(szData)

        switch( szData[0] )
        {
            case EOS, ';', '#':
            {
                continue
            }
            case '[':
            {
                if ( szData[strlen(szData) - 1] == ']' )
                {
                    replace(szData, charsmax(szData), "[", "")
                    replace(szData, charsmax(szData), "]", "")
                    trim(szData)

                    if ( equali(szData, "Main Settings") )
                    {
                        iSection = SECTION_MAIN_SETTINGS
                    }
                    else
                    {
                        if ( g_iDynamiteConfig )
                            ArrayPushArray(g_aDynamiteConfig, eDynamite)

                        copy(eDynamite[DYNAMITE_NAME], charsmax(eDynamite[DYNAMITE_NAME]), szData)
                        copy(eDynamite[DYNAMITE_SPRITE_EXPLOSION], charsmax(eDynamite[DYNAMITE_SPRITE_EXPLOSION]), g_eSettings[SETTING_DEFAULT_SPRITE_EXPLOSION])
                        eDynamite[DYNAMITE_FLAGS]                   = g_eSettings[SETTING_DEFAULT_FLAGS]
                        eDynamite[DYNAMITE_TEAM]                    = g_eSettings[SETTING_DEFAULT_TEAM]
                        eDynamite[DYNAMITE_EXPLOSION_DAMAGE][0]     = g_eSettings[SETTING_DEFAULT_EXPLOSION_DAMAGE][0]
                        eDynamite[DYNAMITE_EXPLOSION_DAMAGE][1]     = g_eSettings[SETTING_DEFAULT_EXPLOSION_DAMAGE][1]
                        eDynamite[DYNAMITE_EXPLOSION_RADIUS]        = g_eSettings[SETTING_DEFAULT_EXPLOSION_RADIUS]
                        eDynamite[DYNAMITE_EXPLOSION_DAMAGE_TYPE]   = g_eSettings[SETTING_DEFAULT_EXPLOSION_DAMAGE_TYPE]
                        eDynamite[DYNAMITE_EXPLOSION_DELAY][0]      = g_eSettings[SETTING_DEFAULT_EXPLOSION_DELAY][0]
                        eDynamite[DYNAMITE_EXPLOSION_DELAY][1]      = g_eSettings[SETTING_DEFAULT_EXPLOSION_DELAY][1]
                        eDynamite[DYNAMITE_EXPLOSION_FLAGS]         = g_eSettings[SETTING_DEFAULT_EXPLOSION_FLAGS]
                        eDynamite[DYNAMITE_EXPLOSION_TEAM]          = g_eSettings[SETTING_DEFAULT_EXPLOSION_TEAM]
                        eDynamite[DYNAMITE_COOLDOWN][0]             = g_eSettings[SETTING_DEFAULT_COOLDOWN][0]
                        eDynamite[DYNAMITE_COOLDOWN][1]             = g_eSettings[SETTING_DEFAULT_COOLDOWN][1]
                        eDynamite[DYNAMITE_SHAKE_DISTANCE]          = g_eSettings[SETTING_DEFAULT_SHAKE_DISTANCE]
                        eDynamite[DYNAMITE_SHAKE_AMPLITUDE]         = g_eSettings[SETTING_DEFAULT_SHAKE_AMPLITUDE]
                        eDynamite[DYNAMITE_SHAKE_FREQUENCY]         = g_eSettings[SETTING_DEFAULT_SHAKE_FREQUENCY]
                        eDynamite[DYNAMITE_SHAKE_DURATION]          = g_eSettings[SETTING_DEFAULT_SHAKE_DURATION]
                        eDynamite[DYNAMITE_SPRITE_EXPLOSION]        = g_eSettings[SETTING_DEFAULT_SPRITE_EXPLOSION]

                        iSection = SECTION_DYNAMITE
                        g_iDynamiteConfig ++
                    }
                }
                else
                {
                    LogConfigError(iLine, "Unclosed section name: %s", szData)
                    iSection = SECTION_NONE
                }
            }
            default:
            {
                strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
                iPos = contain(szValue, "#")
                if ( iPos != -1 )
                    szValue[iPos] = EOS

                trim(szKey)
                trim(szValue)

                switch( iSection )
                {
                    case SECTION_NONE:
                    {
                        LogConfigError(iLine, "Data is not in any defined section: %s", szData)
                    }
                    case SECTION_MAIN_SETTINGS:
                    {
                        if ( equali(szKey, "SETTING_DEFAULT_SPRITE_EXPLOSION") )
                            parseSetting(DTYPE_STRING_MODEL_ID, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SPRITE_EXPLOSION], charsmax(g_eSettings[SETTING_DEFAULT_SPRITE_EXPLOSION]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SOUND_TRIGGER") )
                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SOUND_TRIGGER], charsmax(g_eSettings[SETTING_DEFAULT_SOUND_TRIGGER]))
                        else if ( equali(szKey, "SETTING_DEFAULT_FLAGS") )
                            parseSetting(DTYPE_FLAGS, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_FLAGS], charsmax(g_eSettings[SETTING_DEFAULT_FLAGS]))
                        else if ( equali(szKey, "SETTING_DEFAULT_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_TEAM], charsmax(g_eSettings[SETTING_DEFAULT_TEAM]))
                        else if ( equali(szKey, "SETTING_DEFAULT_FRAMERATE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_FRAMERATE], charsmax(g_eSettings[SETTING_DEFAULT_FRAMERATE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_EXPLOSION_FRAMERATE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_EXPLOSION_FRAMERATE], charsmax(g_eSettings[SETTING_DEFAULT_EXPLOSION_FRAMERATE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_EXPLOSION_DAMAGE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_EXPLOSION_DAMAGE], charsmax(g_eSettings[SETTING_DEFAULT_EXPLOSION_DAMAGE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_EXPLOSION_RADIUS") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_EXPLOSION_RADIUS], charsmax(g_eSettings[SETTING_DEFAULT_EXPLOSION_RADIUS]))
                        else if ( equali(szKey, "SETTING_DEFAULT_EXPLOSION_DAMAGE_TYPE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_EXPLOSION_DAMAGE_TYPE], charsmax(g_eSettings[SETTING_DEFAULT_EXPLOSION_DAMAGE_TYPE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_EXPLOSION_FLAGS") )
                            parseSetting(DTYPE_FLAGS, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_EXPLOSION_FLAGS], charsmax(g_eSettings[SETTING_DEFAULT_EXPLOSION_FLAGS]))
                        else if ( equali(szKey, "SETTING_DEFAULT_EXPLOSION_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_EXPLOSION_TEAM], charsmax(g_eSettings[SETTING_DEFAULT_EXPLOSION_TEAM]))
                        else if ( equali(szKey, "SETTING_DEFAULT_EXPLOSION_DELAY") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_EXPLOSION_DELAY], charsmax(g_eSettings[SETTING_DEFAULT_EXPLOSION_DELAY]))
                        else if ( equali(szKey, "SETTING_DEFAULT_COOLDOWN") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_COOLDOWN], charsmax(g_eSettings[SETTING_DEFAULT_COOLDOWN]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SHAKE_DISTANCE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SHAKE_DISTANCE], charsmax(g_eSettings[SETTING_DEFAULT_SHAKE_DISTANCE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SHAKE_AMPLITUDE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SHAKE_AMPLITUDE], charsmax(g_eSettings[SETTING_DEFAULT_SHAKE_AMPLITUDE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SHAKE_FREQUENCY") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SHAKE_FREQUENCY], charsmax(g_eSettings[SETTING_DEFAULT_SHAKE_FREQUENCY]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SHAKE_DURATION") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SHAKE_DURATION], charsmax(g_eSettings[SETTING_DEFAULT_SHAKE_DURATION]))
                        else if ( equali(szKey, "SETTING_KILL_WORLD") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_KILL_WORLD], charsmax(g_eSettings[SETTING_KILL_WORLD]))
                        else if ( equali(szKey, "SETTING_MORE_DAMAGE_FOR_CLOSE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_MORE_DAMAGE_FOR_CLOSE], charsmax(g_eSettings[SETTING_MORE_DAMAGE_FOR_CLOSE]))
                        else if ( equali(szKey, "SETTING_MODEL_TRIGGER") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_MODEL_TRIGGER], charsmax(g_eSettings[SETTING_MODEL_TRIGGER]))
                        else if ( equali(szKey, "SETTING_MODEL_DYNAMITE_SMALL") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_MODEL_DYNAMITE_SMALL], charsmax(g_eSettings[SETTING_MODEL_DYNAMITE_SMALL]))
                        else if ( equali(szKey, "SETTING_MODEL_DYNAMITE_MEDIUM") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_MODEL_DYNAMITE_MEDIUM], charsmax(g_eSettings[SETTING_MODEL_DYNAMITE_MEDIUM]))
                        else if ( equali(szKey, "SETTING_MODEL_DYNAMITE_LARGE") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_MODEL_DYNAMITE_LARGE], charsmax(g_eSettings[SETTING_MODEL_DYNAMITE_LARGE]))
                        else if ( equali(szKey, "SETTING_MINS_TRIGGER") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MINS_TRIGGER], charsmax(g_eSettings[SETTING_MINS_TRIGGER]))
                        else if ( equali(szKey, "SETTING_MAXS_TRIGGER") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MAXS_TRIGGER], charsmax(g_eSettings[SETTING_MAXS_TRIGGER]))
                        else if ( equali(szKey, "SETTING_MINS_DYNAMITE_SMALL") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MINS_DYNAMITE_SMALL], charsmax(g_eSettings[SETTING_MINS_DYNAMITE_SMALL]))
                        else if ( equali(szKey, "SETTING_MAXS_DYNAMITE_SMALL") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MAXS_DYNAMITE_SMALL], charsmax(g_eSettings[SETTING_MAXS_DYNAMITE_SMALL]))
                        else if ( equali(szKey, "SETTING_MINS_DYNAMITE_MEDIUM") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MINS_DYNAMITE_MEDIUM], charsmax(g_eSettings[SETTING_MINS_DYNAMITE_MEDIUM]))
                        else if ( equali(szKey, "SETTING_MAXS_DYNAMITE_MEDIUM") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MAXS_DYNAMITE_MEDIUM], charsmax(g_eSettings[SETTING_MAXS_DYNAMITE_MEDIUM]))
                        else if ( equali(szKey, "SETTING_MINS_DYNAMITE_LARGE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MINS_DYNAMITE_LARGE], charsmax(g_eSettings[SETTING_MINS_DYNAMITE_LARGE]))
                        else if ( equali(szKey, "SETTING_MAXS_DYNAMITE_LARGE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MAXS_DYNAMITE_LARGE], charsmax(g_eSettings[SETTING_MAXS_DYNAMITE_LARGE]))
                        else if ( equali(szKey, "SETTING_DYNAMITE_LOAD") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DYNAMITE_LOAD], charsmax(g_eSettings[SETTING_DYNAMITE_LOAD]))
                        else if ( equali(szKey, "SETTING_DYNAMITE_CHECK") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DYNAMITE_CHECK], charsmax(g_eSettings[SETTING_DYNAMITE_CHECK]))
                        else if ( equali(szKey, "SETTING_DYNAMITE_TASK") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DYNAMITE_TASK], charsmax(g_eSettings[SETTING_DYNAMITE_TASK]))
                        else if ( equali(szKey, "SETTING_OFFSET_BASE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_OFFSET_BASE], charsmax(g_eSettings[SETTING_OFFSET_BASE]))
                        else if ( equali(szKey, "SETTING_OFFSET") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_OFFSET], charsmax(g_eSettings[SETTING_OFFSET]))
                        else if ( equali(szKey, "SETTING_OFFSET_STEP") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_OFFSET_STEP], charsmax(g_eSettings[SETTING_OFFSET_STEP]))
                        else if ( equali(szKey, "SETTING_GHOST_ALPHA") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_GHOST_ALPHA], charsmax(g_eSettings[SETTING_GHOST_ALPHA]))
                        else if ( equali(szKey, "SETTING_ROTATION_STEP") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_ROTATION_STEP], charsmax(g_eSettings[SETTING_ROTATION_STEP]))
                    }
                    case SECTION_DYNAMITE:
                    {
                        if ( equali(szKey, "DYNAMITE_MODEL") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), eDynamite[DYNAMITE_MODEL], charsmax(eDynamite[DYNAMITE_MODEL]))
                        else if ( equali(szKey, "DYNAMITE_SPRITE_EXPLOSION") )
                            parseSetting(DTYPE_STRING_MODEL_ID, szValue, charsmax(szValue), eDynamite[DYNAMITE_SPRITE_EXPLOSION], charsmax(eDynamite[DYNAMITE_SPRITE_EXPLOSION]))
                        else if ( equali(szKey, "DYNAMITE_FLAGS") )
                            parseSetting(DTYPE_FLAGS, szValue, charsmax(szValue), eDynamite[DYNAMITE_FLAGS], charsmax(eDynamite[DYNAMITE_FLAGS]))
                        else if ( equali(szKey, "DYNAMITE_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eDynamite[DYNAMITE_TEAM], charsmax(eDynamite[DYNAMITE_TEAM]))
                        else if ( equali(szKey, "DYNAMITE_EXPLOSION_DAMAGE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eDynamite[DYNAMITE_EXPLOSION_DAMAGE], charsmax(eDynamite[DYNAMITE_EXPLOSION_DAMAGE]))
                        else if ( equali(szKey, "DYNAMITE_EXPLOSION_RADIUS") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eDynamite[DYNAMITE_EXPLOSION_RADIUS], charsmax(eDynamite[DYNAMITE_EXPLOSION_RADIUS]))
                        else if ( equali(szKey, "DYNAMITE_EXPLOSION_DAMAGE_TYPE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eDynamite[DYNAMITE_EXPLOSION_DAMAGE_TYPE], charsmax(eDynamite[DYNAMITE_EXPLOSION_DAMAGE_TYPE]))
                        else if ( equali(szKey, "DYNAMITE_EXPLOSION_DELAY") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eDynamite[DYNAMITE_EXPLOSION_DELAY], charsmax(eDynamite[DYNAMITE_EXPLOSION_DELAY]))
                        else if ( equali(szKey, "DYNAMITE_EXPLOSION_FLAGS") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eDynamite[DYNAMITE_EXPLOSION_FLAGS], charsmax(eDynamite[DYNAMITE_EXPLOSION_FLAGS]))
                        else if ( equali(szKey, "DYNAMITE_EXPLOSION_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eDynamite[DYNAMITE_EXPLOSION_TEAM], charsmax(eDynamite[DYNAMITE_EXPLOSION_TEAM]))
                        else if ( equali(szKey, "DYNAMITE_COOLDOWN") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eDynamite[DYNAMITE_COOLDOWN], charsmax(eDynamite[DYNAMITE_COOLDOWN]))
                        else if ( equali(szKey, "DYNAMITE_SHAKE_DISTANCE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eDynamite[DYNAMITE_SHAKE_DISTANCE], charsmax(eDynamite[DYNAMITE_SHAKE_DISTANCE]))
                        else if ( equali(szKey, "DYNAMITE_SHAKE_AMPLITUDE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eDynamite[DYNAMITE_SHAKE_AMPLITUDE], charsmax(eDynamite[DYNAMITE_SHAKE_AMPLITUDE]))
                        else if ( equali(szKey, "DYNAMITE_SHAKE_FREQUENCY") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eDynamite[DYNAMITE_SHAKE_FREQUENCY], charsmax(eDynamite[DYNAMITE_SHAKE_FREQUENCY]))
                        else if ( equali(szKey, "DYNAMITE_SHAKE_DURATION") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eDynamite[DYNAMITE_SHAKE_DURATION], charsmax(eDynamite[DYNAMITE_SHAKE_DURATION]))
                    }
                }
            }
        }
    }

    if ( g_iDynamiteConfig )
        ArrayPushArray(g_aDynamiteConfig, eDynamite)
    else
        set_fail_state("No dynamites were found in the configuration file.")

    g_bFileWasRead = true
    fclose(iFile)
}

public client_authorized(id)
{
    set_task(DELAY_ON_CONNECT, "UpdateData", id)
}

public client_disconnected(id)
{
    new eDynamite[DYNAMITE], iItem
    if ( g_ePlayerData[id][PDATA_DYNAMITE_GHOST]
    && (iItem = dynamiteGet(eDynamite, g_ePlayerData[id][PDATA_DYNAMITE_GHOST])) != -1 )
    {
        dynamiteKill(eDynamite)
        dynamiteRemove(iItem)
    }

    DisableAction(id)
    g_ePlayerData[id][PDATA_DYNAMITE_GHOST]  = 0
    g_ePlayerData[id][PDATA_DYNAMITE_MENU]   = 0
}

public UpdateData(id)
{
    g_ePlayerData[id][PDATA_OFFSET] = g_eSettings[SETTING_OFFSET_BASE]
}

stock dynamiteInit()
{
    if ( g_eSettings[SETTING_DYNAMITE_LOAD] )
        set_task(DELAY_ON_LOAD, "loadData")
}

stock dynamiteTerminate()
{
    new eDynamite[DYNAMITE]
    for ( new i = 0; i < g_iDynamite; i ++ )
    {
        ArrayGetArray(g_aDynamite, i, eDynamite)
        eDynamite[DYNAMITE_FLAGS] &= ~(FLAG_TRIGGER | FLAG_EXPLODE)
        if ( !(eDynamite[DYNAMITE_FLAGS] & FLAG_PENDING) )
        {
            ArraySetArray(g_aDynamite, i, eDynamite)
            continue
        }

        eDynamite[DYNAMITE_FLAGS] |= FLAG_ACTIVE
        eDynamite[DYNAMITE_FLAGS] &= ~FLAG_PENDING
        ArraySetArray(g_aDynamite, i, eDynamite)
    }
}

stock dynamiteMenu(id, iType)
{
    if ( !is_user_connected(id) )
        return PLUGIN_HANDLED

    new szData[256], iMenu
    formatex(szData, charsmax(szData), "%L", id, "DYNAMITE_MENU_TITLE", PLUGIN_VERSION)
    iMenu = menu_create(szData, g_szMenuHandler[iType])
    switch( iType )
    {
        case MENU_ROOT:             { menuRoot(id, iMenu); }
        case MENU_CREATE:           { menuCreate(iMenu);                format(szData, charsmax(szData), "%s^n%L", szData, id, "DYNAMITE_ROOT_CREATE"); }
        case MENU_EDIT:             { menuEdit(id, iMenu);              format(szData, charsmax(szData), "%s^n%L", szData, id, "DYNAMITE_ROOT_EDIT"); }
        case MENU_REMOVE:           { menuRemove(id, iMenu);            format(szData, charsmax(szData), "%s^n%L", szData, id, "DYNAMITE_ROOT_REMOVE"); }
        case MENU_SHOW:             { menuShow(id, iMenu);              format(szData, charsmax(szData), "%s^n%L", szData, id, "DYNAMITE_ROOT_SHOW"); }
        case MENU_STATUS:           { menuStatus(id, iMenu);            format(szData, charsmax(szData), "%s^n%L", szData, id, "DYNAMITE_ROOT_STATUS"); }
        case MENU_ROTATE_TRIGGER:   { menuRotateTrigger(id, iMenu);     format(szData, charsmax(szData), "%s^n%L", szData, id, "DYNAMITE_ROOT_ROTATE"); }
        case MENU_ROTATE_DYNAMITE:  { menuRotateDynamite(id, iMenu);    format(szData, charsmax(szData), "%s^n%L", szData, id, "DYNAMITE_ROOT_ROTATE"); }
    }

    if ( menu_pages(iMenu) > 1 )
        format(szData, charsmax(szData), "%s^n%L", szData, id, "DYNAMITE_MENU_TITLE_PAGE")

    menu_setprop(iMenu, MPROP_TITLE, szData)
    menu_setprop(iMenu, MPROP_EXIT, MEXIT_ALL)
    menu_setprop(iMenu, MPROP_NUMBER_COLOR, "\r")

    menu_display(id, iMenu)
    return PLUGIN_HANDLED
}

stock menuNav(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "DYNAMITE_NAV_NEXT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "DYNAMITE_NAV_BACK")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)
}

public menuRoot(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "DYNAMITE_ROOT_CREATE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "DYNAMITE_ROOT_EDIT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "DYNAMITE_ROOT_REMOVE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "DYNAMITE_ROOT_SAVE")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "DYNAMITE_ROOT_NOCLIP", id, get_user_noclip(id) ? "DYNAMITE_ON" : "DYNAMITE_OFF")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "DYNAMITE_ROOT_GODMODE", id, get_user_godmode(id) ? "DYNAMITE_ON" : "DYNAMITE_OFF")
    menu_additem(iMenu, szItem)
}

public menuHandlerRoot(id, menu, item)
{
    if ( item == MENU_EXIT )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROOT_CREATE:
        {
            if ( g_iDynamite >= MAX_ENT )
            {
                client_print_color(id, id, "%L %L", id, "DYNAMITE_CHAT_TAG", id, "DYNAMITE_CHAT_LIMIT", MAX_ENT)

                dynamiteSound(id, SOUND_MENU_REMOVE)
                dynamiteMenu(id, MENU_ROOT)
            }
            else
            {
                dynamiteSound(id, SOUND_MENU_NAV)
                dynamiteMenu(id, MENU_CREATE)
            }
        }
        case ROOT_EDIT:
        {
            if ( !g_iDynamite )
            {
                client_print_color(id, id, "%L %L", id, "DYNAMITE_CHAT_TAG", id, "DYNAMITE_CHAT_NO_DYNAMITE")

                dynamiteSound(id, SOUND_MENU_REMOVE)
                dynamiteMenu(id, MENU_ROOT)
            }
            else
            {
                dynamiteSound(id, SOUND_MENU_NAV)
                dynamiteMenu(id, MENU_EDIT)
            }
        }
        case ROOT_REMOVE:
        {
            if ( !g_iDynamite )
            {
                client_print_color(id, id, "%L %L", id, "DYNAMITE_CHAT_TAG", id, "DYNAMITE_CHAT_NO_DYNAMITE")

                dynamiteSound(id, SOUND_MENU_REMOVE)
                dynamiteMenu(id, MENU_ROOT)
            }
            else
            {
                dynamiteSound(id, SOUND_MENU_REMOVE)
                dynamiteMenu(id, MENU_REMOVE)
            }
        }
        case ROOT_SAVE:
        {
            saveData(id)
        }
        case ROOT_NOCLIP:
        {
            dynamiteNoClip(id)
        }
        case ROOT_GODMODE:
        {
            dynamiteGodMode(id)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuCreate(iMenu)
{
    new eDynamite[DYNAMITE], szItem[64]
    for ( new i = 0; i < g_iDynamiteConfig; i ++ )
    {
        ArrayGetArray(g_aDynamiteConfig, i, eDynamite)

        copy(szItem, charsmax(szItem), eDynamite[DYNAMITE_NAME])
        menu_additem(iMenu, szItem)
    }
}

public menuHandlerCreate(id, menu, item)
{
    if ( !is_user_alive(id) )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    else if ( item == MENU_EXIT )
    {
        dynamiteSound(id, SOUND_MENU_NAV)
        dynamiteMenu(id, MENU_ROOT)

        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    dynamiteCreate(id, item)
    dynamiteSound(id, SOUND_MENU_NAV)
    dynamiteMenu(id, MENU_ROTATE_TRIGGER)

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuEdit(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "DYNAMITE_EDIT_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "DYNAMITE_EDIT_STATUS")
    menu_additem(iMenu, szItem)
}

public menuHandlerEdit(id, menu, item)
{
    switch( item )
    {
        case EDIT_SHOW:
        {
            dynamiteSound(id, SOUND_MENU_NAV)
            dynamiteMenu(id, MENU_SHOW)
        }
        case EDIT_STATUS:
        {
            dynamiteSound(id, SOUND_MENU_NAV)
            dynamiteMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            dynamiteSound(id, SOUND_MENU_NAV)
            dynamiteMenu(id, MENU_ROOT)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRemove(id, iMenu)
{
    new szItem[64], eDynamite[DYNAMITE]
    menuNav(id, iMenu)
    ArrayGetArray(g_aDynamite, g_ePlayerData[id][PDATA_DYNAMITE_MENU], eDynamite)

    formatex(szItem, charsmax(szItem), "%L", id, "DYNAMITE_REMOVE_CURRENT", eDynamite[DYNAMITE_NAME])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "DYNAMITE_REMOVE_ALL")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    dynamiteSelect(eDynamite, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_REMOVE
    ArraySetArray(g_aDynamite, g_ePlayerData[id][PDATA_DYNAMITE_MENU], eDynamite)
}

public menuHandlerRemove(id, menu, item)
{
    new eDynamite[DYNAMITE]
    ArrayGetArray(g_aDynamite, g_ePlayerData[id][PDATA_DYNAMITE_MENU], eDynamite)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        dynamiteSelect(eDynamite, eDynamite[DYNAMITE_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case REMOVE_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_DYNAMITE_MENU] >= g_iDynamite - 1 )
                g_ePlayerData[id][PDATA_DYNAMITE_MENU] = 0
            else
                g_ePlayerData[id][PDATA_DYNAMITE_MENU] ++

            dynamiteSound(id, SOUND_MENU_NAV)
            dynamiteMenu(id, MENU_REMOVE)
        }
        case REMOVE_BACK:
        {
            if ( g_ePlayerData[id][PDATA_DYNAMITE_MENU] <= 0 )
                g_ePlayerData[id][PDATA_DYNAMITE_MENU] = g_iDynamite - 1
            else
                g_ePlayerData[id][PDATA_DYNAMITE_MENU] --

            dynamiteSound(id, SOUND_MENU_NAV)
            dynamiteMenu(id, MENU_REMOVE)
        }
        case REMOVE_CURRENT:
        {
            eDynamite[DYNAMITE_FLAGS] &= ~FLAG_ACTIVE
            dynamiteSetState(eDynamite)
            dynamiteKill(eDynamite)
            dynamiteRemove(g_ePlayerData[id][PDATA_DYNAMITE_MENU])

            client_print_color(id, id, "%L %L", id, "DYNAMITE_CHAT_TAG", id, "DYNAMITE_CHAT_REMOVE_CURRENT", eDynamite[DYNAMITE_NAME])
            g_ePlayerData[id][PDATA_DYNAMITE_MENU] = 0

            dynamiteSound(id, g_iDynamite > 0 ? SOUND_MENU_REMOVE : SOUND_MENU_NAV)
            dynamiteMenu(id, g_iDynamite > 0 ? MENU_REMOVE : MENU_ROOT)
        }
        case REMOVE_ALL:
        {
            while( g_iDynamite )
            {
                ArrayGetArray(g_aDynamite, 0, eDynamite)
                eDynamite[DYNAMITE_FLAGS] &= ~FLAG_ACTIVE

                dynamiteSetState(eDynamite)
                dynamiteKill(eDynamite)
                dynamiteRemove(0)
            }

            client_print_color(id, id, "%L %L", id, "DYNAMITE_CHAT_TAG", id, "DYNAMITE_CHAT_REMOVE_ALL")
            g_ePlayerData[id][PDATA_DYNAMITE_MENU] = 0

            dynamiteSound(id, SOUND_MENU_ALERT)
            dynamiteMenu(id, MENU_ROOT)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                dynamiteSound(id, SOUND_MENU_NAV)
                dynamiteMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_DYNAMITE_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_DYNAMITE_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuShow(id, iMenu)
{
    new szItem[64], eDynamite[DYNAMITE]
    menuNav(id, iMenu)
    ArrayGetArray(g_aDynamite, g_ePlayerData[id][PDATA_DYNAMITE_MENU], eDynamite)

    formatex(szItem, charsmax(szItem), "%L", id, "DYNAMITE_SHOW_CURRENT",
    eDynamite[DYNAMITE_FLAGS] & FLAG_SHOW ? "\y" : "\r", eDynamite[DYNAMITE_NAME], id, eDynamite[DYNAMITE_FLAGS] & FLAG_SHOW ? "DYNAMITE_SHOWN" : "DYNAMITE_HIDDEN")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "DYNAMITE_SHOW_ALL_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "DYNAMITE_SHOW_ALL_HIDE")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    dynamiteSelect(eDynamite, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_SHOW
    ArraySetArray(g_aDynamite, g_ePlayerData[id][PDATA_DYNAMITE_MENU], eDynamite)
}

public menuHandlerShow(id, menu, item)
{
    new eDynamite[DYNAMITE]
    ArrayGetArray(g_aDynamite, g_ePlayerData[id][PDATA_DYNAMITE_MENU], eDynamite)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        dynamiteSelect(eDynamite, eDynamite[DYNAMITE_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case SHOW_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_DYNAMITE_MENU] >= g_iDynamite - 1 )
                g_ePlayerData[id][PDATA_DYNAMITE_MENU] = 0
            else
                g_ePlayerData[id][PDATA_DYNAMITE_MENU] ++

            dynamiteSound(id, SOUND_MENU_NAV)
            dynamiteMenu(id, MENU_SHOW)
        }
        case SHOW_BACK:
        {
            if ( g_ePlayerData[id][PDATA_DYNAMITE_MENU] <= 0 )
                g_ePlayerData[id][PDATA_DYNAMITE_MENU] = g_iDynamite - 1
            else
                g_ePlayerData[id][PDATA_DYNAMITE_MENU] --

            dynamiteSound(id, SOUND_MENU_NAV)
            dynamiteMenu(id, MENU_SHOW)
        }
        case SHOW_CURRENT:
        {
            eDynamite[DYNAMITE_FLAGS] ^= FLAG_SHOW
            if ( eDynamite[DYNAMITE_FLAGS] & FLAG_SHOW )
                eDynamite[DYNAMITE_FLAGS] |= FLAG_ACTIVE
            else
                eDynamite[DYNAMITE_FLAGS] &= ~FLAG_ACTIVE
            dynamiteSetState(eDynamite)

            client_print_color(id, id, "%L %L", id, "DYNAMITE_CHAT_TAG", id, "DYNAMITE_CHAT_SHOW_CURRENT",
            eDynamite[DYNAMITE_NAME], id, eDynamite[DYNAMITE_FLAGS] & FLAG_SHOW ? "DYNAMITE_CHAT_SHOWN" : "DYNAMITE_CHAT_HIDDEN")
            ArraySetArray(g_aDynamite, g_ePlayerData[id][PDATA_DYNAMITE_MENU], eDynamite)

            dynamiteSound(id, SOUND_MENU_NAV)
            dynamiteMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_SHOW:
        {
            for ( new i = 0; i < g_iDynamite; i ++ )
            {
                ArrayGetArray(g_aDynamite, i, eDynamite)
                eDynamite[DYNAMITE_FLAGS] |= (FLAG_SHOW | FLAG_ACTIVE)
                dynamiteSetState(eDynamite)

                ArraySetArray(g_aDynamite, i, eDynamite)
            }

            client_print_color(id, id, "%L %L", id, "DYNAMITE_CHAT_TAG", id, "DYNAMITE_CHAT_SHOW_ALL_SHOWN")
            dynamiteSound(id, SOUND_MENU_ALERT)
            dynamiteMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_HIDE:
        {
            for ( new i = 0; i < g_iDynamite; i ++ )
            {
                ArrayGetArray(g_aDynamite, i, eDynamite)
                eDynamite[DYNAMITE_FLAGS] &= ~(FLAG_SHOW | FLAG_ACTIVE)
                dynamiteSetState(eDynamite)

                ArraySetArray(g_aDynamite, i, eDynamite)
            }

            client_print_color(id, id, "%L %L", id, "DYNAMITE_CHAT_TAG", id, "DYNAMITE_CHAT_SHOW_ALL_HIDDEN")
            dynamiteSound(id, SOUND_MENU_ALERT)
            dynamiteMenu(id, MENU_SHOW)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                dynamiteSound(id, SOUND_MENU_NAV)
                dynamiteMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_DYNAMITE_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_DYNAMITE_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuStatus(id, iMenu)
{
    new szItem[64], eDynamite[DYNAMITE]
    menuNav(id, iMenu)
    ArrayGetArray(g_aDynamite, g_ePlayerData[id][PDATA_DYNAMITE_MENU], eDynamite)

    formatex(szItem, charsmax(szItem), "%L", id, "DYNAMITE_STATUS_CURRENT",
    eDynamite[DYNAMITE_FLAGS] & FLAG_ACTIVE ? "\y" : "\r", eDynamite[DYNAMITE_NAME], id, eDynamite[DYNAMITE_FLAGS] & FLAG_ACTIVE ? "DYNAMITE_ENABLED" : "DYNAMITE_DISABLED")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "DYNAMITE_STATUS_ALL_ENABLE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "DYNAMITE_STATUS_ALL_DISABLE")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    dynamiteSelect(eDynamite, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_STATUS
    ArraySetArray(g_aDynamite, g_ePlayerData[id][PDATA_DYNAMITE_MENU], eDynamite)
}

public menuHandlerStatus(id, menu, item)
{
    new eDynamite[DYNAMITE]
    ArrayGetArray(g_aDynamite, g_ePlayerData[id][PDATA_DYNAMITE_MENU], eDynamite)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        dynamiteSelect(eDynamite, eDynamite[DYNAMITE_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case STATUS_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_DYNAMITE_MENU] >= g_iDynamite - 1 )
                g_ePlayerData[id][PDATA_DYNAMITE_MENU] = 0
            else
                g_ePlayerData[id][PDATA_DYNAMITE_MENU] ++

            dynamiteSound(id, SOUND_MENU_NAV)
            dynamiteMenu(id, MENU_STATUS)
        }
        case STATUS_BACK:
        {
            if ( g_ePlayerData[id][PDATA_DYNAMITE_MENU] <= 0 )
                g_ePlayerData[id][PDATA_DYNAMITE_MENU] = g_iDynamite - 1
            else
                g_ePlayerData[id][PDATA_DYNAMITE_MENU] --

            dynamiteSound(id, SOUND_MENU_NAV)
            dynamiteMenu(id, MENU_STATUS)
        }
        case STATUS_CURRENT:
        {
            eDynamite[DYNAMITE_FLAGS] ^= FLAG_ACTIVE
            dynamiteSetState(eDynamite)

            client_print_color(id, id, "%L %L", id, "DYNAMITE_CHAT_TAG", id, "DYNAMITE_CHAT_STATUS_CURRENT",
            eDynamite[DYNAMITE_NAME], id, eDynamite[DYNAMITE_FLAGS] & FLAG_ACTIVE ? "DYNAMITE_CHAT_ENABLED" : "DYNAMITE_CHAT_DISABLED")
            ArraySetArray(g_aDynamite, g_ePlayerData[id][PDATA_DYNAMITE_MENU], eDynamite)

            dynamiteSound(id, SOUND_MENU_NAV)
            dynamiteMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_ENABLE:
        {
            for ( new i = 0; i < g_iDynamite; i ++ )
            {
                ArrayGetArray(g_aDynamite, i, eDynamite)
                eDynamite[DYNAMITE_FLAGS] |= FLAG_ACTIVE
                dynamiteSetState(eDynamite)

                ArraySetArray(g_aDynamite, i, eDynamite)
            }

            client_print_color(id, id, "%L %L", id, "DYNAMITE_CHAT_TAG", id, "DYNAMITE_CHAT_STATUS_ALL_ENABLED")
            dynamiteSound(id, SOUND_MENU_ALERT)
            dynamiteMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_DISABLE:
        {
            for ( new i = 0; i < g_iDynamite; i ++ )
            {
                ArrayGetArray(g_aDynamite, i, eDynamite)
                eDynamite[DYNAMITE_FLAGS] &= ~FLAG_ACTIVE
                dynamiteSetState(eDynamite)

                ArraySetArray(g_aDynamite, i, eDynamite)
            }

            client_print_color(id, id, "%L %L", id, "DYNAMITE_CHAT_TAG", id, "DYNAMITE_CHAT_STATUS_ALL_DISABLED")
            dynamiteSound(id, SOUND_MENU_ALERT)
            dynamiteMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                dynamiteSound(id, SOUND_MENU_NAV)
                dynamiteMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_DYNAMITE_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_DYNAMITE_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRotateTrigger(id, iMenu)
{
    new szItem[64], eDynamite[DYNAMITE]
    if ( dynamiteGet(eDynamite, g_ePlayerData[id][PDATA_DYNAMITE_GHOST]) == -1 )
    {
        menu_destroy(iMenu)
        return
    }

    formatex(szItem, charsmax(szItem), "%L", id, "DYNAMITE_ROTATE_UP")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "DYNAMITE_ROTATE_DOWN")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "DYNAMITE_ROTATE_GROUND",
    id, eDynamite[DYNAMITE_FLAGS] & FLAG_GROUND ? "DYNAMITE_ON" : "DYNAMITE_OFF")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "DYNAMITE_ROTATE_MODE", id, g_szRotateMode[g_ePlayerData[id][PDATA_ROTATE_MODE]])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "DYNAMITE_ROTATE_PLACE")
    menu_additem(iMenu, szItem)
}

public menuHandlerRotateTrigger(id, menu, item)
{
    new eDynamite[DYNAMITE], iItem
    if ( (iItem = dynamiteGet(eDynamite, g_ePlayerData[id][PDATA_DYNAMITE_GHOST])) == -1 )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROTATE_TRIGGER_UP:
        {
            pev(eDynamite[DYNAMITE_ID_TRIGGER], pev_angles, eDynamite[DYNAMITE_ANGLES_TRIGGER])
            eDynamite[DYNAMITE_ANGLES_TRIGGER][g_ePlayerData[id][PDATA_ROTATE_MODE]] -= g_eSettings[SETTING_ROTATION_STEP]
            if ( eDynamite[DYNAMITE_ANGLES_TRIGGER][g_ePlayerData[id][PDATA_ROTATE_MODE]] < -180.0 ) eDynamite[DYNAMITE_ANGLES_TRIGGER][g_ePlayerData[id][PDATA_ROTATE_MODE]] += 360.0

            set_pev(eDynamite[DYNAMITE_ID_TRIGGER], pev_angles, eDynamite[DYNAMITE_ANGLES_TRIGGER])
            ArraySetArray(g_aDynamite, iItem, eDynamite)

            dynamiteSound(id, SOUND_MENU_NAV)
            dynamiteMenu(id, MENU_ROTATE_TRIGGER)
        }
        case ROTATE_TRIGGER_DOWN:
        {
            pev(eDynamite[DYNAMITE_ID_TRIGGER], pev_angles, eDynamite[DYNAMITE_ANGLES_TRIGGER])
            eDynamite[DYNAMITE_ANGLES_TRIGGER][g_ePlayerData[id][PDATA_ROTATE_MODE]] += g_eSettings[SETTING_ROTATION_STEP]
            if ( eDynamite[DYNAMITE_ANGLES_TRIGGER][g_ePlayerData[id][PDATA_ROTATE_MODE]] > 180.0 ) eDynamite[DYNAMITE_ANGLES_TRIGGER][g_ePlayerData[id][PDATA_ROTATE_MODE]] -= 360.0

            set_pev(eDynamite[DYNAMITE_ID_TRIGGER], pev_angles, eDynamite[DYNAMITE_ANGLES_TRIGGER])
            ArraySetArray(g_aDynamite, iItem, eDynamite)

            dynamiteSound(id, SOUND_MENU_NAV)
            dynamiteMenu(id, MENU_ROTATE_TRIGGER)
        }
        case ROTATE_TRIGGER_GROUND:
        {
            eDynamite[DYNAMITE_FLAGS] ^= FLAG_GROUND
            ArraySetArray(g_aDynamite, iItem, eDynamite)

            dynamiteSound(id, SOUND_MENU_NAV)
            dynamiteMenu(id, MENU_ROTATE_TRIGGER)
        }
        case ROTATE_TRIGGER_MODE:
        {
            if ( ++ g_ePlayerData[id][PDATA_ROTATE_MODE] > ROTATE_MODE_ROLL )
                g_ePlayerData[id][PDATA_ROTATE_MODE] = ROTATE_MODE_PITCH

            ArraySetArray(g_aDynamite, iItem, eDynamite)
            dynamiteSound(id, SOUND_MENU_NAV)
            dynamiteMenu(id, MENU_ROTATE_TRIGGER)
        }
        case ROTATE_TRIGGER_PLACE:
        {
            dynamiteTrace(eDynamite, id)

            eDynamite[DYNAMITE_FLAGS] |= FLAG_SHOW
            eDynamite[DYNAMITE_FLAGS] &= ~FLAG_GROUND
            eDynamite[DYNAMITE_ANGLES_TRIGGER][0] = -eDynamite[DYNAMITE_ANGLES_TRIGGER][0]
            dynamiteSetSize(eDynamite, ENTITY_TRIGGER)

            ArraySetArray(g_aDynamite, iItem, eDynamite)
            dynamiteSound(id, SOUND_MENU_NAV)
            dynamiteMenu(id, MENU_ROTATE_DYNAMITE)
        }
        case MENU_EXIT:
        {
            dynamiteKill(eDynamite)
            dynamiteRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_DYNAMITE_GHOST] = 0

            dynamiteSound(id, SOUND_MENU_NAV)
            dynamiteMenu(id, MENU_CREATE)
        }
        default:
        {
            dynamiteKill(eDynamite)
            dynamiteRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_DYNAMITE_GHOST] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRotateDynamite(id, iMenu)
{
    new szItem[64], eDynamite[DYNAMITE]
    if ( dynamiteGet(eDynamite, g_ePlayerData[id][PDATA_DYNAMITE_GHOST]) == -1 )
    {
        menu_destroy(iMenu)
        return
    }

    formatex(szItem, charsmax(szItem), "%L", id, "DYNAMITE_ROTATE_UP")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "DYNAMITE_ROTATE_DOWN")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "DYNAMITE_ROTATE_MODE", id, g_szRotateMode[g_ePlayerData[id][PDATA_ROTATE_MODE]])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "DYNAMITE_ROTATE_SIZE", id, g_szRotateSize[g_ePlayerData[id][PDATA_ROTATE_SIZE]])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "DYNAMITE_ROTATE_ADD")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "DYNAMITE_ROTATE_FINISH")
    menu_additem(iMenu, szItem)
}

public menuHandlerRotateDynamite(id, menu, item)
{
    new eDynamite[DYNAMITE], iItem
    if ( (iItem = dynamiteGet(eDynamite, g_ePlayerData[id][PDATA_DYNAMITE_GHOST])) == -1 )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROTATE_DYNAMITE_UP:
        {
            pev(eDynamite[DYNAMITE_LAST_ID], pev_angles, eDynamite[DYNAMITE_LAST_ANGLES])
            eDynamite[DYNAMITE_LAST_ANGLES][g_ePlayerData[id][PDATA_ROTATE_MODE]] -= g_eSettings[SETTING_ROTATION_STEP]
            if ( eDynamite[DYNAMITE_LAST_ANGLES][g_ePlayerData[id][PDATA_ROTATE_MODE]] < -180.0 ) eDynamite[DYNAMITE_LAST_ANGLES][g_ePlayerData[id][PDATA_ROTATE_MODE]] += 360.0

            set_pev(eDynamite[DYNAMITE_LAST_ID], pev_angles, eDynamite[DYNAMITE_LAST_ANGLES])
            ArraySetArray(eDynamite[DYNAMITE_ANGLES_DYNAMITE], eDynamite[DYNAMITE_ID_COUNT] - 1, eDynamite[DYNAMITE_LAST_ANGLES])
            ArraySetArray(g_aDynamite, iItem, eDynamite)

            dynamiteSound(id, SOUND_MENU_NAV)
            dynamiteMenu(id, MENU_ROTATE_DYNAMITE)
        }
        case ROTATE_DYNAMITE_DOWN:
        {
            pev(eDynamite[DYNAMITE_LAST_ID], pev_angles, eDynamite[DYNAMITE_LAST_ANGLES])
            eDynamite[DYNAMITE_LAST_ANGLES][g_ePlayerData[id][PDATA_ROTATE_MODE]] += g_eSettings[SETTING_ROTATION_STEP]
            if ( eDynamite[DYNAMITE_LAST_ANGLES][g_ePlayerData[id][PDATA_ROTATE_MODE]] > 180.0 ) eDynamite[DYNAMITE_LAST_ANGLES][g_ePlayerData[id][PDATA_ROTATE_MODE]] -= 360.0

            set_pev(eDynamite[DYNAMITE_LAST_ID], pev_angles, eDynamite[DYNAMITE_LAST_ANGLES])
            ArraySetArray(eDynamite[DYNAMITE_ANGLES_DYNAMITE], eDynamite[DYNAMITE_ID_COUNT] - 1, eDynamite[DYNAMITE_LAST_ANGLES])
            ArraySetArray(g_aDynamite, iItem, eDynamite)

            dynamiteSound(id, SOUND_MENU_NAV)
            dynamiteMenu(id, MENU_ROTATE_DYNAMITE)
        }
        case ROTATE_DYNAMITE_MODE:
        {
            if ( ++ g_ePlayerData[id][PDATA_ROTATE_MODE] > ROTATE_MODE_ROLL )
                g_ePlayerData[id][PDATA_ROTATE_MODE] = ROTATE_MODE_PITCH

            dynamiteSound(id, SOUND_MENU_NAV)
            dynamiteMenu(id, MENU_ROTATE_DYNAMITE)
        }
        case ROTATE_DYNAMITE_SIZE:
        {
            if ( ++ g_ePlayerData[id][PDATA_ROTATE_SIZE] > SIZE_LARGE )
                g_ePlayerData[id][PDATA_ROTATE_SIZE] = SIZE_SMALL

            eDynamite[DYNAMITE_LAST_SIZE] = g_ePlayerData[id][PDATA_ROTATE_SIZE]
            switch( eDynamite[DYNAMITE_LAST_SIZE] )
            {
                case SIZE_SMALL:    engfunc(EngFunc_SetModel, eDynamite[DYNAMITE_LAST_ID], g_eSettings[SETTING_MODEL_DYNAMITE_SMALL])
                case SIZE_MEDIUM:   engfunc(EngFunc_SetModel, eDynamite[DYNAMITE_LAST_ID], g_eSettings[SETTING_MODEL_DYNAMITE_MEDIUM])
                case SIZE_LARGE:    engfunc(EngFunc_SetModel, eDynamite[DYNAMITE_LAST_ID], g_eSettings[SETTING_MODEL_DYNAMITE_LARGE])
            }

            ArraySetCell(eDynamite[DYNAMITE_SIZE], eDynamite[DYNAMITE_ID_COUNT] - 1, eDynamite[DYNAMITE_LAST_SIZE])
            ArraySetArray(g_aDynamite, iItem, eDynamite)
            dynamiteSound(id, SOUND_MENU_NAV)
            dynamiteMenu(id, MENU_ROTATE_DYNAMITE)
        }
        case ROTATE_DYNAMITE_ADD:
        {
            eDynamite[DYNAMITE_LAST_ANGLES][0] = -eDynamite[DYNAMITE_LAST_ANGLES][0]
            dynamiteTrace(eDynamite, id)
            dynamiteSetSize(eDynamite, ENTITY_DYNAMITE)
            dynamiteSetState(eDynamite)
            dynamiteCreateDynamite(eDynamite)
            client_print_color(id, id, "%L %L", id, "DYNAMITE_CHAT_TAG", id, "DYNAMITE_CHAT_CREATE_NEW", eDynamite[DYNAMITE_NAME])

            ArraySetArray(g_aDynamite, iItem, eDynamite)
            dynamiteSound(id, SOUND_MENU_NAV)
            dynamiteMenu(id, MENU_ROTATE_DYNAMITE)
        }
        case ROTATE_DYNAMITE_FINISH:
        {
            dynamiteTrace(eDynamite, id)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_DYNAMITE_GHOST] = 0

            eDynamite[DYNAMITE_FLAGS] &= ~(FLAG_GHOST | FLAG_LOCK)
            eDynamite[DYNAMITE_FLAGS] |= FLAG_ACTIVE
            eDynamite[DYNAMITE_LAST_ANGLES][0] = -eDynamite[DYNAMITE_LAST_ANGLES][0]
            dynamiteSetSize(eDynamite, ENTITY_DYNAMITE)
            dynamiteSetState(eDynamite)
            client_print_color(id, id, "%L %L", id, "DYNAMITE_CHAT_TAG", id, "DYNAMITE_CHAT_CREATE_NEW", eDynamite[DYNAMITE_NAME])

            ArraySetArray(g_aDynamite, iItem, eDynamite)
            dynamiteSound(id, SOUND_MENU_NAV)
            dynamiteMenu(id, MENU_CREATE)
        }
        case MENU_EXIT:
        {
            dynamiteKill(eDynamite)
            dynamiteRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_DYNAMITE_GHOST] = 0

            dynamiteSound(id, SOUND_MENU_NAV)
            dynamiteMenu(id, MENU_CREATE)
        }
        default:
        {
            dynamiteKill(eDynamite)
            dynamiteRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_DYNAMITE_GHOST] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public dynamiteTask()
{
    new eDynamite[DYNAMITE], bool:bModified, Float:fCurrentTime
    fCurrentTime = get_gametime()

    for ( new i = 0; i < g_iDynamite; i ++ )
    {
        ArrayGetArray(g_aDynamite, i, eDynamite)
        bModified = false

        if ( eDynamite[DYNAMITE_FLAGS] & FLAG_ACTIVE )
        {
            if ( eDynamite[DYNAMITE_NEXT_EXPLOSION] > 0.0
            && fCurrentTime >= eDynamite[DYNAMITE_NEXT_EXPLOSION] )
            {
                eDynamite[DYNAMITE_FLAGS] |= FLAG_EXPLODE
                eDynamite[DYNAMITE_NEXT_EXPLOSION] = 0.0
                eDynamite[DYNAMITE_NEXT_ACTIVE] = fCurrentTime + random_float(eDynamite[DYNAMITE_COOLDOWN][0], eDynamite[DYNAMITE_COOLDOWN][1])
                dynamiteExplode(eDynamite)
                dynamiteSetState(eDynamite)

                bModified = true
            }
            else if ( eDynamite[DYNAMITE_NEXT_ACTIVE] > 0.0
            && fCurrentTime >= eDynamite[DYNAMITE_NEXT_ACTIVE] )
            {
                eDynamite[DYNAMITE_ACTIVATOR] = 0
                eDynamite[DYNAMITE_NEXT_ACTIVE] = 0.0
                eDynamite[DYNAMITE_FLAGS] &= ~(FLAG_TRIGGER | FLAG_EXPLODE)
                dynamiteSetState(eDynamite)

                bModified = true
            }
        }

        if ( bModified )
            ArraySetArray(g_aDynamite, i, eDynamite)
    }
}

stock dynamiteCreate(id, iItem)
{
    new iEnt = cs_create_entity("info_target")
    if ( !pev_valid(iEnt) )
        return

    new eDynamite[DYNAMITE], szCN[32]
    ArrayGetArray(g_aDynamiteConfig, iItem, eDynamite)
    eDynamite[DYNAMITE_SIZE] = ArrayCreate(1)
    eDynamite[DYNAMITE_ID_DYNAMITE] = ArrayCreate(1)
    eDynamite[DYNAMITE_ORIGIN_DYNAMITE] = ArrayCreate(3)
    eDynamite[DYNAMITE_ANGLES_DYNAMITE] = ArrayCreate(3)
    eDynamite[DYNAMITE_ID_TRIGGER] = iEnt
    eDynamite[DYNAMITE_ITEM] = iItem
    if ( id )
    {
        EnableAction(id)
        g_ePlayerData[id][PDATA_DYNAMITE_GHOST] = eDynamite[DYNAMITE_ID_TRIGGER]
        g_ePlayerData[id][PDATA_ROTATE_MODE] = ROTATE_MODE_YAW
        g_ePlayerData[id][PDATA_OFFSET] = g_eSettings[SETTING_OFFSET_BASE]

        eDynamite[DYNAMITE_FLAGS] |= FLAG_GHOST
        eDynamite[DYNAMITE_LAST_SIZE] = g_ePlayerData[id][PDATA_ROTATE_SIZE]
    }

    formatex(szCN, charsmax(szCN), "%s_trigger", g_szCN)
    dynamiteSelect(eDynamite, TARGET_GHOST, false)
    set_pev(iEnt, pev_classname, szCN)
    set_pev(iEnt, pev_impulse, DYNAMITE_KEY)
    set_pev(iEnt, DYNAMITE_ARRAY_ITEM, g_iDynamite)
    dllfunc(DLLFunc_Spawn, iEnt)
    set_pev(iEnt, pev_solid, SOLID_NOT)
    set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
    engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_MODEL_TRIGGER])

    ArrayPushArray(g_aDynamite, eDynamite)
    if ( ++ g_iDynamite == 1 )
    {
        set_task(g_eSettings[SETTING_DYNAMITE_TASK], "dynamiteTask", DYNAMITE_KEY, .flags = "b")
        EnableDynamite()
    }
}

stock dynamiteCreateDynamite(eDynamite[DYNAMITE])
{
    new iEnt = cs_create_entity("info_target")
    if ( !pev_valid(iEnt) )
        return

    new szCN[32]
    ArrayPushCell(eDynamite[DYNAMITE_ID_DYNAMITE], iEnt)
    ArrayPushCell(eDynamite[DYNAMITE_SIZE], eDynamite[DYNAMITE_LAST_SIZE])
    ArrayPushArray(eDynamite[DYNAMITE_ORIGIN_DYNAMITE], Float:{0.0, 0.0, 0.0})
    ArrayPushArray(eDynamite[DYNAMITE_ANGLES_DYNAMITE], Float:{0.0, 0.0, 0.0})
    eDynamite[DYNAMITE_LAST_ID] = iEnt
    eDynamite[DYNAMITE_ID_COUNT] ++
    eDynamite[DYNAMITE_FLAGS] |= FLAG_LOCK

    formatex(szCN, charsmax(szCN), "%s_dynamite", g_szCN)
    dynamiteSelect(eDynamite, TARGET_GHOST)
    set_pev(iEnt, DYNAMITE_OWNER, eDynamite[DYNAMITE_ID_TRIGGER])
    set_pev(iEnt, pev_classname, szCN)
    dllfunc(DLLFunc_Spawn, iEnt)
    set_pev(iEnt, pev_solid, SOLID_NOT)
    set_pev(iEnt, pev_movetype, MOVETYPE_FLY)

    switch( eDynamite[DYNAMITE_LAST_SIZE] )
    {
        case SIZE_SMALL:    engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_MODEL_DYNAMITE_SMALL])
        case SIZE_MEDIUM:   engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_MODEL_DYNAMITE_MEDIUM])
        case SIZE_LARGE:    engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_MODEL_DYNAMITE_LARGE])
    }
}

public dynamiteRemove(iItem)
{
    new eDynamite[DYNAMITE]
    ArrayGetArray(g_aDynamite, iItem, eDynamite)
    ArrayDestroy(eDynamite[DYNAMITE_SIZE])
    ArrayDestroy(eDynamite[DYNAMITE_ID_DYNAMITE])
    ArrayDestroy(eDynamite[DYNAMITE_ORIGIN_DYNAMITE])
    ArrayDestroy(eDynamite[DYNAMITE_ANGLES_DYNAMITE])
    ArrayDeleteItem(g_aDynamite, iItem)

    if ( -- g_iDynamite == 0 )
    {
        remove_task(DYNAMITE_KEY)
        DisableDynamite()
    }

    for ( new i = iItem; i < g_iDynamite; i ++ )
    {
        ArrayGetArray(g_aDynamite, i, eDynamite)
        set_pev(eDynamite[DYNAMITE_ID_TRIGGER], DYNAMITE_ARRAY_ITEM, i)
    }
}

public saveData(id)
{
    new eDynamite[DYNAMITE],
        szFile[128], iFile, szData[128]

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_DynamiteTrap.ini", szFile)

    iFile = fopen(szFile, "wt")
    if ( !iFile )
        return PLUGIN_HANDLED

    dynamiteTerminate()
    for ( new i = 0; i < g_iDynamite; i ++ )
    {
        ArrayGetArray(g_aDynamite, i, eDynamite)

        formatex(szData, charsmax(szData), "[%d]^n", i)
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "item = %d^n", eDynamite[DYNAMITE_ITEM])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "flags = %d^n", eDynamite[DYNAMITE_FLAGS])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "trigger_origin = %.2f %.2f %.2f^n",
        eDynamite[DYNAMITE_ORIGIN_TRIGGER][0], eDynamite[DYNAMITE_ORIGIN_TRIGGER][1], eDynamite[DYNAMITE_ORIGIN_TRIGGER][2])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "trigger_angles = %.2f %.2f %.2f^n",
        eDynamite[DYNAMITE_ANGLES_TRIGGER][0], eDynamite[DYNAMITE_ANGLES_TRIGGER][1], eDynamite[DYNAMITE_ANGLES_TRIGGER][2])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "dynamite_count = %d^n", eDynamite[DYNAMITE_ID_COUNT])
        fputs(iFile, szData)

        for ( new j = 0; j < eDynamite[DYNAMITE_ID_COUNT]; j ++ )
        {
            formatex(szData, charsmax(szData), "dynamite_size_%d = %d^n", j, ArrayGetCell(eDynamite[DYNAMITE_SIZE], j))
            fputs(iFile, szData)

            ArrayGetArray(eDynamite[DYNAMITE_ORIGIN_DYNAMITE], j, eDynamite[DYNAMITE_LAST_ORIGIN])
            formatex(szData, charsmax(szData), "dynamite_origin_%d = %.2f %.2f %.2f^n", j,
            eDynamite[DYNAMITE_LAST_ORIGIN][0], eDynamite[DYNAMITE_LAST_ORIGIN][1], eDynamite[DYNAMITE_LAST_ORIGIN][2])
            fputs(iFile, szData)

            ArrayGetArray(eDynamite[DYNAMITE_ANGLES_DYNAMITE], j, eDynamite[DYNAMITE_LAST_ANGLES])
            formatex(szData, charsmax(szData), "dynamite_angles_%d = %.2f %.2f %.2f^n", j,
            eDynamite[DYNAMITE_LAST_ANGLES][0], eDynamite[DYNAMITE_LAST_ANGLES][1], eDynamite[DYNAMITE_LAST_ANGLES][2])
            fputs(iFile, szData)
        }
    }

    client_print_color(id, id, "%L %L", id, "DYNAMITE_CHAT_TAG", id, "DYNAMITE_CHAT_SAVE", szFile)
    fclose(iFile)

    dynamiteSound(id, SOUND_MENU_NAV)
    dynamiteMenu(id, MENU_ROOT)
    return PLUGIN_HANDLED
}

public loadData()
{
    new szFile[128], iFile,
        szData[128], szKey[32], szValue[96],
        Float:fOriginTrigger[3], Float:fAnglesTrigger[3],
        Float:fOriginDynamite[3], Float:fAnglesDynamite[3],
        iItem, iFlags, iCount = -1, iDynamiteCount,
        Array:aSize, Array:aOrigin, Array:aAngles

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_DynamiteTrap.ini", szFile)

    iFile = fopen(szFile, "rt")
    if ( !iFile )
        return

    aSize = ArrayCreate(1)
    aOrigin = ArrayCreate(3)
    aAngles = ArrayCreate(3)

    while ( !feof(iFile) )
    {
        fgets(iFile, szData, charsmax(szData))

        if ( szData[0] == '[' )
        {
            if ( iCount != -1 )
                LoadDataDynamite(iItem, iFlags, fOriginTrigger, fAnglesTrigger, iDynamiteCount, aSize, aOrigin, aAngles, iCount)

            iCount ++
            iDynamiteCount = 0
            ArrayClear(aSize)
            ArrayClear(aOrigin)
            ArrayClear(aAngles)
        }
        else
        {
            strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
            trim(szKey)
            trim(szValue)

            if ( equal(szKey, "item") )
            {
                iItem = str_to_num(szValue)
            }
            else if ( equal(szKey, "flags") )
            {
                iFlags = str_to_num(szValue)
            }
            else if ( equal(szKey, "trigger_origin") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOriginTrigger[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOriginTrigger[1] = str_to_float(szKey)
                fOriginTrigger[2] = str_to_float(szValue)
            }
            else if ( equal(szKey, "trigger_angles") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAnglesTrigger[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAnglesTrigger[1] = str_to_float(szKey)
                fAnglesTrigger[2] = str_to_float(szValue)
            }
            else if ( equal(szKey, "dynamite_count") )
            {
                iDynamiteCount = str_to_num(szValue)
            }
            else if ( contain(szKey, "dynamite_size") != -1 )
            {
                ArrayPushCell(aSize, str_to_num(szValue))
            }
            else if ( contain(szKey, "dynamite_origin") != -1 )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOriginDynamite[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOriginDynamite[1] = str_to_float(szKey)
                fOriginDynamite[2] = str_to_float(szValue)
                ArrayPushArray(aOrigin, fOriginDynamite)
            }
            else if ( contain(szKey, "dynamite_angles") != -1 )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAnglesDynamite[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAnglesDynamite[1] = str_to_float(szKey)
                fAnglesDynamite[2] = str_to_float(szValue)
                ArrayPushArray(aAngles, fAnglesDynamite)
            }
        }
    }

    if ( iCount != -1 )
        LoadDataDynamite(iItem, iFlags, fOriginTrigger, fAnglesTrigger, iDynamiteCount, aSize, aOrigin, aAngles, iCount)

    ArrayDestroy(aSize)
    ArrayDestroy(aOrigin)
    ArrayDestroy(aAngles)
    fclose(iFile)
}

stock LoadDataDynamite(iItem, iFlags, Float:fOriginTrigger[3], Float:fAnglesTrigger[3], iDynamiteCount, Array:aSize, Array:aOrigin, Array:aAngles, iCount)
{
    new eDynamite[DYNAMITE]
    dynamiteCreate(0, iItem)
    ArrayGetArray(g_aDynamite, iCount, eDynamite)

    eDynamite[DYNAMITE_FLAGS] = iFlags
    fAnglesTrigger[0] = -fAnglesTrigger[0]
    xs_vec_copy(fOriginTrigger, eDynamite[DYNAMITE_ORIGIN_TRIGGER])
    xs_vec_copy(fAnglesTrigger, eDynamite[DYNAMITE_ANGLES_TRIGGER])

    dynamiteSetBox(eDynamite, ENTITY_TRIGGER)
    dynamiteSetSize(eDynamite, ENTITY_TRIGGER)

    for ( new i = 0; i < iDynamiteCount; i ++ )
    {
        eDynamite[DYNAMITE_LAST_SIZE] = ArrayGetCell(aSize, i)
        dynamiteCreateDynamite(eDynamite)
        ArrayGetArray(aOrigin, i, eDynamite[DYNAMITE_LAST_ORIGIN])
        ArrayGetArray(aAngles, i, eDynamite[DYNAMITE_LAST_ANGLES])
        eDynamite[DYNAMITE_LAST_ANGLES][0] = -eDynamite[DYNAMITE_LAST_ANGLES][0]

        ArraySetCell(eDynamite[DYNAMITE_SIZE], i, eDynamite[DYNAMITE_LAST_SIZE])
        ArraySetArray(eDynamite[DYNAMITE_ORIGIN_DYNAMITE], i, eDynamite[DYNAMITE_LAST_ORIGIN])
        ArraySetArray(eDynamite[DYNAMITE_ANGLES_DYNAMITE], i, eDynamite[DYNAMITE_LAST_ANGLES])

        dynamiteSetBox(eDynamite, ENTITY_DYNAMITE)
        dynamiteSetSize(eDynamite, ENTITY_DYNAMITE)
    }

    eDynamite[DYNAMITE_FLAGS] &= ~FLAG_LOCK
    dynamiteSetState(eDynamite)
    ArraySetArray(g_aDynamite, iCount, eDynamite)
}

public dynamiteNoClip(id)
{
    set_user_noclip(id, !get_user_noclip(id))

    dynamiteSound(id, SOUND_MENU_NAV)
    dynamiteMenu(id, MENU_ROOT)
}

public dynamiteGodMode(id)
{
    set_user_godmode(id, !get_user_godmode(id))

    dynamiteSound(id, SOUND_MENU_NAV)
    dynamiteMenu(id, MENU_ROOT)
}

public fwdUse(iEnt, iCaller, iActivator, iType, Float:fValue)
{
    if ( !isDynamite(iEnt)
    || !is_user_alive(iActivator) )
        return HAM_IGNORED

    new eDynamite[DYNAMITE], iItem
    if ( (iItem = dynamiteGet(eDynamite, iEnt)) == -1 )
        return HAM_IGNORED

    if ( !(eDynamite[DYNAMITE_FLAGS] & FLAG_ACTIVE)
    || eDynamite[DYNAMITE_FLAGS] & FLAG_TRIGGER
    || !(CsTeams:eDynamite[DYNAMITE_TEAM] & cs_get_user_team(iActivator))
    || get_gametime() < eDynamite[DYNAMITE_NEXT_ACTIVE] )
        return HAM_IGNORED

    new szSound[MAX_RESOURCE_PATH_LENGTH]
    ArrayGetString(g_eSettings[SETTING_DEFAULT_SOUND_TRIGGER], random(ArraySize(g_eSettings[SETTING_DEFAULT_SOUND_TRIGGER])), szSound, charsmax(szSound))
    engfunc(EngFunc_EmitSound, eDynamite[DYNAMITE_ID_TRIGGER], CHAN_ITEM, szSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

    eDynamite[DYNAMITE_FLAGS] |= FLAG_TRIGGER
    eDynamite[DYNAMITE_ACTIVATOR] = iActivator
    eDynamite[DYNAMITE_NEXT_EXPLOSION] = get_gametime() + random_float(eDynamite[DYNAMITE_EXPLOSION_DELAY][0], eDynamite[DYNAMITE_EXPLOSION_DELAY][1])
    dynamiteSetSeq(eDynamite, DYNAMITE_SEQ_DOWN)
    ArraySetArray(g_aDynamite, iItem, eDynamite)
    return HAM_IGNORED
}

public fwdObjectCaps(iEnt)
{
    if ( !isDynamite(iEnt) )
        return HAM_IGNORED

    SetHamReturnInteger(FCAP_IMPULSE_USE)
    return HAM_SUPERCEDE
}

public fwdPreThink(id)
{
    if ( !is_user_alive(id) )
        return HAM_IGNORED

    static eDynamite[DYNAMITE], iButton, Float:fCurrentTime
    iButton = pev(id, pev_button)
    fCurrentTime = get_gametime()

    if ( dynamiteGet(eDynamite, g_ePlayerData[id][PDATA_DYNAMITE_GHOST]) != -1 )
    {
        if ( g_ePlayerData[id][PDATA_DYNAMITE_GHOST] )
        {
            if ( fCurrentTime > g_ePlayerData[id][PDATA_NEXT_OFFSET] )
            {
                if ( iButton & IN_ATTACK )
                {
                    g_ePlayerData[id][PDATA_OFFSET]      += g_eSettings[SETTING_OFFSET_STEP]
                    g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], g_eSettings[SETTING_OFFSET][0], g_eSettings[SETTING_OFFSET][1])
                    g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + 0.1
                }
                else if ( iButton & IN_ATTACK2 )
                {
                    g_ePlayerData[id][PDATA_OFFSET]      -= g_eSettings[SETTING_OFFSET_STEP]
                    g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], g_eSettings[SETTING_OFFSET][0], g_eSettings[SETTING_OFFSET][1])
                    g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + 0.1
                }
            }

            set_pdata_float(id, PDATA_NEXT_ATTACK, fCurrentTime + 0.1, XO_CBASEPLAYER, XO_CBASEPLAYER)
            iButton &= ~(IN_ATTACK | IN_ATTACK2)
            set_pev(id, pev_button, iButton)

            dynamiteTrace(eDynamite, id)
        }
    }
    else if ( g_ePlayerData[id][PDATA_DYNAMITE_ACTION] )
    {
        dynamiteCheck(id)
    }

    return HAM_IGNORED
}

public fwdKilled(id, iAttacker, bGib)
{
    DisableAction(id)
    g_ePlayerData[id][PDATA_DYNAMITE_MENU]   = 0
    if ( g_ePlayerData[id][PDATA_DYNAMITE_GHOST] )
    {
        new eDynamite[DYNAMITE], iItem
        if ( (iItem = dynamiteGet(eDynamite, g_ePlayerData[id][PDATA_DYNAMITE_GHOST])) != -1 )
        {
            dynamiteKill(eDynamite)
            dynamiteRemove(iItem)
        }

        g_ePlayerData[id][PDATA_DYNAMITE_GHOST] = 0
    }
}

stock dynamiteTrace(eDynamite[DYNAMITE], id)
{
    new Float:fVec1[3], Float:fVec2[3]
    pev(id, pev_origin, fVec2)
    pev(id, pev_view_ofs, fVec1)
    xs_vec_add(fVec2, fVec1, fVec2)
    pev(id, pev_v_angle, fVec1)
    engfunc(EngFunc_MakeVectors, fVec1)
    global_get(glb_v_forward, fVec1)

    xs_vec_mul_scalar(fVec1, g_ePlayerData[id][PDATA_OFFSET], fVec1)
    xs_vec_add(fVec1, fVec2, fVec1)

    engfunc(EngFunc_TraceLine, fVec2, fVec1, DONT_IGNORE_MONSTERS, id, 0)
    get_tr2(0, TR_vecEndPos, fVec2)

    if ( eDynamite[DYNAMITE_FLAGS] & FLAG_LOCK )
    {
        dynamiteSetBox(eDynamite, ENTITY_DYNAMITE)
        dynamiteSetOffset(eDynamite, fVec2, eDynamite[DYNAMITE_LAST_ID])

        xs_vec_copy(fVec2, eDynamite[DYNAMITE_LAST_ORIGIN])
        set_pev(eDynamite[DYNAMITE_LAST_ID], pev_origin, fVec2)
    }
    else
    {
        dynamiteSetBox(eDynamite, ENTITY_TRIGGER)
        dynamiteSetOffset(eDynamite, fVec2, eDynamite[DYNAMITE_ID_TRIGGER])

        xs_vec_copy(fVec2, eDynamite[DYNAMITE_ORIGIN_TRIGGER])
        set_pev(eDynamite[DYNAMITE_ID_TRIGGER], pev_origin, fVec2)
    }
}

stock dynamiteCheck(id)
{
    new eDynamite[DYNAMITE], Float:fVec1[3], Float:fVec2[3], Float:fVec3[3], Float:fMins[3], Float:fMaxs[3], Float:fNearest[3], Float:fOrigin[3]
    new iBest, iDynamite, Float:fBestDist, Float:fDotSwitch, Float:fDotDynamite, Float:fDist

    pev(id, pev_origin, fVec1)
    pev(id, pev_view_ofs, fVec2)
    xs_vec_add(fVec1, fVec2, fVec1)

    pev(id, pev_v_angle, fVec2)
    engfunc(EngFunc_MakeVectors, fVec2)
    global_get(glb_v_forward, fVec2)

    iBest = -1
    fBestDist = g_eSettings[SETTING_DYNAMITE_CHECK]

    for ( new i = 0; i < g_iDynamite; i ++ )
    {
        ArrayGetArray(g_aDynamite, i, eDynamite)

        xs_vec_sub(eDynamite[DYNAMITE_ORIGIN_TRIGGER], fVec1, fVec3)
        fDotSwitch = xs_vec_dot(fVec2, fVec3)

        if ( fDotSwitch >= 0.0 )
        {
            xs_vec_mul_scalar(fVec2, fDotSwitch, fVec3)
            xs_vec_add(fVec3, fVec1, fVec3)

            pev(eDynamite[DYNAMITE_ID_TRIGGER], pev_absmin, fMins)
            pev(eDynamite[DYNAMITE_ID_TRIGGER], pev_absmax, fMaxs)
            fNearest[0] = floatclamp(fVec3[0], fMins[0], fMaxs[0])
            fNearest[1] = floatclamp(fVec3[1], fMins[1], fMaxs[1])
            fNearest[2] = floatclamp(fVec3[2], fMins[2], fMaxs[2])
            fDist = xs_vec_distance(fVec3, fNearest)

            if ( fDist < fBestDist )
            {
                fBestDist = fDist
                iBest = i
            }
        }

        for ( new j = 0; j < eDynamite[DYNAMITE_ID_COUNT]; j ++ )
        {
            iDynamite = ArrayGetCell(eDynamite[DYNAMITE_ID_DYNAMITE], j)
            ArrayGetArray(eDynamite[DYNAMITE_ORIGIN_DYNAMITE], j, fOrigin)

            xs_vec_sub(fOrigin, fVec1, fVec3)
            fDotDynamite = xs_vec_dot(fVec2, fVec3)
            if ( fDotDynamite < 0.0 )
                continue

            xs_vec_mul_scalar(fVec2, fDotDynamite, fVec3)
            xs_vec_add(fVec3, fVec1, fVec3)

            pev(iDynamite, pev_absmin, fMins)
            pev(iDynamite, pev_absmax, fMaxs)
            fNearest[0] = floatclamp(fVec3[0], fMins[0], fMaxs[0])
            fNearest[1] = floatclamp(fVec3[1], fMins[1], fMaxs[1])
            fNearest[2] = floatclamp(fVec3[2], fMins[2], fMaxs[2])
            fDist = xs_vec_distance(fVec3, fNearest)

            if ( fDist < fBestDist )
            {
                fBestDist = fDist
                iBest = i
            }
        }
    }

    if ( iBest != -1
    && g_ePlayerData[id][PDATA_DYNAMITE_MENU] != iBest )
    {
        ArrayGetArray(g_aDynamite, g_ePlayerData[id][PDATA_DYNAMITE_MENU], eDynamite)
        dynamiteSelect(eDynamite, eDynamite[DYNAMITE_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

        g_ePlayerData[id][PDATA_MENU_TRACE] = true
        g_ePlayerData[id][PDATA_DYNAMITE_MENU] = iBest
        dynamiteMenu(id, g_ePlayerData[id][PDATA_MENU_TYPE])
    }
}

stock dynamiteShake(eDynamite[DYNAMITE])
{
    new Float:fOrigin[3]
    for ( new id = 1; id <= g_iMaxPlayers; id ++ )
    {
        if ( !is_user_alive(id) )
            continue

        pev(id, pev_origin, fOrigin)
        if ( xs_vec_distance(fOrigin, eDynamite[DYNAMITE_ORIGIN_DYNAMITE]) > eDynamite[DYNAMITE_SHAKE_DISTANCE] )
            continue

        message_begin(MSG_ONE_UNRELIABLE, g_iScreenShake, .player = id)
        write_short(eDynamite[DYNAMITE_SHAKE_AMPLITUDE] * 4096)
        write_short(eDynamite[DYNAMITE_SHAKE_DURATION] * 4096)
        write_short(eDynamite[DYNAMITE_SHAKE_FREQUENCY] * 4096)
        message_end()
    }
}

stock dynamiteSparks(Float:fOrigin[3])
{
    message_begin_f(MSG_PVS, SVC_TEMPENTITY, fOrigin)
    write_byte(TE_SPARKS)
    write_coord_f(fOrigin[0])
    write_coord_f(fOrigin[1])
    write_coord_f(fOrigin[2])
    message_end()
}

stock dynamiteExplode(eDynamite[DYNAMITE])
{
    new Float:fOrigin[3], Float:fDistance, Float:fFactor, Float:fDamage,
        Float:fVec1[3], Float:fVec2[3], iEnt, iKiller

    iKiller = g_eSettings[SETTING_KILL_WORLD] ? 0 : eDynamite[DYNAMITE_ACTIVATOR]
    for ( new i = 0; i < eDynamite[DYNAMITE_ID_COUNT]; i ++ )
    {
        ArrayGetArray(eDynamite[DYNAMITE_ORIGIN_DYNAMITE], i, fOrigin)
        message_begin_f(MSG_PVS, SVC_TEMPENTITY, fOrigin)
        write_byte(TE_EXPLOSION)
        write_coord_f(fOrigin[0])
        write_coord_f(fOrigin[1])
        write_coord_f(fOrigin[2])
        write_short(eDynamite[DYNAMITE_SPRITE_EXPLOSION])
        write_byte(floatround(eDynamite[DYNAMITE_EXPLOSION_RADIUS] / 15.0))
        write_byte(g_eSettings[SETTING_DEFAULT_EXPLOSION_FRAMERATE])
        write_byte(eDynamite[DYNAMITE_EXPLOSION_FLAGS])
        message_end()

        iEnt = -1
        while ( (iEnt = engfunc(EngFunc_FindEntityInSphere, iEnt, fOrigin, eDynamite[DYNAMITE_EXPLOSION_RADIUS])) )
        {
            if ( !pev_valid(iEnt)
            || pev(iEnt, pev_takedamage) == DAMAGE_NO
            || (is_user_alive(iEnt) && !(cs_get_user_team(iEnt) & CsTeams:eDynamite[DYNAMITE_EXPLOSION_TEAM])) )
                continue

            pev(iEnt, pev_absmin, fVec1)
            pev(iEnt, pev_absmax, fVec2)
            xs_vec_add(fVec1, fVec2, fVec1)
            xs_vec_mul_scalar(fVec1, 0.5, fVec1)
            fDistance = xs_vec_distance(fOrigin, fVec1)
            if ( fDistance > eDynamite[DYNAMITE_EXPLOSION_RADIUS] )
                continue

            fFactor = g_eSettings[SETTING_MORE_DAMAGE_FOR_CLOSE] ? 1.0 - fDistance / eDynamite[DYNAMITE_EXPLOSION_RADIUS] : 1.0
            fDamage = random_float(eDynamite[DYNAMITE_EXPLOSION_DAMAGE][0], eDynamite[DYNAMITE_EXPLOSION_DAMAGE][1]) * fFactor

            ExecuteHamB(Ham_TakeDamage, iEnt, 0, iKiller, fDamage, eDynamite[DYNAMITE_EXPLOSION_DAMAGE_TYPE])
        }
    }
}

stock dynamiteSetBox(eDynamite[DYNAMITE], iEntity)
{
    new Float:fMins[3], Float:fMaxs[3],
        Float:fForward[3], Float:fRight[3], Float:fUp[3],
        Float:fCorners[8][3]

    if ( iEntity == ENTITY_DYNAMITE )
    {
        eDynamite[DYNAMITE_LAST_ANGLES][0] = -eDynamite[DYNAMITE_LAST_ANGLES][0]
        engfunc(EngFunc_AngleVectors, eDynamite[DYNAMITE_LAST_ANGLES], fForward, fRight, fUp)

        switch ( eDynamite[DYNAMITE_LAST_SIZE] )
        {
            case SIZE_SMALL:     xs_vec_copy(g_eSettings[SETTING_MINS_DYNAMITE_SMALL], fMins), xs_vec_copy(g_eSettings[SETTING_MAXS_DYNAMITE_SMALL], fMaxs)
            case SIZE_MEDIUM:    xs_vec_copy(g_eSettings[SETTING_MINS_DYNAMITE_MEDIUM], fMins), xs_vec_copy(g_eSettings[SETTING_MAXS_DYNAMITE_MEDIUM], fMaxs)
            case SIZE_LARGE:     xs_vec_copy(g_eSettings[SETTING_MINS_DYNAMITE_LARGE], fMins), xs_vec_copy(g_eSettings[SETTING_MAXS_DYNAMITE_LARGE], fMaxs)
        }
    }
    else
    {
        eDynamite[DYNAMITE_ANGLES_TRIGGER][0] = -eDynamite[DYNAMITE_ANGLES_TRIGGER][0]
        engfunc(EngFunc_AngleVectors, eDynamite[DYNAMITE_ANGLES_TRIGGER], fForward, fRight, fUp)

        xs_vec_copy(g_eSettings[SETTING_MINS_TRIGGER], fMins)
        xs_vec_copy(g_eSettings[SETTING_MAXS_TRIGGER], fMaxs)
    }

    for ( new i = 0; i < 8; i ++ )
    {
        fCorners[i][0] = (i & 1) ? fMaxs[0] : fMins[0]
        fCorners[i][1] = (i & 2) ? fMaxs[1] : fMins[1]
        fCorners[i][2] = (i & 4) ? fMaxs[2] : fMins[2]

        boxRotate(fCorners[i], fForward, fRight, fUp)
    }

    xs_vec_copy(fCorners[0], fMins)
    xs_vec_copy(fCorners[0], fMaxs)
    for ( new i = 1; i < 8; i ++ )
    {
        fMins[0] = floatmin(fMins[0], fCorners[i][0])
        fMins[1] = floatmin(fMins[1], fCorners[i][1])
        fMins[2] = floatmin(fMins[2], fCorners[i][2])

        fMaxs[0] = floatmax(fMaxs[0], fCorners[i][0])
        fMaxs[1] = floatmax(fMaxs[1], fCorners[i][1])
        fMaxs[2] = floatmax(fMaxs[2], fCorners[i][2])
    }

    xs_vec_copy(fMins, eDynamite[DYNAMITE_MINS])
    xs_vec_copy(fMaxs, eDynamite[DYNAMITE_MAXS])
}

stock boxRotate(Float:fLocal[3], Float:fForward[3], Float:fRight[3], Float:fUp[3])
{
    new Float:fOut[3]
    fOut[0] = fLocal[0] * fForward[0] - fLocal[1] * fRight[0] + fLocal[2] * fUp[0]
    fOut[1] = fLocal[0] * fForward[1] - fLocal[1] * fRight[1] + fLocal[2] * fUp[1]
    fOut[2] = fLocal[0] * fForward[2] - fLocal[1] * fRight[2] + fLocal[2] * fUp[2]

    xs_vec_copy(fOut, fLocal)
}

stock dynamiteSetOffset(eDynamite[DYNAMITE], Float:fOrigin[3], iEnt)
{
    new Float:fGaps[6], Float:fVec1[3], Float:fCurrentGap
    fGaps[0] = -eDynamite[DYNAMITE_MINS][0]
    fGaps[1] = eDynamite[DYNAMITE_MAXS][0]
    fGaps[2] = -eDynamite[DYNAMITE_MINS][1]
    fGaps[3] = eDynamite[DYNAMITE_MAXS][1]
    fGaps[4] = -eDynamite[DYNAMITE_MINS][2]
    fGaps[5] = eDynamite[DYNAMITE_MAXS][2]

    if ( eDynamite[DYNAMITE_FLAGS] & FLAG_GROUND )
    {
        xs_vec_sub(fOrigin, Float:{0.0, 0.0, 9999.9}, fVec1)
        engfunc(EngFunc_TraceLine, fOrigin, fVec1, DONT_IGNORE_MONSTERS, eDynamite[DYNAMITE_ID_TRIGGER], 0)
        get_tr2(0, TR_vecEndPos, fOrigin)
    }

    for ( new i = 5; i >= 0; i -- )
    {
        xs_vec_mul_scalar(g_fDirections[i], 9999.9, fVec1)
        xs_vec_add(fVec1, fOrigin, fVec1)
        engfunc(EngFunc_TraceLine, fOrigin, fVec1, DONT_IGNORE_MONSTERS, iEnt, 0)
        get_tr2(0, TR_vecEndPos, fVec1)
        fCurrentGap = xs_vec_distance(fOrigin, fVec1)

        if ( fCurrentGap < fGaps[i] )
        {
            get_tr2(0, TR_vecPlaneNormal, fVec1)
            xs_vec_mul_scalar(fVec1, fGaps[i] - fCurrentGap, fVec1)
            xs_vec_add(fOrigin, fVec1, fOrigin)
        }
    }
}

stock dynamiteSetSeq(eDynamite[DYNAMITE], iSequence)
{
    set_pev(eDynamite[DYNAMITE_ID_TRIGGER], pev_sequence, iSequence)
    set_pev(eDynamite[DYNAMITE_ID_TRIGGER], pev_frame, 0.0)
    set_pev(eDynamite[DYNAMITE_ID_TRIGGER], pev_framerate, g_eSettings[SETTING_DEFAULT_FRAMERATE])
    set_pev(eDynamite[DYNAMITE_ID_TRIGGER], pev_animtime, get_gametime())
}

stock dynamiteSetSize(eDynamite[DYNAMITE], iEntity)
{
    if ( iEntity == ENTITY_TRIGGER )
    {
        engfunc(EngFunc_SetOrigin, eDynamite[DYNAMITE_ID_TRIGGER], eDynamite[DYNAMITE_ORIGIN_TRIGGER])
        set_pev(eDynamite[DYNAMITE_ID_TRIGGER], pev_angles, eDynamite[DYNAMITE_ANGLES_TRIGGER])
        set_pev(eDynamite[DYNAMITE_ID_TRIGGER], pev_solid, eDynamite[DYNAMITE_FLAGS] & FLAG_SHOW ? SOLID_BBOX : SOLID_NOT)
        set_pev(eDynamite[DYNAMITE_ID_TRIGGER], pev_movetype, MOVETYPE_NONE)

        engfunc(EngFunc_SetSize, eDynamite[DYNAMITE_ID_TRIGGER], eDynamite[DYNAMITE_MINS], eDynamite[DYNAMITE_MAXS])
        dynamiteCreateDynamite(eDynamite)
    }
    else if ( iEntity == ENTITY_DYNAMITE )
    {
        dynamiteSelect(eDynamite, TARGET_CLEAR)
        engfunc(EngFunc_SetOrigin, eDynamite[DYNAMITE_LAST_ID], eDynamite[DYNAMITE_LAST_ORIGIN])
        set_pev(eDynamite[DYNAMITE_LAST_ID], pev_angles, eDynamite[DYNAMITE_LAST_ANGLES])
        set_pev(eDynamite[DYNAMITE_LAST_ID], pev_solid, eDynamite[DYNAMITE_FLAGS] & FLAG_SHOW ? SOLID_BBOX : SOLID_NOT)
        set_pev(eDynamite[DYNAMITE_LAST_ID], pev_movetype, MOVETYPE_NONE)

        engfunc(EngFunc_SetSize, eDynamite[DYNAMITE_LAST_ID], eDynamite[DYNAMITE_MINS], eDynamite[DYNAMITE_MAXS])
        ArraySetArray(eDynamite[DYNAMITE_ORIGIN_DYNAMITE], eDynamite[DYNAMITE_ID_COUNT] - 1, eDynamite[DYNAMITE_LAST_ORIGIN])
    }
}

stock dynamiteSetState(eDynamite[DYNAMITE])
{
    if ( eDynamite[DYNAMITE_FLAGS] & FLAG_EXPLODE )
    {
        for ( new i = 0; i < eDynamite[DYNAMITE_ID_COUNT]; i ++ )
            set_pev(ArrayGetCell(eDynamite[DYNAMITE_ID_DYNAMITE], i), pev_solid, SOLID_NOT)

        dynamiteSelect(eDynamite, TARGET_HIDE)
    }
    else
    {
        if ( eDynamite[DYNAMITE_FLAGS] & FLAG_SHOW )
        {
            set_pev(eDynamite[DYNAMITE_ID_TRIGGER], pev_solid, SOLID_BBOX)
            for ( new i = 0; i < eDynamite[DYNAMITE_ID_COUNT]; i ++ )
                set_pev(ArrayGetCell(eDynamite[DYNAMITE_ID_DYNAMITE], i), pev_solid, SOLID_BBOX)

            dynamiteSelect(eDynamite, TARGET_CLEAR)
            if ( !(eDynamite[DYNAMITE_FLAGS] & FLAG_LOCK) )
                dynamiteSetSeq(eDynamite, DYNAMITE_SEQ_UP)
        }
        else
        {
            set_pev(eDynamite[DYNAMITE_ID_TRIGGER], pev_solid, SOLID_NOT)
            for ( new i = 0; i < eDynamite[DYNAMITE_ID_COUNT]; i ++ )
                set_pev(ArrayGetCell(eDynamite[DYNAMITE_ID_DYNAMITE], i), pev_solid, SOLID_NOT)

            dynamiteSelect(eDynamite, TARGET_HIDE)
        }
    }
}

stock dynamiteSelect(eDynamite[DYNAMITE], iAction, bool:bDynamiteExists = true)
{
    new iRenderColor[3]

    if ( iAction == TARGET_SELECT )
    {
        if ( eDynamite[DYNAMITE_FLAGS] & FLAG_ACTIVE )  { iRenderColor[0] = g_iColorActive[0];    iRenderColor[1] = g_iColorActive[1];    iRenderColor[2] = g_iColorActive[2]; }
        else                                            { iRenderColor[0] = g_iColorInactive[0];  iRenderColor[1] = g_iColorInactive[1];  iRenderColor[2] = g_iColorInactive[2]; }

        set_ent_rendering(eDynamite[DYNAMITE_ID_TRIGGER], kRenderFxGlowShell, iRenderColor[0], iRenderColor[1], iRenderColor[2], kRenderTransAlpha, 16)
        for ( new i = 0; i < eDynamite[DYNAMITE_ID_COUNT]; i ++ )
            set_ent_rendering(ArrayGetCell(eDynamite[DYNAMITE_ID_DYNAMITE], i), kRenderFxGlowShell, iRenderColor[0], iRenderColor[1], iRenderColor[2], kRenderTransAlpha, 16)
    }
    else if ( iAction == TARGET_GHOST )
    {
        set_ent_rendering(eDynamite[DYNAMITE_ID_TRIGGER], kRenderFxNone, 255, 255, 255, kRenderTransAlpha, g_eSettings[SETTING_GHOST_ALPHA])

        if ( bDynamiteExists )
            for ( new i = 0; i < eDynamite[DYNAMITE_ID_COUNT]; i ++ )
                set_ent_rendering(ArrayGetCell(eDynamite[DYNAMITE_ID_DYNAMITE], i), kRenderFxNone, 255, 255, 255, kRenderTransAlpha, g_eSettings[SETTING_GHOST_ALPHA])
    }
    else if ( iAction == TARGET_HIDE )
    {
        if ( !(eDynamite[DYNAMITE_FLAGS] & FLAG_EXPLODE) )
            set_ent_rendering(eDynamite[DYNAMITE_ID_TRIGGER], kRenderFxNone, 255, 255, 255, kRenderTransAlpha, 0)

        for ( new i = 0; i < eDynamite[DYNAMITE_ID_COUNT]; i ++ )
            set_ent_rendering(ArrayGetCell(eDynamite[DYNAMITE_ID_DYNAMITE], i), kRenderFxNone, 255, 255, 255, kRenderTransAlpha, 0)
    }
    else if ( iAction == TARGET_CLEAR )
    {
        set_ent_rendering(eDynamite[DYNAMITE_ID_TRIGGER], kRenderFxNone, 255, 255, 255, kRenderNormal, 255)
        if ( bDynamiteExists )
            for ( new i = 0; i < eDynamite[DYNAMITE_ID_COUNT]; i ++ )
                set_ent_rendering(ArrayGetCell(eDynamite[DYNAMITE_ID_DYNAMITE], i), kRenderFxNone, 255, 255, 255, kRenderNormal, 255)
    }
}

stock dynamiteSound(iEnt, iSound, bool:bPlayer = true)
{
    new szSample[64]
    switch( iSound )
    {
        case SOUND_MENU_NAV:    copy(szSample, charsmax(szSample), SOUND_NAV)
        case SOUND_MENU_REMOVE: copy(szSample, charsmax(szSample), SOUND_REMOVE)
        case SOUND_MENU_ALERT:  copy(szSample, charsmax(szSample), SOUND_ALERT)
    }

    if ( bPlayer )
        client_cmd(iEnt, "spk %s", szSample)
    else
        engfunc(EngFunc_EmitSound, iEnt, CHAN_ITEM, szSample, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

stock dynamiteReset()
{
    new eDynamite[DYNAMITE]
    for ( new i = 0; i < g_iDynamite; i ++ )
    {
        ArrayGetArray(g_aDynamite, i, eDynamite)
        eDynamite[DYNAMITE_NEXT_ACTIVE] = get_gametime()
        ArraySetArray(g_aDynamite, i, eDynamite)
    }
}

stock dynamiteGet(eDynamite[DYNAMITE], iEnt)
{
    if ( !isDynamite(iEnt) )
        return -1

    new iItem
    iItem = pev(iEnt, DYNAMITE_ARRAY_ITEM)
    if ( iItem < 0 || iItem >= g_iDynamite )
        return -1

    ArrayGetArray(g_aDynamite, iItem, eDynamite)
    return iItem
}

stock bool:isDynamite(iEnt)
{
    return pev_valid(iEnt) && pev(iEnt, pev_impulse) == DYNAMITE_KEY
}

stock dynamiteKill(eDynamite[DYNAMITE])
{
    if ( pev_valid(eDynamite[DYNAMITE_ID_TRIGGER]) )
        set_pev(eDynamite[DYNAMITE_ID_TRIGGER], pev_flags, pev(eDynamite[DYNAMITE_ID_TRIGGER], pev_flags) | FL_KILLME)

    new iDynamite
    for ( new i = 0; i < eDynamite[DYNAMITE_ID_COUNT]; i ++ )
    {
        iDynamite = ArrayGetCell(eDynamite[DYNAMITE_ID_DYNAMITE], i)
        if ( pev_valid(iDynamite) )
            set_pev(iDynamite, pev_flags, pev(iDynamite, pev_flags) | FL_KILLME)
    }
}

stock parseSetting(iType, szValue[], iValueLen, any:aOutput[], iOutputLength)
{
    switch ( iType )
    {
        case DTYPE_INT:
        {
            new szTok[MAX_VALUE_LENGTH], szTmp[MAX_VALUE_LENGTH], iCounter
            copy(szTmp, charsmax(szTmp), szValue)

            strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
            trim(szTok)
            while ( szTok[0] )
            {
                aOutput[iCounter ++] = str_to_num(szTok)

                strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
                trim(szTok)
            }
        }
        case DTYPE_FLOAT:
        {
            new szTok[MAX_VALUE_LENGTH], szTmp[MAX_VALUE_LENGTH], iCounter
            copy(szTmp, charsmax(szTmp), szValue)

            strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
            trim(szTok)
            while ( szTok[0] )
            {
                aOutput[iCounter ++] = str_to_float(szTok)

                strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
                trim(szTok)
            }
        }
        case DTYPE_FLAGS:
        {
            aOutput[0] = read_flags(szValue)
        }
        case DTYPE_ARRAY_STRING:
        {
            replace_all(szValue, iValueLen, "^"", " ")
            replace_all(szValue, iValueLen, "^^n", "^n")
            ArrayPushString(aOutput[0], szValue)
        }
        case DTYPE_ARRAY_SOUND:
        {
            ArrayPushString(aOutput[0], szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_STRING_MODEL:
        {
            copy(aOutput, iOutputLength, szValue)
            if ( !g_bFileWasRead ) precache_model(szValue)
        }
        case DTYPE_STRING_SOUND:
        {
            copy(aOutput, iOutputLength, szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_STRING_MODEL_ID:
        {
            if ( !g_bFileWasRead )
                aOutput[0] = precache_model(szValue)
        }
    }
}

stock EnableAction(id)
{
    if ( !g_ePlayerData[id][PDATA_DYNAMITE_ACTION] )
    {
        new eDynamite[DYNAMITE]
        for ( new i = 0; i < g_iDynamite; i ++ )
        {
            ArrayGetArray(g_aDynamite, i, eDynamite)
            if ( eDynamite[DYNAMITE_FLAGS] & FLAG_SHOW )
                continue

            dynamiteSelect(eDynamite, TARGET_GHOST)
        }

        g_ePlayerData[id][PDATA_DYNAMITE_ACTION] = true
        if ( ++ g_iActivePlayers == 1 )
            EnableForward()
    }
}

stock DisableAction(id)
{
    if ( g_ePlayerData[id][PDATA_DYNAMITE_ACTION] )
    {
        new eDynamite[DYNAMITE]
        for ( new i = 0; i < g_iDynamite; i ++ )
        {
            ArrayGetArray(g_aDynamite, i, eDynamite)
            if ( eDynamite[DYNAMITE_FLAGS] & FLAG_SHOW )
                continue

            dynamiteSelect(eDynamite, TARGET_HIDE)
        }

        g_ePlayerData[id][PDATA_DYNAMITE_ACTION] = false
        if ( -- g_iActivePlayers == 0 )
            DisableForward()
    }
}

stock EnableForward()
{
    EnableHamForward(g_iFwdPreThink)
    EnableHamForward(g_iFwdKilled)
}

stock DisableForward()
{
    DisableHamForward(g_iFwdPreThink)
    DisableHamForward(g_iFwdKilled)
}

stock EnableDynamite()
{
    EnableHamForward(g_iFwdUse)
    EnableHamForward(g_iFwdObjectCaps)
}

stock DisableDynamite()
{
    DisableHamForward(g_iFwdUse)
    DisableHamForward(g_iFwdObjectCaps)
}

stock LogConfigError(const iLine, const szText[], any:...)
{
    new szError[MAX_PLATFORM_PATH_LENGTH]
    vformat(szError, charsmax(szError), szText, 3)

    log_to_file(ERROR_FILE, "^nLine %d: %s", iLine, szError)
}