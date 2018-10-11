#!/usr/bin/env bash
#
# Script to utilize the UptimeRobot API to retrieve and work with monitors.
# Tronyx
set -eo pipefail
IFS=$'\n\t'

# Declare some variables
. Config/vars.cfg

# Edit these to finish setting up the script
# Specify UptimeRobot API key
if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
  apiKey="${travisApiKey}"
else
  # Enter your API key here
  apiKey=''
fi
# Specify the Discord/Slack webhook URL to send notifications to
if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
  webhookUrl="${travisWebhookUrl}"
else
  # Enter your webhook URL here
  webhookUrl=''
fi
# Set notifyAll to true for notification to apply for all running state as well
notifyAll='false'

# Log functions
#info()    { echo -e "$(date +"%F %T") ${blu}[INFO]${endColor}       $*" | tee -a "${LOG_FILE}" >&2 ; }
#warning() { echo -e "$(date +"%F %T") ${ylw}[WARNING]${endColor}    $*" | tee -a "${LOG_FILE}" >&2 ; }
#error()   { echo -e "$(date +"%F %T") ${org}[ERROR]${endColor}      $*" | tee -a "${LOG_FILE}" >&2 ; }
#fatal()   { echo -e "$(date +"%F %T") ${red}[FATAL]${endColor}      $*" | tee -a "${LOG_FILE}" >&2 ; exit 1 ; }

# Source usage function
. Config/usage.cfg

# Source cmdline function
. Config/cmdline.cfg

# Some basic checks
checks() {
# An option is provided
for arg in "${args[@]:-}"
do
  if [ -z "${arg}" ]; then
    usage
    exit
  fi
done
# Alert set to true, but webhook not defined
if [ "${webhookUrl}" = "" ] && [ "${webhook}" = "true" ]; then
  echo -e "${red}You didn't define your Discord webhook URL!${endColor}"
  read -rp 'Enter your webhook URL: ' url
  echo ''
  sed -i "12 s/webhookUrl='[^']*'/webhookUrl='${url}'/" "$0"
  webhookUrl="${url}"
else
  :
fi
}

# Create directory to neatly store temp files
create_dir() {
  mkdir -p "${tempDir}"
  #chmod 777 "${tempDir}"
}

# Cleanup temp files
cleanup() {
  rm -rf "${tempDir}"*.txt || true
}
trap 'cleanup' 0 1 2 3 6 14 15

# Check that provided API Key is valid
check_api_key() {
while [ "${apiKeyStatus}" = 'invalid' ]; do
  if [[ -z "${apiKey}" ]]; then
    echo -e "${red}You didn't define your API key in the script!${endColor}"
    echo ''
    read -rp 'Enter your API key: ' API
    echo ''
    sed -i "10 s/apiKey='[^']*'/apiKey='${API}'/" "$0"
    apiKey="${API}"
  else
    curl -s -X POST "${apiUrl}"getAccountDetails -d "api_key=${apiKey}" -d "format=json" > "${apiTestFullFile}"
    status=$(grep -Po '"stat":"[a-z]*"' "${apiTestFullFile}" |awk -F':' '{print $2}' |tr -d '"')
    if [ "${status}" = "fail" ]; then
      echo -e "${red}The API Key that you provided is not valid!${endColor}"
      sed -i "10 s/apiKey='[^']*'/apiKey=''/" "$0"
      apiKey=""
    elif [ "${status}" = "ok" ]; then
      sed -i "34 s/apiKeyStatus='[^']*'/apiKeyStatus='${status}'/" "$0"
      apiKeyStatus="${status}"
    fi
  fi
done
}

# Grab data for all monitors
get_data() {
  curl -s -X POST "${apiUrl}"getMonitors -d "api_key=${apiKey}" -d "format=json" > "${urMonitorsFullFile}"
}

# Create list of monitor IDs
get_monitors() {
  totalMonitors=$(grep -Po '"total":[!0-9]*' "${urMonitorsFullFile}" |awk -F: '{print $2}')
  if [ "${totalMonitors}" = '0' ]; then
    echo 'There are currently no monitors associated with your UptimeRobot account.'
    exit
  else
    grep -Po '"id":[!0-9]*' "${urMonitorsFullFile}" |tr -d '"id:' > "${urMonitorsFile}"
  fi
}

