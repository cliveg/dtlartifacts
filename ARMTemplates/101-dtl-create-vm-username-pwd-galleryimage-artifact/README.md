# Create a new MDT virtual machine in a DevTestLab instance.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fcliveg%2Fdtlartifacts%2Fmaster%2FRMTemplates%2F101-dtl-create-vm-username-pwd-galleryimage-artifact%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>


This deployment template is used with an Azure gallery image and custom Artifact repository.

This template creates a new virtual machine in a DevTestLab instance.
- A new user account is created using the username/password combination specified. 
- This user account is added to the local administrators group.
