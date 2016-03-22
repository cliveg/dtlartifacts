@echo off
echo **Creating Custom VHD
CD "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\"
call DandISetEnv.bat
CD "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\"
call copype.cmd amd64 c:\winpe_amd64

diskpart /s C:\DeploymentShare\diskpart1.txt
echo y|call MakeWinPEMedia /UFD C:\WinPE_amd64 V:
copy C:\DeploymentShare\Boot\LiteTouchPE_x64.wim V:\sources\boot.wim /Y
diskpart /s C:\DeploymentShare\diskpart2.txt
dir c:\*.vhd
echo **Finished Creating Custom VHD

