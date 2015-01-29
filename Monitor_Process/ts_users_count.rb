def run  
    items = execute_wmi_query("Select LogonType from Win32_OperatingSystem WHERE LogonType='10'")
    (items).each { |count| }
 	@logger.debug("User Count: #{count}") 
	gauge('users', '', 'count', 'count', count)
 end