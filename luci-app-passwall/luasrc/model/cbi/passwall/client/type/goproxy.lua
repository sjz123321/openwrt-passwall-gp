local m, s = ...

local api = require "luci.passwall.api"

if not api.is_finded("proxy") and not api.finded_com("goproxy") then
	return
end

local type_name = "Goproxy"
local option_prefix = "goproxy_"

local function _n(name)
	return option_prefix .. name
end

s.fields["type"]:value(type_name, "Goproxy")

o = s:option(ListValue, _n("protocol"), translate("Protocol"))
o:value("http", "HTTP")
o:value("https", "HTTPS")
o:value("socks5", "SOCKS5")
o:value("socks5s", "SOCKS5S")
o:value("httpws", "HTTP WS")
o:value("httpwss", "HTTP WSS")
o:value("socks5ws", "SOCKS5 WS")
o:value("socks5wss", "SOCKS5 WSS")
o:value("httpkcp", "HTTP KCP")
o:value("socks5kcp", "SOCKS5 KCP")
o:value("custom", translate("Custom"))
o.default = "socks5"

o = s:option(Value, _n("address"), translate("Address (Support Domain Name)"))

o = s:option(Value, _n("port"), translate("Port"))
o.datatype = "port"

o = s:option(Value, _n("username"), translate("Username"))
o:depends({ [_n("protocol")] = "http" })
o:depends({ [_n("protocol")] = "https" })
o:depends({ [_n("protocol")] = "socks5" })
o:depends({ [_n("protocol")] = "socks5s" })
o:depends({ [_n("protocol")] = "httpkcp" })
o:depends({ [_n("protocol")] = "socks5kcp" })

o = s:option(Value, _n("password"), translate("Password"))
o.password = true
o:depends({ [_n("protocol")] = "http" })
o:depends({ [_n("protocol")] = "https" })
o:depends({ [_n("protocol")] = "socks5" })
o:depends({ [_n("protocol")] = "socks5s" })
o:depends({ [_n("protocol")] = "httpkcp" })
o:depends({ [_n("protocol")] = "socks5kcp" })

o = s:option(Value, _n("ws_password"), "WS Password")
o.password = true
o:depends({ [_n("protocol")] = "httpws" })
o:depends({ [_n("protocol")] = "httpwss" })
o:depends({ [_n("protocol")] = "socks5ws" })
o:depends({ [_n("protocol")] = "socks5wss" })

o = s:option(Value, _n("kcp_password"), "KCP Password")
o.password = true
o:depends({ [_n("protocol")] = "httpkcp" })
o:depends({ [_n("protocol")] = "socks5kcp" })

o = s:option(Value, _n("custom_args"), "Custom Command Args")
o.description = "Example: proxy http -T tcp -P {ipaddr}:{port} -t tcp -p :{local_port}"
o.placeholder = "proxy http -T tcp -P {ipaddr}:{port} -t tcp -p :{local_port}"
o:depends({ [_n("protocol")] = "custom" })

api.luci_types(arg[1], m, s, type_name, option_prefix)
