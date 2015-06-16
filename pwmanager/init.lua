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
-- Version 0.3

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
		elseif password_list["password_list"] == nil and password_list.lu then
			errmsg = "The password file is in the old 'lookup' format. That isn't supported anymore."
			print(errmsg)
			password_list = nil
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
	local errmsg = ""
	local pw = nil
	local comment = nil
	-- first search for matching addresses, then for matching server names.
	for ind, content in pairs(password_list["password_list"]) do
		if content.user ~= nil and content.user ~= "" then
			if content.user == user then
				if content.address and content.port then
					if content.address == address and (content.port-port) == 0 then
						pw = content.password
						comment = content.comment
						return  {pw = pw, comment = comment, errmsg = errmsg, id = content.id}
					end
				elseif content.address or content.port then
					errmsg = "Invalid password list: found entry with incomplete address information : "
						.. (content.address and "" or
							"Address is nil, but port specified")
						.. (content.port and "" or
							"Port is nil, but address specified")
						.. (content.id and " (ID: ".. content.id..")" or "").. "."
					print(errmsg)
					return  {pw = pw, comment = comment, errmsg = errmsg}
				end
			end
		else
			errmsg = "Invalid password list: found entry with missing username."
			print(errmsg)
			return  {pw = pw, comment = comment, errmsg = errmsg}
		end
	end
	for ind, content in pairs(password_list["password_list"]) do
		if content.user == user then
			if content.name == selected_name then
				pw = content.password
				comment = content.comment
				return  {pw = pw, comment = comment, errmsg = errmsg, id = content.id}
			end
		end
	end
	errmsg = "Didn't find matching entry in password file."
	return  {pw = pw, comment = comment, errmsg = errmsg}
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
		if re.pw then
			print("Found matching entry in password list"..(re.id and " (ID: "..re.id..")" or "")..".")
			retpwd = re.pw
			success = true
		else
			errmsg = errmsg .. re.errmsg
		end
	else
		-- the user has already entered a password.
		success = true
	end
	return retusr, retpwd, success, errmsg
end