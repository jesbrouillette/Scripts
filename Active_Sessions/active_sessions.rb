# true:: Always return true
def run  
    items = execute_wmi_query("SELECT ActiveSessions FROM Win32_PerfFormattedData_LocalSessionManager_TerminalServices")
    for item in items do  
        value=item.ActiveSessions
	if is_number?(value)
	    @logger.debug("Total Active Session: #{value}") 
	    gauge('activesessions', 'plugin', 'gauge', 'activesessions', value)
	else
	    @logger.debug("The returned ActiveSessions(#{value}) is not a number") 
	end
    end
end