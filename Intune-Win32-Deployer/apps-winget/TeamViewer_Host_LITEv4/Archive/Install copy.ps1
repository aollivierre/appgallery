# & ".\TeamViewer_Host.msi" '/S' '/V"/qn IKEY=DI9OOWPZR7438NT2WCJF SKEY=9Y023lEkVeiiNjg3zxPGVfLIJvZk8wVrGHDqpigL HOST=api-d327e3d5.duosecurity.com AUTOPUSH=#1 FAILOPEN=#1 SMARTCARD=#1 RDPONLY=#0"'


# MSIEXEC.EXE /i "PATH_TO_MSI_FILE\TeamViewer_Host.msi" /qn CUSTOMCONFIGID=YOUR_CUSTOM_CONFIG_ID


# MSIEXEC.EXE /i ".\TeamViewer_Host.msi" /qn CUSTOMCONFIGID=xxxxxx APITOKEN=7757967-xxxxxxxxxxxxx ASSIGNMENTOPTIONS="--reassign" ASSIGNMENTOPTIONS="--group-id=""g176322730""" SETTINGSFILE=teamviewer_settings_export.tvopt


# MSIEXEC.EXE /i ".\TeamViewer_Host.msi" /qn CUSTOMCONFIGID=xxxxxx



# powershell -Command "$ScriptRoot_DIR_1001='YourScriptRootDirPath'; $CUSTOMCONFIG_ID_1='ZZZZZZ'; $API_TOKEN_1='XXXXXXXXXXXXXXXXXXXXXXX'; $SETTINGSFILE_1=\"$ScriptRoot_DIR_1001\Settings\teamviewer_settings_export.tvopt\"; $MSI_FILE_HOST_PATH_1=\"$ScriptRoot_DIR_1001\msi\TeamViewerMSI\Host\TeamViewer_Host.msi\"; $Log_File_9='YourLogFilePath'; Start-Process 'msiexec.exe' -ArgumentList '/i', \"$MSI_FILE_HOST_PATH_1\", '/qn', \"CUSTOMCONFIGID=$CUSTOMCONFIG_ID_1\", \"APITOKEN=$API_TOKEN_1\", '/L*V', \"$Log_File_9\", '/promptrestart', 'ASSIGNMENTOPTIONS=--reassign', 'ASSIGNMENTOPTIONS=--group-id=g176322730', \"SETTINGSFILE=$SETTINGSFILE_1\""



# $customConfigId = "xxxxxx"
# $apiToken = "7757967-xxxxxxxxxxx"
# $groupId = "g176322730"
# $settingsFile = "teamviewer_settings_export.tvopt"
# $msiFilePath = ".\TeamViewer_Host.msi"

# Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", $msiFilePath, "/qn", "CUSTOMCONFIGID=$customConfigId", "APITOKEN=$apiToken", "ASSIGNMENTOPTIONS=--reassign", "ASSIGNMENTOPTIONS=--group-id=`"$groupId`"", "SETTINGSFILE=$settingsFile"







# start /wait MSIEXEC.EXE /i "C:\Code\TV\TeamViewer_Host_LITEv1\TeamViewer_Host.msi" /qn CUSTOMCONFIGID=he26pyq



# Start-Process -FilePath "MSIEXEC.EXE" -ArgumentList '/i', 'C:\Code\TV\TeamViewer_Host_LITEv1\TeamViewer_Host.msi', '/qn', 'CUSTOMCONFIGID=he26pyq' -Wait


# Start-Process -FilePath "MSIEXEC.EXE" -ArgumentList '/i', 'C:\Code\TV\TeamViewer_Host_LITEv1\TeamViewer_Host.msi', '/qn', 'CUSTOMCONFIGID=he26pyq', 'ASSIGNMENTOPTIONS=--reassign', 'ASSIGNMENTOPTIONS=--group-id="g176322730"', 'SETTINGSFILE=C:\Code\TV\TeamViewer_Host_LITEv1\teamviewer_settings_export.tvopt' -Wait



# Start-Process -FilePath "MSIEXEC.EXE" -ArgumentList '/i', '.\TeamViewer_Host.msi', '/qn', 'CUSTOMCONFIGID=he26pyq', 'ASSIGNMENTOPTIONS=--reassign', 'ASSIGNMENTOPTIONS=--group-id="g176322730"', 'SETTINGSFILE=.\teamviewer_settings_export.tvopt' -Wait


