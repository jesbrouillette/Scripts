wmi_query                 "SELECT CurrentDiskQueueLength,AvgDiskQueueLength FROM Win32_PerfFormattedData_PerfDisk_PhysicalDisk where Name='_Total'"
wmi_query_send_attributes ['CurrentDiskQueueLength','AvgDiskQueueLength']
collectd_plugin           'DiskQueueLength'
collectd_type             'queue_length'
collectd_type_instance    'total'
