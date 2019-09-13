# Get the location of the script, that is assumed to be the install prefix
$installPrefix = $PSScriptRoot

Write-Host 'Removing ' + $installPrefix + ' from the CMAKE_PREFIX_PATH User enviroment variable.'
$currVar = [System.Environment]::GetEnvironmentVariable('CMAKE_PREFIX_PATH', 'User');
$newVar = ($currVar.Split(';') | Where-Object { $_ -ne $installPrefix }) -join ';';
[System.Environment]::SetEnvironmentVariable('CMAKE_PREFIX_PATH', $newVar, 'User');

Write-Host 'Removing ' + $installPrefix + '\debug from the CMAKE_PREFIX_PATH User enviroment variable.'
$currVar = [System.Environment]::GetEnvironmentVariable('CMAKE_PREFIX_PATH', 'User');
$newVar = ($currVar.Split(';') | Where-Object { $_ -ne $installPrefix + '\debug' }) -join ';';
[System.Environment]::SetEnvironmentVariable('CMAKE_PREFIX_PATH', $newVar, 'User');

Write-Host 'Removing ' + $installPrefix + '\debug\bin from the Path User enviroment variable.'
$currVar = [System.Environment]::GetEnvironmentVariable('Path', 'User');
$newVar = ($currVar.Split(';') | Where-Object { $_ -ne $installPrefix + '\debug\bin' }) -join ';';
[System.Environment]::SetEnvironmentVariable('Path', $newVar, 'User');

Write-Host 'Removing ' + $installPrefix + '\bin from the Path User enviroment variable.'
$currVar = [System.Environment]::GetEnvironmentVariable('Path', 'User');
$newVar = ($currVar.Split(';') | Where-Object { $_ -ne $installPrefix + '\bin' }) -join ';';
[System.Environment]::SetEnvironmentVariable('Path', $newVar, 'User');