# Start-Process -FilePath "MSIEXEC.EXE" -ArgumentList '/i', 'TeamViewer_Host.msi', '/qn', 'CUSTOMCONFIGID=he26pyq', 'ASSIGNMENTOPTIONS=--reassign', 'ASSIGNMENTOPTIONS=--group-id="g176322730"', 'SETTINGSFILE=teamviewer_settings_export.tvopt' -Wait



$msiPath = Resolve-Path ".\TeamViewer_Host.msi"
$settingsFilePath = Resolve-Path ".\teamviewer_settings_export.tvopt"

# Start-Process -FilePath "MSIEXEC.EXE" -ArgumentList "/i", $msiPath, "/qn", "CUSTOMCONFIGID=he26pyq", "ASSIGNMENTOPTIONS=--reassign", "ASSIGNMENTOPTIONS=--group-id=""g176322730""", "SETTINGSFILE=$settingsFilePath" -Wait
Start-Process -FilePath "MSIEXEC.EXE" -ArgumentList "/i", $msiPath, "/qn", "CUSTOMCONFIGID=he26pyq", "SETTINGSFILE=$settingsFilePath" -Wait


# "C:\Program Files (x86)\TeamViewer\TeamViewer.exe" assignment --id YOUR_ASSIGNMENT_ID
# "C:\Program Files (x86)\TeamViewer\TeamViewer.exe" assignment --id 0001CoABChB_v5MwSa8R7o8P_rKIEvk7EigIACAAAgAJACy2Zi09RdZnXEaaCiwaca_tqmQwD_Jl-MczmvzG-wSzGkB8W7SmmlegzfK9r1qmVL39mYxWpE434_lZbmR7-_u8wLAjko6jO8YAVCA91RlMOsBp9NUzSkwYqzplaRat5iR7IAEQoJnZ0wY=


Start-Sleep -Seconds 30

# $id = "0001CoABChB_v5MwSa8R7o8P_rKIEvk7EigIACAAAgAJACy2Zi09RdZnXEaaCiwaca_tqmQwD_Jl-MczmvzG-wSzGkB8W7SmmlegzfK9r1qmVL39mYxWpE434_lZbmR7-_u8wLAjko6jO8YAVCA91RlMOsBp9NUzSkwYqzplaRat5iR7IAEQoJnZ0wY="  # Replace with your actual ID
# & "C:\Program Files (x86)\TeamViewer\TeamViewer.exe" assignment --id $id
# & "C:\Program Files (x86)\TeamViewer\TeamViewer.exe" assignment --id "0001CoABChB_v5MwSa8R7o8P_rKIEvk7EigIACAAAgAJACy2Zi09RdZnXEaaCiwaca_tqmQwD_Jl-MczmvzG-wSzGkB8W7SmmlegzfK9r1qmVL39mYxWpE434_lZbmR7-_u8wLAjko6jO8YAVCA91RlMOsBp9NUzSkwYqzplaRat5iR7IAEQoJnZ0wY="



# $id = "0001CoABChB_v5MwSa8R7o8P_rKIEvk7EigIACAAAgAJACy2Zi09RdZnXEaaCiwaca_tqmQwD_Jl-MczmvzG-wSzGkB8W7SmmlegzfK9r1qmVL39mYxWpE434_lZbmR7-_u8wLAjko6jO8YAVCA91RlMOsBp9NUzSkwYqzplaRat5iR7IAEQoJnZ0wY"  # Replace with your actual ID
Start-Process -FilePath "C:\Program Files (x86)\TeamViewer\TeamViewer.exe" -ArgumentList "assignment", "--id", "0001CoABChB_v5MwSa8R7o8P_rKIEvk7EigIACAAAgAJACy2Zi09RdZnXEaaCiwaca_tqmQwD_Jl-MczmvzG-wSzGkB8W7SmmlegzfK9r1qmVL39mYxWpE434_lZbmR7-_u8wLAjko6jO8YAVCA91RlMOsBp9NUzSkwYqzplaRat5iR7IAEQoJnZ0wY"

