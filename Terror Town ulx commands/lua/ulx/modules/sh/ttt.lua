--[=[-------------------------------------------------------------------------------------------
║                              Trouble in Terrorist Town Commands                              ║
                                    By: Skillz and Bender180                                   ║
║                              ╔═════════╗╔═════════╗╔═════════╗                               ║
║                              ║ ╔═╗ ╔═╗ ║║ ╔═╗ ╔═╗ ║║ ╔═╗ ╔═╗ ║                               ║
║                              ╚═╝ ║ ║ ╚═╝╚═╝ ║ ║ ╚═╝╚═╝ ║ ║ ╚═╝                               ║
║──────────────────────────────────║ ║────────║ ║────────║ ║───────────────────────────────────║
║──────────────────────────────────║ ║────────║ ║────────║ ║───────────────────────────────────║
║──────────────────────────────────╚═╝────────╚═╝────────╚═╝───────────────────────────────────║
║                  All code included is completely original or extracted                       ║
║            from the base ttt files that are provided with the ttt gamemode.                  ║
║                                                                                              ║
---------------------------------------------------------------------------------------------]=]
local CATEGORY_NAME = "TTT"

local gamemode_error="The current gamemode is not trouble in terrorest town"


--[[
	ulx.slaynr( calling_ply, target_plys, num_slay, should_slaynr )
	calling_ply		: PlayerObject	: The player who used the command
	target_plys		: PlayerObject	: The player(s) who will have the effects of the command applied to them.
	num_slay		: number		: Numer of rounds to add or remove the the target(s) slay total.
	should_slaynr	: boolean		: Hidden, differentiates between ulx.slaynr and, ulx.rslaynr.
	
	The slaynr command slays <target(s)> next round.
]]
function ulx.slaynr( calling_ply, target_plys, num_slay, should_slaynr )
		if not GetConVarString("gamemode") == "terrortown" then ULib.tsayError( calling_ply, gamemode_error, true ) else
		local affected_plys = {}
	
		for i=1, #target_plys do
			v = target_plys[ i ]
	
			if ulx.getExclusive( v, calling_ply ) then
				ULib.tsayError( calling_ply, ulx.getExclusive( v, calling_ply ), true )
			elseif num_slay == 0 then
				local slays_left = tonumber(v:GetPData("slaynr_slays")) or 0

				if slays_left == 0 then
					ulx.fancyLogAdmin( calling_ply, "#T will not be slain next round.", target_plys )
				elseif slays_left == 1 then
					ulx.fancyLogAdmin( calling_ply, "#T will be slain next round.", target_plys )
				elseif slays_left > 1 then
					ulx.fancyLogAdmin( calling_ply, "#T will be slain for the next ".. tostring(slays_left) .." rounds." , target_plys )
				end
			elseif num_slay < 0 then
				ULib.tsayError( calling_ply, "<times> must be a positive interger.", true )
			else
				current_slay = tonumber(v:GetPData("slaynr_slays")) or 0
				if not should_slaynr then
					new_slay =current_slay + num_slay
				else
					new_slay =current_slay - num_slay
				end

				if new_slay > 0 then
					v:SetPData("slaynr_slays", new_slay)
				else
					v:RemovePData("slaynr_slays")
				end

				table.insert( affected_plys, v )
			end

			local slays_left = tonumber(v:GetPData("slaynr_slays")) or 0
			local slays_removed = (current_slay - slays_left) or 0 

			if slays_removed > 0 and slays_left ==0 then
				chat_message = ("#A removed ".. slays_removed .." round(s) of slaying from #T. They/you will not be slain next round.")
			elseif slays_removed==0 then
				chat_message = ("#T will not be slain next round.")
			elseif slays_removed > 0 then
				chat_message = ("#A removed ".. slays_removed .." round(s) of slaying from #T.")
			elseif slays_left == 1 then
				chat_message = ("#A will slay #T next round.")
			elseif slays_left > 1 then
				chat_message = ("#A will slay #T for the next ".. tostring(slays_left) .." rounds.")
			end
		end
		ulx.fancyLogAdmin( calling_ply, chat_message, affected_plys )
	end
