-- Minetest µ-password manager.
-- Copyright 2015, est31 (https://github.com/est31).
--
--
--This program is free software; you can redistribute it and/or modify
--it under the terms of the GNU Lesser General Public License as published by
--the Free Software Foundation; either version 2.1 of the License, or
--(at your option) any later version.
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU Lesser General Public License for more details.
--
--You should have received a copy of the GNU Lesser General Public License along
--with this program; if not, write to the Free Software Foundation, Inc.,
--51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
--------------------------------------------------------------------------------
-- Version 0.1

pwmgr = {}

local pwfilename = core.setting_get("pwfile")
if pwfilename == nil then
	-- unfortunately, there is no core.get_path_user(), so we have to resort to this:
	pwfilename = core.get_modpath() .. DIR_DELIM .. ".." .. DIR_DELIM .. "client" .. DIR_DELIM .."password_list.txt"
	--print("password storage file from: "..pwfilename)
end

local function read_file()
	local password_list = {}
	local errmsg = nil
	local file = io.open(pwfilename, "r")
	if file then
		password_list = minetest.deserialize(file:read("*all"))
		file:close()
		if password_list == nil then
			errmsg = "There was an error in parsing the password file. Have you broken it?"
			print(errmsg)
		end
	else
		errmsg = "The password file wasn't at the position on "..pwfilename..",\n"..
			"or some other error occured while reading the file. "..
			"Note: '..' means directory up, so the file should not be placed into the mods directory!"
		print(errmsg)
		return nil, errmsg
	end
	return password_list, errmsg
end

--determine the id the user wanted.
local function check_uname(user, selected_name, address, port, password_list)
	
	local id = nil
	local errmsg = ""
	local check_addr = true
	if not password_list.lu[user] then
		errmsg = "no entry in table for user '"..user.."'."
		print(errmsg)
		return  {id = id, errmsg = errmsg}
	end
	if check_addr then
		local addr_entry = password_list.lu[user].addr_lu[address]
		if addr_entry then
			id = addr_entry[port]
		end
	end
	if selected_name and (id == nil) then
		id = password_list.lu[user].select_srv_lu[selected_name]
	end
	return {id = id, errmsg = errmsg}
end

function pwmgr.entered_handle(user, selected_name, pwd, addr, port)
	local retusr = user
	local retpwd = pwd
	local success = false
	local errmsg = ""
	if pwd == nil or pwd == "" then
		print("submitted empty password, checking passwordfile for a password...")
		local read_emsg = nil
		local password_list, read_emsg = read_file()
		if password_list == nil then
			errmsg = read_emsg
			return retusr, retpwd, false, errmsg
		end
		local re = check_uname(user, selected_name, addr, port, password_list)
		if re.id then
			if password_list.passwords[re.id] then
				print("Using the stored password with the ID ".. re.id .. ".")
				retpwd = password_list.passwords[re.id]
				success = true
			else
				errmsg = errmsg .. "ID ".. re.id .. " has no corresponding password, this is bad."
				print(errmsg)
			end
		else
			errmsg = errmsg .. re.errmsg
		end
	end
	return retusr, retpwd, success, errmsg
end