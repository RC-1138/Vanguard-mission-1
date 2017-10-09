["Setup Timer", "Allows the mission maker to restrict the AO of a side for a set amount of time.", "Olsen"] call FNC_RegisterModule;

#define ADDSETUPMARKER(SIDE, TIME, NAME) \
if !(markerType NAME == "") then { \
	_markers set [count _markers, [SIDE, TIME, NAME]]; \
} else { \
	_temp = format ["Setup timer module:<br></br>Warning marker ""%1"", in file ""modules\setup timer\settings.sqf"" does not exist.", NAME]; \
	_temp call FNC_DebugMessage; \
};

private _isSP = false;
if (!isMultiplayer) then {
    _isSP = true;
    "Setup Timer: Singleplayer session detected, this module will function only in multiplayer." call FNC_DebugMessage;
};

if (isServer) then {
    [] spawn {
        //waitUntil {time > 0};
        //FW_setup_start_time = serverTime;
        //publicVariable "FW_setup_start_time";
    };
};

if (!isDedicated && _isSP) then {
	
	private ["_markers", "_pos", "_timeLeft", "_string", "_displayed"];

	_markers = [];

	#include "settings.sqf"
    
    [{!isNull (findDisplay 46)},
    {
        (findDisplay 46) displayAddEventHandler ["MouseMoving", {
            if (serverCommandAvailable "#kick") then {
                FW_IsAdmin = true;
            } else {
                FW_IsAdmin = false;
            };
        }];
    }] call CBA_fnc_WaitUntilAndExecute;
    
    private _action = ["Start_cd", "Start 5 min countdown", "", {
        FW_setup_start_time = serverTime;
        publicVariable "FW_setup_start_time";
    }, {!isNil "FW_IsAdmin" && {FW_IsAdmin}}] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions"], _action] call ace_interact_menu_fnc_addActionToObject;
    
    _action = ["end_red", "End mission, winner: MSV", "", {
        "MSV VICTORY <br/> BP Anna successfully defended." remoteExecCall ["FNC_EndMission", 2];
    }, {!isNil "FW_IsAdmin" && {FW_IsAdmin}}] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions"], _action] call ace_interact_menu_fnc_addActionToObject;
    
    _action = ["end_blu", "End mission, winner: US Army", "", {
        "US ARMY VICTORY <br/> OBJ Rifles has been seized." remoteExecCall ["FNC_EndMission", 2];
    }, {!isNil "FW_IsAdmin" && {FW_IsAdmin}}] call ace_interact_menu_fnc_createAction;
    [player, 1, ["ACE_SelfActions"], _action] call ace_interact_menu_fnc_addActionToObject;

	
	if ((count _markers) > 0) then {
	
		[_markers] spawn {
			
			_marker = [];
			_displayed = false;
            
			waitUntil {!isNil "FW_setup_start_time"};
            _startTime = FW_setup_start_time;
            //we are checking for a bug described on serverTime wiki page
            //bugged value is usually around 400 000
            if (abs (FW_setup_start_time - serverTime) > 100000) then { 
                _startTime = serverTime;
                FW_setup_start_time = serverTime; //client time is used instead, according to wiki it's always correct
                //we send it across network. Possible issue: multiple clients send it at the same time
                //and increase network traffic. Shouldn't be too bad because data is small.
                publicVariable "FW_setup_start_time";
                systemchat "Setup Timer: Detected desynchronized server and client clock, using client's time instead.";
            };
            
			{
				if (((_x select 0) == (side player)) && [(vehicle player), (_x select 2)] call FNC_InArea) then {
				
					_marker = [(_x select 1), (_x select 2)];
					
				} else {
				
					(_x select 2) setMarkerAlphaLocal 0;
					
				};
				
			} forEach (_this select 0);
			
			_pos = getPosATL (vehicle player);
			
			while {(count _marker) > 0} do {
			
				_vehicle = (vehicle player);
			
				if ([_vehicle, (_marker select 1)] call FNC_InArea) then {
				
					_pos = getPosATL _vehicle;
					
				} else {
				
					_vehicle setPos _pos;
					
				};
				
				_timeLeft = round(_startTime + (_marker select 0) - serverTime);
				
				if (_timeLeft < 0) then {
					
					_timeLeft = 0;
					
				};
				
				if (_timeLeft > 0 && !_displayed) then {
					_displayed = true;
					missionNamespace setVariable ["FW_ST_TimeLeft", _timeLeft];
					cutRsc ["RscSetupTimer", "PLAIN", 0.5, false];
				};
				
				if (_timeLeft == 0) then {
				
					(_marker select 1) setMarkerAlphaLocal 0;
					_marker = [];
					SETUP_RUNNING = false;
				};
				
				sleep(0.1);
				
			};
		};
	};
};