#!/bin/bash

# Nag-add.sh v0.3                              
# Jason Rhoades (c) 2024 MIT License
     
# Prompt for the directory where the configuration files are located
read -p "Enter the directory path for the cfg files: " cfg_directory

# Ensure the directory path ends with a slash
[[ "$cfg_directory" != */ ]] && cfg_directory="$cfg_directory/"

# Prompt for other user inputs
read -p "Enter General Service Type: " service
read -p "Enter Sub-Service Type: " sub_service
read -p "Enter Customer Name : " customer_name
read -p "Enter IP Address: " ip_address
read -p "Enter Check Type (http or ping): " check_type
read -p "Enter PID#: " pid

# Determine check command based on user input
if [ "$check_type" = "http" ]; then
    check_command="customer_check_http"
else
    check_command="customer_check_ping"
fi

# Append to hosts.cfg; A new file will be created if one does not already exist
echo "define host {
    use             customer-${sub_service}
    host_name	    $service-${pid}
    alias           $customer_name (${pid})
    check_command   $check_command
    contact_groups  level1
    address         $ip_address
}
" >> "${cfg_directory}hosts.cfg"

# Append to services.cfg; A new file will be created if one does not already exist
echo "define service {
    host_name       $service-${pid}
    use             $check_command
    check_command   $check_command
    contact_groups  level1
}
" >> "${cfg_directory}services.cfg"

# Hostgroup.cfg management 
# This cfg file is a bit different because each service it not a stazna unto itself 

# File path for hostgroups.cfg
hostgroups_cfg="${cfg_directory}hostgroups.cfg"

# Using "grep -q" is a slightly dirty way of checking to see if a file exists, but if it works it works 
if grep -q "members" "$hostgroups_cfg" >/dev/null 2<&1 ; then
    # If hostgroup.cfg exists, append the new member
    sed -i "/members/s/$/,$service-${pid}/" $hostgroups_cfg 
else

# If hostgroup.cfg doesn't exist, generate the initial stanza inside a new file
echo "define hostgroup {
    hostgroup_name  $sub_service
    alias           Worldspice Customer $subservice
    members         $service-${pid}
}
" >> "$hostgroups_cfg"
fi
# Yay! We did a thing. 
echo "Configuration updated successfully in $cfg_directory"

# Future Jason, this is past Jason. Get to adding some some error handling and formatting checks up in this bitch when you get a chance. 
 