# Create individual monitor files
create_monitor_files() {
  while IFS= read -r monitor; do
    curl -s -X POST "${apiUrl}"getMonitors -d "api_key=${apiKey}" -d "monitors=${monitor}" -d "format=json" > "${tempDir}${monitor}".txt
  done < <(cat "${urMonitorsFile}")
}

# Create friendly output of all monitors
create_friendly_list() {
  true > "${friendlyListFile}"
  while IFS= read -r monitor; do
    grep -Po '"id":[!0-9]*|"friendly_name":["^][^"]*"|"status":[!0-9]*' "${tempDir}${monitor}".txt > "${tempDir}${monitor}"_short.txt
    friendlyName=$(grep friend "${tempDir}${monitor}"_short.txt |awk -F':' '{print $2}' |tr -d '"')
    status=$(grep status "${tempDir}${monitor}"_short.txt |awk -F':' '{print $2}' |tr -d '"')
    if [ "${status}" = '0' ]; then
      friendlyStatus="${ylw}Paused${endColor}"
    elif [ "${status}" = '1' ]; then
      friendlyStatus="${mgt}Not checked yet${endColor}"
    elif [ "${status}" = '2' ]; then
      friendlyStatus="${grn}Up${endColor}"
    elif [ "${status}" = '8' ]; then
      friendlyStatus="${org}Seems down${endColor}"
    elif [ "${status}" = '9' ]; then
      friendlyStatus="${red}Down${endColor}"
    fi
    echo -e "${lorg}${friendlyName}${endColor} - ID: ${lblu}${monitor}${endColor} - Status: ${friendlyStatus}" >> "${friendlyListFile}"
  done < <(cat "${urMonitorsFile}")
}

# Display friendly list of all monitors
display_all_monitors() {
  if [ -s "${friendlyListFile}" ]; then
    echo 'The following UptimeRobot monitors were found in your UptimeRobot account:'
    echo ''
    column -ts- "${friendlyListFile}"
    echo ''
  else
    :
    #echo 'There are currently no monitors associated with your UptimeRobot account.'
    echo ''
  fi
}

# Find all paused monitors
get_paused_monitors() {
  true > "${pausedMonitorsFile}"
  while IFS= read -r monitor; do
    grep -Po '"id":[!0-9]*|"friendly_name":["^][^"]*"|"status":[!0-9]*' "${tempDir}${monitor}".txt > "${tempDir}${monitor}"_short.txt
    friendlyName=$(grep friend "${tempDir}${monitor}"_short.txt |awk -F':' '{print $2}' |tr -d '"')
    status=$(grep status "${tempDir}${monitor}"_short.txt |awk -F':' '{print $2}' |tr -d '"')
    if [ "${status}" = '0' ]; then
      echo -e "${lorg}${friendlyName}${endColor} - ID: ${lblu}${monitor}${endColor}" >> "${pausedMonitorsFile}"
    else
      :
    fi
  done < <(cat "${urMonitorsFile}")
}

# Display list of all paused monitors
display_paused_monitors() {
  if [ -s "${pausedMonitorsFile}" ]; then
    echo 'The following UptimeRobot monitors are currently paused:'
    echo ''
    column -ts- "${pausedMonitorsFile}"
  else
    echo 'There are currently no paused UptimeRobot monitors.'
    echo ''
  fi
}

# Prompt user to unpause monitors after finding paused monitors
unpause_prompt() {
  echo ''
  echo -e "Would you like to unpause the paused monitors? (${grn}[Y]${endColor}es or ${red}[N]${endColor}o): "
  read -r unpausePrompt
  echo ''
  if ! [[ "$unpausePrompt" =~ ^(yes|y|no|n)$  ]]; then
    echo -e "${red}Please specify yes, y, no, or n.${endColor}"
  else
    :
  fi
}

# Prompt user to continue actioning valid monitors after finding invalid ones
invalid_prompt() {
  echo "Would you like to continue actioning the valid monitors below?"
  echo ''
  cat "${validMonitorsFile}"
  echo ''
  echo -e "${grn}[Y]${endColor}es or ${red}[N]${endColor}o):"
  read -r invalidPrompt
  echo ''
  if ! [[ "$invalidPrompt" =~ ^(yes|y|no|n)$  ]]; then
    echo -e "${red}Please specify yes, y, no, or n.${endColor}"
  else
    :
  fi
}

