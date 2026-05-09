module("luci.passwall.util_goproxy", package.seeall)

local api = require "luci.passwall.api"
local uci = api.uci

local function trim(value)
	return value and tostring(value):gsub("^%s+", ""):gsub("%s+$", "") or ""
end

local function bracket_ipv6(host)
	host = trim(host)
	if api.is_ipv6(host) and host:sub(1, 1) ~= "[" then
		return "[" .. host .. "]"
	end
	return host
end

local function parent_parts(node, server_host, server_port)
	local protocol = trim(node.goproxy_protocol or "socks5")
	local username = trim(node.goproxy_username or node.username)
	local password = trim(node.goproxy_password or node.password)
	local service = "socks"
	local transport = "tcp"
	local tls_single = false

	if protocol == "http" then
		service = "http"
	elseif protocol == "https" then
		service = "http"
		transport = "tls"
		tls_single = true
	elseif protocol == "socks5s" then
		service = "socks"
		transport = "tls"
		tls_single = true
	elseif protocol == "httpws" then
		service = "http"
		transport = "ws"
	elseif protocol == "httpwss" then
		service = "http"
		transport = "wss"
	elseif protocol == "socks5ws" then
		service = "socks"
		transport = "ws"
	elseif protocol == "socks5wss" then
		service = "socks"
		transport = "wss"
	end

	return {
		service = service,
		transport = transport,
		address = bracket_ipv6(server_host) .. ":" .. server_port,
		auth = (username ~= "" and password ~= "") and (username .. ":" .. password) or "",
		tls_single = tls_single
	}
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
			"-P", bracket_ipv6(server_host) .. ":" .. server_port,
			"-p", local_addr .. ":" .. local_port
		}
		if dns_server ~= "" then
			table.insert(args, "-q")
			table.insert(args, dns_server)
		end
		return table.concat(args, " ")
	end

	local parent = parent_parts(node, server_host, server_port)
	local args = {
		"sps",
		"-S", parent.service,
		"-T", parent.transport,
		"-P", parent.address,
		"-t", "tcp",
		"-p", local_addr .. ":" .. local_port
	}
	if parent.auth ~= "" then
		table.insert(args, "-A")
		table.insert(args, parent.auth)
	end
	if parent.tls_single then
		table.insert(args, "--parent-tls-single")
	end

	if run_type == "redir" then
		table.insert(args, "--redir")
	elseif run_type == "socks" then
		table.insert(args, "--disable-http")
	elseif run_type == "http" then
		table.insert(args, "--disable-socks")
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