end
local slaynr = ulx.command( CATEGORY_NAME, "ulx slaynr", ulx.slaynr, "!slaynr" )
slaynr:addParam{ type=ULib.cmds.PlayersArg }
slaynr:addParam{ type=ULib.cmds.NumArg, default=1, hint="times, 0 to view", ULib.cmds.optional, ULib.cmds.round }
slaynr:addParam{ type=ULib.cmds.BoolArg, invisible=true }
slaynr:defaultAccess( ULib.ACCESS_ADMIN )
slaynr:help( "Slays target(s) for a number of rounds" )
slaynr:setOpposite( "ulx rslaynr", {_, _, _, true}, "!rslaynr" )

-------------------------------------------Helper functions---------------------------------------------
hook.Add("TTTBeginRound", "SlayPlayersNextRound", function()
	local affected_plys = {}

	for _,v in pairs(player.GetAll()) do
		local slays_left = tonumber(v:GetPData("slaynr_slays")) or 0

		if v:Alive() and slays_left > 0 then
			local slays_left=slays_left -1
			if slays_left == 0 then
				v:RemovePData("slaynr_slays")
			else
				v:SetPData("slaynr_slays", slays_left)
			end

			v:Kill()
			table.insert( affected_plys, v )
		end
	end

	local slay_message = ""
	for i=1, #affected_plys do

		slay_message = ( slay_message .. affected_plys[i]:Nick())
		if i > 1 then
			slay_message = ( slay_message .. ", " )
		end
	end

	local slay_message_context
	if #affected_plys == 1 then slay_message_context ="was" else slay_message_context ="were" end
	if #affected_plys ~= 0 then
		ULib.tsay(_, slay_message .. " ".. slay_message_context .." slain.")
	end
end)

hook.Add("PlayerSpawn", "Inform" ,function(ply)
	local slays_left = tonumber(ply:GetPData("slaynr_slays")) or 0
	local chat_message =""

	if slays_left == 1 then
		chat_message = (chat_message .. "You will be slain this round.")
	end
	if slays_left > 1 then
		chat_message = (chat_message .. " and ".. (slays_left - 1) .." round(s) after the current round.")
	end
	ply:ChatPrint(chat_message)
end)
-----------------------------------------------End-------------------------------------------------


--[[
	ulx.slay( calling_ply, target_plys )
	calling_ply		: PlayerObject	: The player who used the command
	target_plys		: PlayerObject	: The player(s) who will have the effects of the command applied to them.
	
	The ulx.vslaynr command returns the number of slays for the <target(s)>
]]
function ulx.vslaynr( calling_ply, target_plys )
	if not GetConVarString("gamemode") == "terrortown" then ULib.tsayError( calling_ply, gamemode_error, true ) else
		for i=1, #target_plys do
			v = target_plys[ i ]

			local slays_left = tonumber(v:GetPData("slaynr_slays")) or 0

			if slays_left == 0 then
				ulx.fancyLogAdmin( calling_ply,"#T will not be slain next round.", target_plys )
			elseif slays_left == 1 then
				ulx.fancyLogAdmin( calling_ply,"#T will be slain next round.", target_plys )
			elseif slays_left > 1 then
				ulx.fancyLogAdmin( calling_ply,"#T will be slain for the next ".. tostring(slays_left) .." rounds." , target_plys )
			end
		end
	end
end
local vslaynr = ulx.command( CATEGORY_NAME, "ulx vslaynr", ulx.vslaynr, "!vslaynr" )
vslaynr:addParam{ type=ULib.cmds.PlayersArg }
vslaynr:defaultAccess( ULib.ACCESS_ADMIN )
vslaynr:help( "Views the number of rounds the <target(s)> will be slain." )
-----------------------------------------------End-------------------------------------------------


