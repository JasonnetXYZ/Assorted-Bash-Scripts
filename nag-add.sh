#!/bin/bash

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

# Append to hosts.cfg
echo "define host {
    use             customer-$sub_serivce
    host_name	    $service-${pid}
    alias           $customer_name
    check_command   $check_command
    contact_groups  level1
    address         $ip_address
}

" >> "${cfg_directory}hosts.cfg"

# Append to services.cfg
echo "define service {
    host_name       $service-${pid}
    use             $check_command
    check_command   $check_command
    contact_groups  level1
}

" >> "${cfg_directory}services.cfg"

# Update hostgroups.cfg

sed -i "/members/s/$/,$service-${pid}/" ${cfg_directory}hostgroups.cfg

echo "Configuration updated successfully in $cfg_directory"