# Check for bad monitors
check_bad_monitors() {
  true > "${badMonitorsFile}"
  while IFS= read -r monitor; do
    if [[ $(grep -ic "${monitor}" "${friendlyListFile}") != "1" ]]; then
      if [[ "${monitor}" =~ ^[A-Za-z]+$ ]]; then
        echo -e "${lorg}${monitor}${endColor}" >> "${badMonitorsFile}"
      elif [[ "${monitor}" != ^[A-Za-z]+$ ]]; then
        echo -e "${lblu}${monitor}${endColor}" >> "${badMonitorsFile}"
      fi
    else
      :
    fi
  done < <(sed 's/\x1B\[[0-9;]*[JKmsu]//g' "${specifiedMonitorsFile}")
  if [ -s "${badMonitorsFile}" ]; then
    echo -e "${red}The following specified monitors are not valid:${endColor}"
    echo ''
    cat "${badMonitorsFile}"
    sed -i 's/\x1B\[[0-9;]*[JKmsu]//g' "${badMonitorsFile}"
    set +e
    grep -vxf "${badMonitorsFile}" "${specifiedMonitorsFile}" > "${validMonitorsTempFile}"
    true > "${validMonitorsFile}"
    if [ -s "${validMonitorsTempFile}" ]; then
      set -e
      while IFS= read -r monitor; do
        echo -e "${grn}${monitor}${endColor}" >> "${validMonitorsFile}"
      done < <(cat "${validMonitorsTempFile}")
      echo ''
      invalid_prompt
    elif [ ! -s "${validMonitorsTempFile}" ]; then
      echo ''
      echo "Please make sure you're specifying a valid monitor and try again."
      echo ''
      exit
    fi
  else
    :
  fi
}

# Convert friendly names to IDs
convert_friendly_monitors() {
  true > "${convertedMonitorsFile}"
  if [ -s "${validMonitorsFile}" ]; then
    cat "${validMonitorsFile}" > "${specifiedMonitorsFile}"
  else
    :
  fi
  while IFS= read -r monitor; do
    if [[ $(echo "${monitor}" |tr -d ' ') =~ [A-Za-z] ]]; then
      grep -Pi "${monitor}" "${friendlyListFile}" |awk -F ':' '{print $2}' |awk -F ' ' '{print $1}' >> "${convertedMonitorsFile}"
    else
      echo "${monitor}" >> "${convertedMonitorsFile}"
    fi
  done < <(sed 's/\x1B\[[0-9;]*[JKmsu]//g' "${specifiedMonitorsFile}")
}

# Pause all monitors
pause_all_monitors() {
  while IFS= read -r monitor; do
    grep -Po '"id":[!0-9]*|"friendly_name":["^][^"]*"|"status":[!0-9]*' "${tempDir}${monitor}".txt > "${tempDir}${monitor}"_short.txt
    friendlyName=$(grep friend "${tempDir}${monitor}"_short.txt |awk -F':' '{print $2}' |tr -d '"')
    echo "Pausing ${friendlyName}:"
    curl -s -X POST "${apiUrl}"editMonitor -d "api_key=${apiKey}" -d "id=${monitor}" -d "status=0"
    echo ''
  done < <(cat "${urMonitorsFile}")
}

# Pause specified monitors
pause_specified_monitors() {
  echo "${pauseType}" |tr , '\n' |tr -d '"' > "${specifiedMonitorsFile}"
  check_bad_monitors
  if [[ "${invalidPrompt}" = @(n|no) ]]; then
    exit
  else
    convert_friendly_monitors
  fi
  while IFS= read -r monitor; do
    grep -Po '"id":[!0-9]*|"friendly_name":["^][^"]*"|"status":[!0-9]*' "${tempDir}${monitor}".txt > "${tempDir}${monitor}"_short.txt
    friendlyName=$(grep friend "${tempDir}${monitor}"_short.txt |awk -F':' '{print $2}' |tr -d '"')
    echo "Pausing ${friendlyName}:"
    curl -s -X POST "${apiUrl}"editMonitor -d "api_key=${apiKey}" -d "id=${monitor}" -d "status=0"
    echo ''
  done < <(sed 's/\x1B\[[0-9;]*[JKmsu]//g' "${convertedMonitorsFile}")
}