--[[
	ulx.respawn( calling_ply, target_plys, should_silent )
	calling_ply		: PlayerObject	: The player who used the command
	target_plys		: PlayerObject	: The player(s) who will have the effects of the command applied to them.
	should_silent	: boolean		: Hidden, differentiates between ulx.respawn and, ulx.srespawn.
	
	The slaynr command slays <target(s)> next round.
]]
function ulx.respawn( calling_ply, target_plys, should_silent )
	if not GetConVarString("gamemode") == "terrortown" then ULib.tsayError( calling_ply, gamemode_error, true ) else
		local affected_plys = {}
	
		for i=1, #target_plys do
			local v = target_plys[ i ]
	
			if ulx.getExclusive( v, calling_ply ) then
				ULib.tsayError( calling_ply, ulx.getExclusive( v, calling_ply ), true )
			elseif GetRoundState() == 1 then
	    		ULib.tsayError( calling_ply, "Waiting for players!", true )
			elseif v:Alive() then
				ULib.tsayError( calling_ply, v:Nick() .. " is already alive!", true )
			else

				local corpse_credits, corpse_identified, corpse = corpse_getinfo(v)
				if not corpse_identified then new_credits = corpse_credits 
				elseif v:GetRole() ~= 0  then new_credits = GetConVarNumber("ttt_credits_starting") 
				else                          new_credits = 0 end

				if corpse then corpse_remove(v) end
				v:SetTeam( TEAM_TERROR )
				v:Spawn()
				v:SetCredits(new_credits)
				
				send_message(v, calling_ply, "You have been respawned.")
				table.insert( affected_plys, v )
			end
		end
		ulx.fancyLogAdmin( calling_ply, should_silent ,"#A respawned #T!", affected_plys )
	end
end
local respawn = ulx.command( CATEGORY_NAME, "ulx respawn", ulx.respawn, "!respawn" )
respawn:addParam{ type=ULib.cmds.PlayersArg }
respawn:addParam{ type=ULib.cmds.BoolArg, invisible=true }
respawn:defaultAccess( ULib.ACCESS_SUPERADMIN )
respawn:setOpposite( "ulx srespawn", {_, _, true}, "!srespawn" )
respawn:help( "Respawns <target(s)>." )

-------------------------------------------Helper functions---------------------------------------------
function corpse_getinfo(v)
	for _, ent in pairs( ents.FindByClass( "prop_ragdoll" )) do
		if ent.uqid == v:UniqueID() and IsValid(ent) then
			player_ent=ent
		end
	end
	if player_ent~=nil then
		corpse_credits    = CORPSE.GetCredits(player_ent, 0)
		corpse_identified = CORPSE.GetFound(player_ent, false)
		corpse=true
	else
		corpse = false
	end
	return corpse_credits, corpse_identified, corpse
end

function corpse_remove(v)
	for _, ent in pairs( ents.FindByClass( "prop_ragdoll" )) do
		if ent.uqid == v:UniqueID() and IsValid(ent) then
			player_ent=ent
		end
	end
	CORPSE.SetFound(player_ent, false)
	if string.find(player_ent:GetModel(), "zm_", 6, true) then
		player_ent:Remove()
	elseif player_ent.player_ragdoll then
		player_ent:Remove()
	end
end
-----------------------------------------------End-------------------------------------------------


--[[
	ulx.respawntp( calling_ply, target_ply, should_silent )
	calling_ply		: PlayerObject	: The player who used the command
	target_plys		: PlayerObject	: The player who will have the effects of the command applied to them.
	should_silent	: boolean		: Hidden, differentiates between ulx.respawn and, ulx.srespawn.
	
	The slaynr command slays <target(s)> next round.
]]
function ulx.respawntp( calling_ply, target_ply, should_silent )
	if not GetConVarString("gamemode") == "terrortown" then ULib.tsayError( calling_ply, gamemode_error, true ) else

		local affected_ply = {}	
		if not calling_ply:IsValid() then
			Msg( "You are the console, you can't teleport or teleport others since you can't see the world!\n" )
			return
		elseif ulx.getExclusive( target_ply, calling_ply ) then
			ULib.tsayError( calling_ply, ulx.getExclusive( target_ply, calling_ply ), true )
		elseif GetRoundState() == 1 then
	    		ULib.tsayError( calling_ply, "Waiting for players!", true )
		elseif target_ply:Alive() then
			ULib.tsayError( calling_ply, target_ply:Nick() .. " is already alive!", true )
		else
			local corpse_credits, corpse_identified, corpse = corpse_getinfo(target_ply)
			if not corpse_identified then new_credits = corpse_credits 
			elseif target_ply:GetRole() ~= 0  then new_credits = GetConVarNumber("ttt_credits_starting")
			else                          new_credits = 0 end
	
			local tracedata = {}
			tracedata.start  = calling_ply:GetPos()
			tracedata.endpos = calling_ply:GetPos() + calling_ply:EyeAngles():Forward() * 16384
			tracedata.filter = calling_ply
			local tr = util.TraceEntity( tracedata, target_ply )
			local hitpos = tr.HitPos

			if corpse then corpse_remove(target_ply) end
			target_ply:SetTeam( TEAM_TERROR )
			target_ply:Spawn()
			target_ply:SetCredits(new_credits)
					
			send_message(target_ply, calling_ply, "You have been teleported and respawned.")
		
			target_ply:SetPos( hitpos )
			table.insert( affected_ply, target_ply )
		end
		ulx.fancyLogAdmin( calling_ply, should_silent ,"#A teleported and respawned #T!", affected_ply )
	end
