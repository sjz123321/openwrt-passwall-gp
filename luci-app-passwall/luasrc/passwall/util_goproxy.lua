module("luci.passwall.util_goproxy", package.seeall)

local api = require "luci.passwall.api"
local uci = api.uci

local function trim(value)
	return value and tostring(value):gsub("^%s+", ""):gsub("%s+$", "") or ""
end

local function quote(value)
	value = trim(value)
	return "'" .. value:gsub("'", "'\\''") .. "'"
end

local function bracket_ipv6(host)
	host = trim(host)
	if api.is_ipv6(host) and host:sub(1, 1) ~= "[" then
		return "[" .. host .. "]"
	end
	return host
end

local function parent_url(node, server_host, server_port)
	local protocol = trim(node.goproxy_protocol or "socks5")
	local username = trim(node.goproxy_username or node.username)
	local password = trim(node.goproxy_password or node.password)
	local auth = ""

	if username ~= "" and password ~= "" then
		auth = username .. ":" .. password .. "@"
	end

	return protocol .. "://" .. auth .. bracket_ipv6(server_host) .. ":" .. server_port
end

function gen_args(var)
	local node_id = var["-node"]
	if not node_id then
		return ""
	end

	local node = uci:get_all("passwall", node_id)
	local run_type = trim(var["-run_type"] or "socks")
	local local_addr = trim(var["-local_addr"] or "127.0.0.1")
	local local_port = trim(var["-local_port"])
	local server_host = trim(var["-server_host"] or node.address)
	local server_port = trim(var["-server_port"] or node.port)

	if local_port == "" or server_host == "" or server_port == "" then
		return ""
	end

	if run_type == "dns" then
		local dns_server = trim(var["-dns_server"])
		local args = {
			"dns",
			"-S", "socks",
			"-T", "tcp",
			"-P", quote(bracket_ipv6(server_host) .. ":" .. server_port),
			"-p", quote(local_addr .. ":" .. local_port)
		}
		if dns_server ~= "" then
			args[#args + 1] = "-q"
			args[#args + 1] = quote(dns_server)
		end
		return table.concat(args, " ")
	end

	local args = {
		"sps",
		"-P", quote(parent_url(node, server_host, server_port)),
		"-t", "tcp",
		"-p", quote(local_addr .. ":" .. local_port)
	}

	if run_type == "redir" then
		args[#args + 1] = "--redir"
	elseif run_type == "socks" then
		args[#args + 1] = "--disable-http"
	elseif run_type == "http" then
		args[#args + 1] = "--disable-socks"
	end

	return table.concat(args, " ")
end

_G.gen_args = gen_args

if arg[1] then
	local func = _G[arg[1]]
	if func then
		print(func(api.get_function_args(arg)))
	end
end