# Unpause all monitors
unpause_all_monitors() {
  while IFS= read -r monitor; do
    grep -Po '"id":[!0-9]*|"friendly_name":["^][^"]*"|"status":[!0-9]*' "${tempDir}${monitor}".txt > "${tempDir}${monitor}"_short.txt
    friendlyName=$(grep friend "${tempDir}${monitor}"_short.txt |awk -F':' '{print $2}' |tr -d '"')
    echo "Unpausing ${friendlyName}:"
    curl -s -X POST "${apiUrl}"editMonitor -d "api_key=${apiKey}" -d "id=${monitor}" -d "status=1"
    echo ''
  done < <(cat "${urMonitorsFile}")
}

# Unpause specified monitors
unpause_specified_monitors() {
  echo "${unpauseType}" |tr , '\n' |tr -d '"' > "${specifiedMonitorsFile}"
  check_bad_monitors
  if [[ "${invalidPrompt}" = @(n|no) ]]; then
    exit
  else
    convert_friendly_monitors
  fi
  while IFS= read -r monitor; do
    grep -Po '"id":[!0-9]*|"friendly_name":["^][^"]*"|"status":[!0-9]*' "${tempDir}${monitor}".txt > "${tempDir}${monitor}"_short.txt
    friendlyName=$(grep friend "${tempDir}${monitor}"_short.txt |awk -F':' '{print $2}' |tr -d '"')
    echo "Unpausing ${friendlyName}:"
    curl -s -X POST "${apiUrl}"editMonitor -d "api_key=${apiKey}" -d "id=${monitor}" -d "status=1"
    echo ''
  done < <(sed 's/\x1B\[[0-9;]*[JKmsu]//g' "${convertedMonitorsFile}")
}

# Send Discord notification
send_notification() {
  if [ "${webhookUrl}" = "" ]; then
    echo -e "${org}You didn't define your Discord webhook, skipping notification.${endColor}"
  else
    if [ -s "${pausedMonitorsFile}" ]; then
      pausedTests=$(paste -s -d, "${pausedMonitorsFile}")
      curl -s -H "Content-Type: application/json" -X POST -d '{"content": "There are currently paused UptimeRobot monitors:\n\n'"${pausedTests}"'"}' ${webhookUrl}
    elif [ "${notifyAll}" = "true" ]; then
      curl -s -H "Content-Type: application/json" -X POST -d '{"content": "All UptimeRobot monitors are currently running."}' ${webhookUrl}
    fi
  fi
}

# Create a new monitor
create_monitor() {
  if [[ "${createType}" != 'http' && "${createType}" != 'ping' && "${createType}" != 'port' && "${createType}" != 'keyword' ]]; then
    echo -e "${red}You did not specify a valid monitor type!${endColor}"
    echo -e "${red}Your choices are http, ping, port, or keyword.${endColor}"
    echo ''
    exit
  else
    :
  fi
  if [ "${createType}" = 'http' ]; then
    newMonitorConfigFile="${newHttpMonitorConfigFile}"
  elif [ "${createType}" = 'ping' ]; then
    newMonitorConfigFile="${newPingMonitorConfigFile}"
  elif [ "${createType}" = 'port' ]; then
    newMonitorConfigFile="${newPortMonitorConfigFile}"
  elif [ "${createType}" = 'keyword' ]; then
    newMonitorConfigFile="${newKeywordMonitorConfigFile}"
  fi
  sed -i "s|\"api_key\": \"[^']*\"|\"api_key\": \"${apiKey}\"|" "${newMonitorConfigFile}"
  curl -s -X POST "${apiUrl}"newMonitor -d @"${newMonitorConfigFile}" --header "Content-Type: application/json"
  echo ''
}

# Display account statistics
get_stats() {
  echo 'Here are the basic statistics for your UptimeRobot account:'
  echo ''
  curl -s -X POST "${apiUrl}"getAccountDetails -d "api_key=${apiKey}" -d "format=json"
  echo ''
}

