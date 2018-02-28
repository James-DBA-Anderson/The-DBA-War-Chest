#Install Chocolatey
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

choco feature enable -n allowGlobalConfirmation

# Basics

#choco install googlechrome 
choco install rdcman
choco install cmder
choco install 7zip.install
choco install notepadplusplus
choco install fileshredder

#choco install avastfreeantivirus 
#choco install avginternetsecurity


# Chat
#choco install skype
#choco install slack
#choco install microsoft-teams


# File Sync
choco install dropbox
choco install onedrive


# Development

choco install git
choco install poshgit 
choco install visualstudio2017community
choco install sql-server-management-studio
#choco install powerbi 

choco install visualstudiocode
choco install vscode-powershell
choco install vscode-mssql
choco install vscode-docker
choco install vscode-gitlens

choco install pester
#choco install docker
#choco install NugetPackageExplorer
#choco install vcredist2017
#choco install vim

#choco install agentransack
#choco install ag # The Silver Searcher

#choco install python
#choco install python2
#choco install pip
#choco install pycharm-community
#choco install anaconda3
#choco install minikube 

#choco install jdk9
#choco install maven


# Presenting

#choco install zoomit
#choco install nginx 


# Distractions

#choco install audacity
#choco install steam
choco install spotify 
