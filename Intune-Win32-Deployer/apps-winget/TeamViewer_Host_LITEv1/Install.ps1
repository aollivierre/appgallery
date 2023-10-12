# & ".\TeamViewer_Host.msi" '/S' '/V"/qn IKEY=DI9OOWPZR7438NT2WCJF SKEY=9Y023lEkVeiiNjg3zxPGVfLIJvZk8wVrGHDqpigL HOST=api-d327e3d5.duosecurity.com AUTOPUSH=#1 FAILOPEN=#1 SMARTCARD=#1 RDPONLY=#0"'


# MSIEXEC.EXE /i "PATH_TO_MSI_FILE\TeamViewer_Host.msi" /qn CUSTOMCONFIGID=YOUR_CUSTOM_CONFIG_ID


MSIEXEC.EXE /i ".\TeamViewer_Host.msi" /qn CUSTOMCONFIGID=he26pyq APITOKEN=7757967-7qRfr5r4Voq9MRxS7UKZ ASSIGNMENTOPTIONS="--reassign" ASSIGNMENTOPTIONS="--group-id=""g176322730""" SETTINGSFILE=teamviewer_settings_export.tvopt



# powershell -Command "$ScriptRoot_DIR_1001='YourScriptRootDirPath'; $CUSTOMCONFIG_ID_1='ZZZZZZ'; $API_TOKEN_1='XXXXXXXXXXXXXXXXXXXXXXX'; $SETTINGSFILE_1=\"$ScriptRoot_DIR_1001\Settings\teamviewer_settings_export.tvopt\"; $MSI_FILE_HOST_PATH_1=\"$ScriptRoot_DIR_1001\msi\TeamViewerMSI\Host\TeamViewer_Host.msi\"; $Log_File_9='YourLogFilePath'; Start-Process 'msiexec.exe' -ArgumentList '/i', \"$MSI_FILE_HOST_PATH_1\", '/qn', \"CUSTOMCONFIGID=$CUSTOMCONFIG_ID_1\", \"APITOKEN=$API_TOKEN_1\", '/L*V', \"$Log_File_9\", '/promptrestart', 'ASSIGNMENTOPTIONS=--reassign', 'ASSIGNMENTOPTIONS=--group-id=g176322730', \"SETTINGSFILE=$SETTINGSFILE_1\""