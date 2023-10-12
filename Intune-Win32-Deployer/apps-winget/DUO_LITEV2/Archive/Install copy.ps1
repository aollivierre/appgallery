# Start-Process -FilePath (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "duo-win-login-4.2.2.exe") -ArgumentList "/S /V`" /qn IKEY=DI9OOWPZR7438NT2WCJF SKEY=9Y023lEkVeiiNjg3zxPGVfLIJvZk8wVrGHDqpigL HOST=api-d327e3d5.duosecurity.com AUTOPUSH=#1 FAILOPEN=#1 SMARTCARD=#1 RDPONLY=#0`""


# & (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "duo-win-login-4.2.2.exe") '/S /V" /qn IKEY=DI9OOWPZR7438NT2WCJF SKEY=9Y023lEkVeiiNjg3zxPGVfLIJvZk8wVrGHDqpigL HOST=api-d327e3d5.duosecurity.com AUTOPUSH=#1 FAILOPEN=#1 SMARTCARD=#1 RDPONLY=#0"'


# & (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "duo-win-login-4.2.2.exe") '/S'


# & (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "duo-win-login-4.2.2.exe") '/S', '/V', '/qn IKEY=DI9OOWPZR7438NT2WCJF SKEY=9Y023lEkVeiiNjg3zxPGVfLIJvZk8wVrGHDqpigL HOST=api-d327e3d5.duosecurity.com AUTOPUSH=#1 FAILOPEN=#1 SMARTCARD=#1 RDPONLY=#0'


# & (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "duo-win-login-4.2.2.exe") '/S /V "/qn IKEY=DI9OOWPZR7438NT2WCJF SKEY=9Y023lEkVeiiNjg3zxPGVfLIJvZk8wVrGHDqpigL HOST=api-d327e3d5.duosecurity.com.duosecurity.com AUTOPUSH=#1 FAILOPEN=#1 SMARTCARD=#1 RDPONLY=#0"'

& (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "duo-win-login-4.2.2.exe") '/S' '/V"/qn IKEY=DI9OOWPZR7438NT2WCJF SKEY=9Y023lEkVeiiNjg3zxPGVfLIJvZk8wVrGHDqpigL HOST=api-d327e3d5.duosecurity.com AUTOPUSH=#1 FAILOPEN=#1 SMARTCARD=#1 RDPONLY=#0"'



