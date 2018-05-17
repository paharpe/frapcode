@echo onSET host=sw444v1179
call "C:\Program Files\Puppet Labs\Bolt\bin\bolt.bat" file upload C:\Users\pharpe\Downloads\leeg.exe C:\Users\Administrator\Downloads\leegdest.exe --nodes winrm://%host% --user hosting -p --no-ssl-verify --configfile "C:\Program Files\Puppet Labs\Bolt\bin\bolt.yml"
pause
