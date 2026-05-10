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
	local protocol = trim(node.protocol or "socks5")
	local username = trim(node.username)
	local password = trim(node.password)
	local ws_password = trim(node.ws_password)
	local kcp_password = trim(node.kcp_password)
	local service = "socks"
	local transport = "tcp"
	local tls_single = false
	local allow_auth = true

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
		allow_auth = false
	elseif protocol == "httpwss" then
		service = "http"
		transport = "wss"
		allow_auth = false
	elseif protocol == "socks5ws" then
		service = "socks"
		transport = "ws"
		allow_auth = false
	elseif protocol == "socks5wss" then
		service = "socks"
		transport = "wss"
		allow_auth = false
	elseif protocol == "httpkcp" then
		service = "http"
		transport = "kcp"
	elseif protocol == "socks5kcp" then
		service = "socks"
		transport = "kcp"
	end

	return {
		service = service,
		transport = transport,
		address = bracket_ipv6(server_host) .. ":" .. server_port,
		auth = (allow_auth and username ~= "" and password ~= "") and (username .. ":" .. password) or "",
		tls_single = tls_single,
		ws_password = ws_password,
		kcp_password = kcp_password
	}
end

local function custom_args(node, run_type, local_addr, local_port, server_host, server_port)
	local template = trim(node.custom_args)
	if template == "" then
		return nil
	end

	local parent = parent_parts(node, server_host, server_port)
	local values = {
		ipaddr = bracket_ipv6(server_host),
		port = server_port,
		local_addr = local_addr,
		local_port = local_port,
		parent_service = parent.service,
		parent_type = parent.transport,
		run_type = run_type
	}

	template = template:gsub("^%s*%S*proxy%s+", "")
	template = template:gsub("{([%w_]+)}", function(key)
		return values[key] or ""
	end)

	return trim(template)
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
	local protocol = trim(node.protocol or "socks5")

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

	if protocol == "custom" then
		return custom_args(node, run_type, local_addr, local_port, server_host, server_port) or ""
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
	if (parent.transport == "ws" or parent.transport == "wss") and parent.ws_password ~= "" then
		table.insert(args, "--parent-ws-password")
		table.insert(args, parent.ws_password)
	end
	if parent.transport == "kcp" and parent.kcp_password ~= "" then
		table.insert(args, "--kcp-key")
		table.insert(args, parent.kcp_password)
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