end
local respawntp = ulx.command( CATEGORY_NAME, "ulx respawntp", ulx.respawntp, "!respawntp" )
respawntp:addParam{ type=ULib.cmds.PlayerArg }
respawntp:addParam{ type=ULib.cmds.BoolArg, invisible=true }
respawntp:defaultAccess( ULib.ACCESS_SUPERADMIN )
respawntp:setOpposite( "ulx srespawntp", {_, _, true}, "!srespawntp" )
respawntp:help( "Respawns <target> to a specific location." )
-----------------------------------------------End-------------------------------------------------

ulx.target_role = {}
function updateRoles()
	table.Empty( ulx.target_role ) 
    
    table.insert(ulx.target_role,"traitor")
    table.insert(ulx.target_role,"detective")
    table.insert(ulx.target_role,"innocent")
end
hook.Add( ULib.HOOK_UCLCHANGED, "ULXRoleNamesUpdate", updateRoles )
updateRoles()
--[[
	ulx.force( calling_ply, target_plys, target_role, should_silent )
	calling_ply		: PlayerObject	: The player who used the command
	target_plys		: PlayerObject	: The player(s) who will have the effects of the command applied to them.
	target_role		: string		: The role that <target(s)> will become.
	should_silent	: boolean		: Hidden, differentiates between ulx.force and, ulx.sforce.
	
	The slaynr command slays <target(s)> next round.
]]
function ulx.force( calling_ply, target_plys, target_role, should_silent )
	if not GetConVarString("gamemode") == "terrortown" then ULib.tsayError( calling_ply, gamemode_error, true ) else

		local affected_plys = {}
		local starting_credits=GetConVarNumber("ttt_credits_starting")
	    if target_role ==  "traitor"   or target_role == "t" then role = ROLE_TRAITOR;   role_grammar="a ";  role_string = "traitor"   role_credits = starting_credits end
	    if target_role ==  "detective" or target_role == "d" then role = ROLE_DETECTIVE; role_grammar="a ";  role_string = "detective" role_credits = starting_credits end
	    if target_role ==  "innocent"  or target_role == "i" then role = ROLE_INNOCENT;  role_grammar="an "; role_string = "innocent" role_credits = 0                end
	    
	    for i=1, #target_plys do
			local v = target_plys[ i ]
			local current_role = v:GetRole()
	
			if ulx.getExclusive( v, calling_ply ) then
				ULib.tsayError( calling_ply, ulx.getExclusive( v, calling_ply ), true )
			elseif GetRoundState() == 1 or GetRoundState() == 2 then
	    		ULib.tsayError( calling_ply, "The round has not begun!", true )
			elseif role==nil then
	    		ULib.tsayError( calling_ply, "Invalid role:\"" .. target_role .. "\" specified", true )
			elseif not v:Alive() then
				ULib.tsayError( calling_ply, v:Nick() .. " is dead!", true )
			elseif current_role == role then
	    		ULib.tsayError( calling_ply, v:Nick() .. " is already " .. role_string, true )
			else
	            v:SetRole(role)
	            v:SetCredits(role_credits)
	            SendFullStateUpdate()

	            send_message(v, calling_ply, "Your role has been set to " .. role_string .. ".")
	            table.insert( affected_plys, v )
	        end
	    end
	    ulx.fancyLogAdmin( calling_ply, should_silent, "#A forced #T to become the role of " .. role_grammar .."#s.", affected_plys, role_string )
	end
