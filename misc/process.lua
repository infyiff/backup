local getinfo = getinfo or (debug and debug.getinfo)
local setthreadidentity = setthreadidentity or (syn and syn.set_thread_identity) or syn_context_set or setthreadcontext
local getgc = getgc or get_gc_objects
local hk = {}
local dt = nil
local kl = nil
setthreadidentity(2)
for _, v in getgc(true) do
	if typeof(v) == "table" then
		local df = rawget(v, "Detected")
		local kf = rawget(v, "Kill")
		if typeof(df) == "function" and not dt then
			dt = df
			hookfunction(dt, function() return true end)
			table.insert(hk, dt)
		end
		if rawget(v, "Variables") and rawget(v, "Process") and typeof(kf) == "function" and not kl then
			kl = kf
			hookfunction(kl, function() end)
			table.insert(hk, kl)
		end
	end
end
local Old = nil
Old = hookfunction(getrenv().debug.info, newcclosure(function(o, ...)
	if dt and o == dt then return coroutine.yield(coroutine.running()) end
	return Old(o, ...)
end))
setthreadidentity(8)
