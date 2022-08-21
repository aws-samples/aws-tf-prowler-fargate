# Enter the group for the checks you would like Prowler to run, syntax is group=<GroupName>. You cannot do a scan on multiple groups. 1 group at a time. 
PROWLER_SCAN_GROUP="cislevel2"

# Enter the Output formats for your Prowler Report, syntax is format=csv or comma separated if selecting multiple formats format=json,csv,html
PROWLER_OUTPUT_FORMAT="csv"

export PROWLER_SCAN_GROUP

export PROWLER_OUTPUT_FORMAT