end
local force = ulx.command( CATEGORY_NAME, "ulx force", ulx.force, "!force" )
force:addParam{ type=ULib.cmds.PlayersArg }
force:addParam{ type=ULib.cmds.StringArg, completes=ulx.target_role, hint="Role" }
force:addParam{ type=ULib.cmds.BoolArg, invisible=true }
force:defaultAccess( ULib.ACCESS_SUPERADMIN )
force:setOpposite( "ulx sforce", {_, _, _, true}, "!sforce" )
force:help( "Force <target(s) to become a specified role." )
-----------------------------------------------End-------------------------------------------------

-------------------------------------Global Helper functions---------------------------------------
function send_message(target_ply, calling_ply, message)
	if target_ply ~= calling_ply then
		target_ply:ChatPrint(message)
	end
end
-----------------------------------------------End-------------------------------------------------

------------------------------ Spectator ------------------------------
function ulx.tttafk( calling_ply, target_plys, should_unafk )

    local affected_plys = {}
    
    for i=1, #target_plys do
		local v = target_plys[ i ]
            if not should_unafk then
                v:ConCommand("ttt_spectator_mode 1")
                v:ConCommand("ttt_cl_idlepopup")
                v:ChatPrint("You have been moved to spectator due to inactivity by an admin.")
            else
                v:ConCommand("ttt_spectator_mode 0")
            end
    end
    
    if not should_unafk then
        ulx.fancyLogAdmin( calling_ply, "#A has forced #T into spectator mode", target_plys )
    else
        ulx.fancyLogAdmin( calling_ply, "#A has forced #T back to player.", target_plys )
    end
end

local tttafk = ulx.command( CATEGORY_NAME, "ulx afk", ulx.tttafk, "!afk" )
tttafk:addParam{ type=ULib.cmds.PlayersArg }
tttafk:addParam{ type=ULib.cmds.BoolArg, invisible=true }
tttafk:defaultAccess( ULib.ACCESS_SUPERADMIN )
tttafk:help( "Forces the target(s) to/from spectator." )
tttafk:setOpposite( "ulx unafk", {_, _, true}, "!unafk" )

 ------------------------------ Karma ------------------------------
function ulx.karma( calling_ply, target_plys, amount )
    
    for i=1, #target_plys do
		target_plys[ i ]:SetBaseKarma(amount)
        target_plys[ i ]:SetLiveKarma( amount )
    end
    
ulx.fancyLogAdmin( calling_ply, "#A set the karma for #T to #i", target_plys, amount )
end
local karma = ulx.command( CATEGORY_NAME, "ulx karma", ulx.karma, "!karma" )
karma:addParam{ type=ULib.cmds.PlayersArg }
karma:addParam{ type=ULib.cmds.NumArg, min=0, max = 10000, default=1000, hint="Karma", ULib.cmds.round }
karma:defaultAccess( ULib.ACCESS_SUPERADMIN )
karma:help( "Changes the target(s) Karma." )

 ------------------------------ Credits ------------------------------
function ulx.credits( calling_ply, target_plys, amount )
    
    for i=1, #target_plys do
        target_plys[ i ]:AddCredits(amount)
    end
    
ulx.fancyLogAdmin( calling_ply, true, "#A has given #T #i credits", target_plys, amount )
end
local acred = ulx.command("TTT Fun", "ulx credits", ulx.credits, "!credits")
acred:addParam{ type=ULib.cmds.PlayersArg }
acred:addParam{ type=ULib.cmds.NumArg, hint="Credits", ULib.cmds.round }
acred:defaultAccess( ULib.ACCESS_SUPERADMIN )
acred:help( "Gives the target(s) credits." )

------------------------------ Next Round  ------------------------------
ulx.next_round = {}
local function updateNextround()
	table.Empty( ulx.next_round ) -- Don't reassign so we don't lose our refs
    
    table.insert(ulx.next_round,"traitor") -- Add "traitor" to the table.
    table.insert(ulx.next_round,"detective") -- Add "detective" to the table.	
    table.insert(ulx.next_round,"unmark") -- Add "unmark" to the table.

end
hook.Add( ULib.HOOK_UCLCHANGED, "ULXNextRoundUpdate", updateNextround )
updateNextround() -- Init


