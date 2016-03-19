@echo off
echo Creating Custom VHD
copype.cmd amd64 c:\winpe_amd64
diskpart /s %0\..\diskpart1.txt
MakeWinPEMedia /UFD C:\WinPE_amd64 V:
copy C:\DeploymentShare\Boot\LiteTouchPE_x64.wim V:\sources\boot.wim
diskpart /s %0\..\diskpart2.txt
echo Finished
pause