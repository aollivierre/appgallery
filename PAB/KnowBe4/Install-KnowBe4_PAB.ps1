# Install with Command Line

# The command-line installation method allows you to install the PAB for Outlook on the computer that you’re using for the installation.

# To install the PAB for Outlook with this method, run Command Prompt as an administrator and copy and paste the following command:

# URL https://support.knowbe4.com/hc/en-us/articles/7142051893011#GPO

# PhishAlertButtonSetup.exe /q /ComponentArgs "KnowBe4 Phish Alert Button":"LICENSEKEY=""license_key"" PROXYSERVER=""hostname:port"""



# & "c:\code\KnowBe4\PhishAlertButtonSetup.exe" /q /ComponentArgs "KnowBe4 Phish Alert Button":"LICENSEKEY=""ENTER YOUR LICENSE KEY HERE"" PROXYSERVER=""hostname:port"""


# & "c:\code\KnowBe4\PhishAlertButtonSetup.exe" /q /ComponentArgs "KnowBe4 Phish Alert Button":"LICENSEKEY=license_key"


#The following command works fine in CMD. We just need format it to fit PowerShell syntax. i.e. pass parameters/switches as an array
& "c:\code\KnowBe4\PhishAlertButtonSetup.exe" /q /ComponentArgs "KnowBe4 Phish Alert Button":"LICENSEKEY=ENTER YOUR LICENSE KEY HERE"

# & "c:\code\KnowBe4\PhishAlertButtonSetup.exe" /q /ComponentArgs "KnowBe4 Phish Alert Button":"LICENSEKEY=""ENTER YOUR LICENSE KEY HERE"""