local PlysMarkedForTraitor = {}
local PlysMarkedForDetective = {}
function ulx.nextround( calling_ply, target_plys, next_round )
    local affected_plys = {}
	local unaffected_plys = {}
    for i=1, #target_plys do
        local v = target_plys[ i ]
        local ID = v:UniqueID()
        
        if next_round == "traitor" then
            if PlysMarkedForTraitor[ID] == true or PlysMarkedForDetective[ID] == true then
                ULib.tsayError( calling_ply, "that player is already marked for the next round", true )
            else
                PlysMarkedForTraitor[ID] = true
                table.insert( affected_plys, v ) 
            end
        end
        if next_round == "detective" then
            if PlysMarkedForTraitor[ID] == true or PlysMarkedForDetective[ID] == true then
                ULib.tsayError( calling_ply, "that player is already marked for the next round!", true )
            else
                PlysMarkedForDetective[ID] = true
                table.insert( affected_plys, v ) 
            end
        end
        if next_round == "unmark" then
            if PlysMarkedForTraitor[ID] == true then
                PlysMarkedForTraitor[ID] = false
                table.insert( affected_plys, v )
            end
            if PlysMarkedForDetective[ID] == true then
                PlysMarkedForDetective[ID] = false
                table.insert( affected_plys, v )
            end
        end
    end    
        
    if next_round == "unmark" then
        ulx.fancyLogAdmin( calling_ply, true, "#A has unmarked #T ", affected_plys )
    else
        ulx.fancyLogAdmin( calling_ply, true, "#A marked #T to be #s next round.", affected_plys, next_round )
    end
end        
local nxtr= ulx.command( CATEGORY_NAME, "ulx nr", ulx.nextround, "!nr" )
nxtr:addParam{ type=ULib.cmds.PlayersArg }
nxtr:addParam{ type=ULib.cmds.StringArg, completes=ulx.next_round, hint="Next Round", error="invalid role \"%s\" specified", ULib.cmds.restrictToCompletes }
nxtr:defaultAccess( ULib.ACCESS_SUPERADMIN )
nxtr:help( "Forces the target to be a detective/traitor in the following round." )

local function TraitorMarkedPlayers()
	for k, v in pairs(PlysMarkedForTraitor) do
		if v then
			ply = player.GetByUniqueID(k)
			ply:SetRole(ROLE_TRAITOR)
            ply:AddCredits(GetConVarNumber("ttt_credits_starting"))
			ply:ChatPrint("You have been made a traitor by an admin this round.")
			PlysMarkedForTraitor[k] = false
		end
	end
end
hook.Add("TTTBeginRound", "Admin_Round_Traitor", TraitorMarkedPlayers)

local function DetectiveMarkedPlayers()
	for k, v in pairs(PlysMarkedForDetective) do
		if v then
			ply = player.GetByUniqueID(k)
			ply:SetRole(ROLE_DETECTIVE)
            ply:AddCredits(GetConVarNumber("ttt_credits_starting"))
            ply:Give("weapon_ttt_wtester")
			ply:ChatPrint("You have been made a detective by an admin this round.")
			PlysMarkedForDetective[k] = false
		end
	end
end
hook.Add("TTTBeginRound", "Admin_Round_Detective", DetectiveMarkedPlayers)

------------------------------ Community ------------------------------
--                                                                   -- 
--                          From Here Down                           -- 
--                All item are community contrubutions               --
--                                                                   --   
--                                                                   -- 
--                    Give Body Armor: centran                       -- 
--                                                                   -- 
-----------------------------------------------------------------------

------------------------------ Body Armor ----------------------------
function ulx.bodyarmor( calling_ply, target_plys )
        for i=1, #target_plys do
                target_plys[ i ]:GiveEquipmentItem(EQUIP_ARMOR)
        end
        ulx.fancyLogAdmin( calling_ply, "#A gave #T body armor", target_plys)
end
local armor = ulx.command( "TTT Fun", "ulx bodyarmor", ulx.bodyarmor, "!bodyarmor" )
armor:addParam{ type=ULib.cmds.PlayersArg }
armor:defaultAccess( ULib.ACCESS_ADMIN )
armor:help( "<user(s)> - Give target(s) body armor." )