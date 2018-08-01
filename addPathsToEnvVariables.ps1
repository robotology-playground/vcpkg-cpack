# Get the location of the script, that is assumed to be the install prefix
$installPrefix = $PSScriptRoot

Write-Host 'Adding ' + $installPrefix + ' to the CMAKE_PREFIX_PATH User enviroment variable.'
$currVar = [System.Environment]::GetEnvironmentVariable('CMAKE_PREFIX_PATH', 'User');
$newVar = $currVar + ';' + $installPrefix;
[System.Environment]::SetEnvironmentVariable('CMAKE_PREFIX_PATH', $newVar, 'User');

Write-Host 'Adding ' + $installPrefix + '\debug to the CMAKE_PREFIX_PATH User enviroment variable.'
$currVar = [System.Environment]::GetEnvironmentVariable('CMAKE_PREFIX_PATH', 'User');
$newVar = $currVar + ';' + $installPrefix + '\debug';
[System.Environment]::SetEnvironmentVariable('CMAKE_PREFIX_PATH', $newVar, 'User');

Write-Host 'Adding ' + $installPrefix + '\bin to the Path User enviroment variable.'
$currVar = [System.Environment]::GetEnvironmentVariable('Path', 'User');
$newVar = $currVar + ';' + $installPrefix + '\bin' ;
[System.Environment]::SetEnvironmentVariable('Path', $newVar, 'User');

Write-Host 'Adding ' + $installPrefix + '\debug\bin to the Path User enviroment variable.'
$currVar = [System.Environment]::GetEnvironmentVariable('Path', 'User');
$newVar = $currVar + ';' + $installPrefix + '\debug\bin' ;
[System.Environment]::SetEnvironmentVariable('Path', $newVar, 'User');