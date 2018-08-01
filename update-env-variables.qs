function Component()
{
}

Component.prototype.createOperations = function()
{
    console.log("component: " + component.displayName + ", createOperations called");
   
    // call default implementation
    //component.createOperations();
    
    // Define simple powershell commands to add or remove an element from an Environment Variable list 
    psAddElementToEnvList = function(envVariable, element) { return "\"$currVar = [System.Environment]::GetEnvironmentVariable('" + envVariable + "', 'User'); $newVar = $currVar + '"+element+"'; [System.Environment]::SetEnvironmentVariable('" + envVariable + "', $newVar, 'User');\"" } 
    psRemoveElementFromEnvList = function(envVariable, element) { return "\"$var = [System.Environment]::GetEnvironmentVariable('" + envVariable + "', 'User'); $var = ($var.Split(';') | Where-Object { $_ -ne '" + element + "' }) -join ';'; [System.Environment]::SetEnvironmentVariable('" + envVariable + "', $var, 'User');" }
    
    // CMAKE_PREFIX_PATH 
    component.addOperation("Execute",     "powershell", "-Command", psAddElementToEnvList("CMAKE_PREFIX_PATH", "@TargetDir@"),
                           "UNDOEXECUTE", "powershell", "-Command", psRemoveElementFromEnvList("CMAKE_PREFIX_PATH", "@TargetDir@"));
                           
                           
}
