@echo off
echo **Creating Custom VHD
del d:\mdtazure.vhd
rmdir c:\winpe_amd64 /s /q

CD "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\"

echo **DandI
call DandISetEnv.bat

CD "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\"
echo copype
call copype.cmd amd64 c:\winpe_amd64

echo **diskpart1
diskpart /s C:\DeploymentShare\diskpart1.txt

echo **MakeWinPEMedia
echo y|call MakeWinPEMedia /UFD C:\WinPE_amd64 V:

echo **Copy
copy C:\DeploymentShare\Boot\LiteTouchPE_x64.wim V:\sources\boot.wim

echo **Diskpart2
pause
diskpart /s %0\..\diskpart2.txt

echo **Finished
pause