# Display all stats for single specified monitor
get_info() {
  echo "${infoType}" |tr , '\n' |tr -d '"' > "${specifiedMonitorsFile}"
  check_bad_monitors
  convert_friendly_monitors
  curl -s -X POST "${apiUrl}"getMonitors -d "api_key=${apiKey}" -d "monitors=$(sed 's/\x1B\[[0-9;]*[JKmsu]//g' ${convertedMonitorsFile})" -d "format=json"
  echo ''
}

# Display all alert contacts
get_alert_contacts() {
  echo 'The following alert contacts have been found for your UptimeRobot account:'
  echo ''
  curl -s -X POST "${apiUrl}"getAlertContacts -d "api_key=${apiKey}" -d "format=json"
  echo ''
}

# Reset monitors prompt
reset_prompt() {
  echo ''
  echo -e "${red}***WARNING*** This will reset ALL data for the specified monitors!!!${endColor}"
  echo -e "Are you sure you wish to continue? (${grn}[Y]${endColor}es or ${red}[N]${endColor}o): "
  read -r resetPrompt
  echo ''
  if ! [[ "$resetPrompt" =~ ^(yes|y|no|n)$  ]]; then
    echo -e "${red}Please specify yes, y, no, or n.${endColor}"
  else
    :
  fi
}

# Reset all monitors
reset_all_monitors() {
  reset_prompt
  while IFS= read -r monitor; do
    grep -Po '"id":[!0-9]*|"friendly_name":["^][^"]*"|"status":[!0-9]*' "${tempDir}${monitor}".txt > "${tempDir}${monitor}"_short.txt
    friendlyName=$(grep friend "${tempDir}${monitor}"_short.txt |awk -F':' '{print $2}' |tr -d '"')
    echo "Resetting ${friendlyName}:"
    curl -s -X POST "${apiUrl}"resetMonitor -d "api_key=${apiKey}" -d "id=${monitor}"
    echo ''
  done < <(cat "${urMonitorsFile}")
}

# Reset specified monitors
reset_specified_monitors() {
  echo "${resetType}" |tr , '\n' |tr -d '"' > "${specifiedMonitorsFile}"
  check_bad_monitors
  if [[ "${invalidPrompt}" = @(n|no) ]]; then
    exit
  else
    convert_friendly_monitors
  fi
  reset_prompt
  while IFS= read -r monitor; do
    grep -Po '"id":[!0-9]*|"friendly_name":["^][^"]*"|"status":[!0-9]*' "${tempDir}${monitor}".txt > "${tempDir}${monitor}"_short.txt
    friendlyName=$(grep friend "${tempDir}${monitor}"_short.txt |awk -F':' '{print $2}' |tr -d '"')
    echo "Resetting ${friendlyName}:"
    curl -s -X POST "${apiUrl}"resetMonitor -d "api_key=${apiKey}" -d "id=${monitor}"
    echo ''
  done < <(sed 's/\x1B\[[0-9;]*[JKmsu]//g' "${convertedMonitorsFile}")
}

# Delete monitors prompt
delete_prompt() {
  echo ''
  if [ "${deleteType}" = 'all' ]; then
    echo -e "${red}***WARNING*** This will delete ALL monitors in your account!!!${endColor}"
  elif [ "${deleteType}" != 'all' ]; then
    echo -e "${red}***WARNING*** This will delete the specified monitor from your account!!!${endColor}"
  fi
  echo -e "Are you sure you wish to continue? (${grn}[Y]${endColor}es or ${red}[N]${endColor}o): "
  read -r deletePrompt
  echo ''
  if ! [[ "$deletePrompt" =~ ^(yes|y|no|n)$  ]]; then
    echo -e "${red}Please specify yes, y, no, or n.${endColor}"
  else
    :
  fi
}

# Delete all monitors
delete_all_monitors() {
  delete_prompt
  while IFS= read -r monitor; do
    grep -Po '"id":[!0-9]*|"friendly_name":["^][^"]*"|"status":[!0-9]*' "${tempDir}${monitor}".txt > "${tempDir}${monitor}"_short.txt
    friendlyName=$(grep friend "${tempDir}${monitor}"_short.txt |awk -F':' '{print $2}' |tr -d '"')
    echo "Deleting ${friendlyName}:"
    curl -s -X POST "${apiUrl}"deleteMonitor -d "api_key=${apiKey}" -d "id=${monitor}"
    echo ''
  done < <(cat "${urMonitorsFile}")
}

