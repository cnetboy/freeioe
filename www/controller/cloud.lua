local skynet = require 'skynet'
local snax = require 'skynet.snax'
local dc = require 'skynet.datacenter'
local lfs = require 'lfs'

return {
	get = function(self)
		if lwf.auth.user == 'Guest' then
			self:redirect('/user/login')
		else
			local get = ngx.req.get_uri_args()
			--local cloud = snax.uniqueservice('cloud')
			local cfg = dc.get('CLOUD')
			local sys = dc.get('SYS')
			local edit_sn = lfs.attributes("/etc/profile.d/echo_sn.sh", "mode") == 'file'
			lwf.render('cloud.html', {sys=sys, cfg=cfg, nowtime=skynet.time(), edit_enable=get.edit_enable, edit_sn=edit_sn})
		end
	end,
	post = function(self)
		if lwf.auth.user == 'Guest' then
			self:redirect('/user/login')
			return
		end

		ngx.req.read_body()
		local post = ngx.req.get_post_args()
		local action = post.action
		if action == 'enable' then
			local option = post.option
			local info = _("Action is accepted")
			local id = 'from_web'
			local cloud = snax.uniqueservice('cloud')
			if option == 'data' then
				--print(option, post.enable=='true')
				cloud.post.enable_data(id, post.enable == 'true')
			elseif option == 'stat' then
				--print(option, post.enable=='true')
				cloud.post.enable_stat(id, post.enable == 'true')
			elseif option == 'log' then
				--print(option, tonumber(post.enable) or 0)
				cloud.post.enable_log(id, tonumber(post.enable) or 0)
			elseif option == 'comm' then
				--print(option, tonumber(post.enable) or 0)
				cloud.post.enable_comm(id, tonumber(post.enable) or 0)
			elseif option == 'event' then
				cloud.post.enable_event(id, tonumber(post.enable) or -1)
			else
				info = _("Action %s is not allowed", option)
			end
			ngx.print(info)
		end
		if action == 'cloud' or action == 'mqtt' then
			local option = post.option
			local value = post.value
			if string.upper(option) == 'DATA_UPLOAD_PERIOD' then
				value = math.floor(tonumber(value))
				if value > 0 and value < 1000 then
					ngx.print(_('The upload period cannot be less than 1000 ms (one second)'))
				end
			end
			if string.upper(option) == 'COV_TTL' then
				value = math.floor(tonumber(value))
				if value < 60 then
					ngx.print(_('The COV TTL cannot be less than 60 seconds'))
				end
			end
			if string.upper(option) == 'ID' then
				if string.len(tostring(value) or '') == 0 then
					value = nil
				end
			end
			--print(option, value)
			dc.set('CLOUD', string.upper(option), value)
			ngx.print(_('Cloud option is changed, you need restart system to apply changes!'))
		end
	end
}
