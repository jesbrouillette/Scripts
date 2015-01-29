ATTRIBUTES_TO_NAMES = {	'Name'				=> 'Name',
						'ThreadCount'		=> 'ThreadCount',
						'ProcessID'			=> 'ProcessID'}

processes = array.new
processes.push(REPLACE_PROCESSES)
processes.each do|process|
	wmi_query                 "SELECT #{ATTRIBUTES_TO_NAMES.keys.join(", ")} FROM Win32_Process WHERE Name LIKE #{process}"
	wmi_query_send_attributes ATTRIBUTES_TO_NAMES.keys
	collectd_type_instance    ATTRIBUTES_TO_NAMES
	collectd_plugin           'server'
	collectd_type             'gauge'
	collectd_units_factor     1
End