# Delete specified monitors
delete_specified_monitors() {
  echo "${deleteType}" |tr , '\n' |tr -d '"' > "${specifiedMonitorsFile}"
  check_bad_monitors
  if [[ "${invalidPrompt}" = @(n|no) ]]; then
    exit
  else
    convert_friendly_monitors
  fi
  delete_prompt
  while IFS= read -r monitor; do
    grep -Po '"id":[!0-9]*|"friendly_name":["^][^"]*"|"status":[!0-9]*' "${tempDir}${monitor}".txt > "${tempDir}${monitor}"_short.txt
    friendlyName=$(grep friend "${tempDir}${monitor}"_short.txt |awk -F':' '{print $2}' |tr -d '"')
    echo "Deleting ${friendlyName}:"
    curl -s -X POST "${apiUrl}"deleteMonitor -d "api_key=${apiKey}" -d "id=${monitor}"
    echo ''
  done < <(sed 's/\x1B\[[0-9;]*[JKmsu]//g' "${convertedMonitorsFile}")
}

# Run functions
main() {
  cmdline "${args[@]:-}"
  checks
  create_dir
  check_api_key
  if [ "${list}" = 'true' ]; then
    get_data
    get_monitors
    create_monitor_files
    create_friendly_list
    display_all_monitors
  elif [ "${find}" = 'true' ]; then
    get_data
    get_monitors
    create_monitor_files
    get_paused_monitors
    display_paused_monitors
    if [ -s "${pausedMonitorsFile}" ]; then
      if [ "${prompt}" = 'false' ]; then
        :
      else
        unpause_prompt
          if [[ "$unpausePrompt" =~ ^(yes|y)$ ]]; then
            while IFS= read -r monitor; do
              friendlyName=$(grep "${monitor}" "${pausedMonitorsFile}" |awk '{print $1}')
              echo "Unpausing ${friendlyName}:"
              curl -s -X POST "${apiUrl}"editMonitor -d "api_key=${apiKey}" -d "id=${monitor}" -d "status=1"
              echo ''
            done < <(awk -F: '{print $2}' "${pausedMonitorsFile}" |sed 's/\x1B\[[0-9;]*[JKmsu]//g' |tr -d ' ')
          elif [[ "$unpausePrompt" =~ ^(no|n)$ ]]; then
            exit 1
          fi
      fi
    else
      :
    fi
    if [ "${webhook}" = 'true' ]; then
      send_notification
    fi
  elif [ "${pause}" = 'true' ]; then
    if [ "${pauseType}" = 'all' ]; then
      get_data
      get_monitors
      create_monitor_files
      pause_all_monitors
    elif [ "${pauseType}" != 'all' ]; then
      get_data
      get_monitors
      create_monitor_files
      create_friendly_list
      pause_specified_monitors
    fi
  elif [ "${unpause}" = 'true' ]; then
    if [ "${unpauseType}" = 'all' ]; then
      get_data
      get_monitors
      create_monitor_files
      unpause_all_monitors
    elif [ "${unpauseType}" != 'all' ]; then
      get_data
      get_monitors
      create_monitor_files
      create_friendly_list
      unpause_specified_monitors
    fi
  elif [ "${reset}" = 'true' ]; then
    if [ "${resetType}" = 'all' ]; then
      get_data
      get_monitors
      create_monitor_files
      reset_all_monitors
    elif [ "${resetType}" != 'all' ]; then
      get_data
      get_monitors
      create_monitor_files
      create_friendly_list
      reset_specified_monitors
    fi
  elif [ "${delete}" = 'true' ]; then
    if [ "${deleteType}" = 'all' ]; then
      get_data
      get_monitors
      create_monitor_files
      delete_all_monitors
    elif [ "${deleteType}" != 'all' ]; then
      get_data
      get_monitors
      create_monitor_files
      create_friendly_list
      delete_specified_monitors
    fi
  elif [ "${stats}" = 'true' ]; then
    get_stats
  elif [ "${create}" = 'true' ]; then
    create_monitor
  elif [ "${alerts}" = 'true' ]; then
    get_alert_contacts
  elif [ "${info}" = 'true' ]; then
    get_data
    get_monitors
    create_monitor_files
    create_friendly_list
    get_info
  fi
}

main