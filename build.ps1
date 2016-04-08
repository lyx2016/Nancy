function Install-Dotnet
{
  & where.exe dotnet 2>&1 | Out-Null

  if(($LASTEXITCODE -ne 0) -Or ((Test-Path Env:\APPVEYOR) -eq $true))
  {
    Write-Host "Dotnet CLI not found - downloading latest version"
    & { iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/dotnet/cli/rel/1.0.0/scripts/obtain/install.ps1')) }
  }
}

function Restore-Packages
{
    param([string] $DirectoryName)
    & dotnet restore -v Error ("""" + $DirectoryName + """")
}

function Test-Projects
{
    param([string] $framework)
    & dotnet test -f $framework;

    if($LASTEXITCODE -ne 0)
    {
      exit 3
    }
}

########################
# THE BUILD!
########################

Push-Location $PSScriptRoot

# Install Dotnet CLI
Install-Dotnet

# Package restore
Get-ChildItem -Path . -Filter *.xproj -Recurse | ForEach-Object { Restore-Packages $_.DirectoryName }

# Test for full framework
Get-ChildItem -Path .\test -Filter *.xproj -Exclude Nancy.ViewEngines.Razor.Tests.Models.xproj -Recurse | ForEach-Object {
    Push-Location $_.DirectoryName
    Test-Projects "dnx451"
    Pop-Location
}

# Test for coreclr framework
#Get-ChildItem -Path .\test -Filter *.xproj -Exclude Nancy.ViewEngines.Razor.Tests.Models.xproj -Recurse | ForEach-Object {
#    Push-Location $_.DirectoryName
#    Test-Projects ""
#    Pop-Location
#}

Pop-Location
