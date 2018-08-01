function Component()
{
}

Component.prototype.createOperations = function()
{
    console.log("component: " + component.displayName + ", createOperations called");
     
    component.createOperations();	 
	   
    // Add mantainance of Path variables 
	oper = [ "powershell", "-ExecutionPolicy", "ByPass", "-File", "@TargetDir@"+"\\"+ "x64-windows" + "\\" + "addPathsToEnvVariables.ps1"+"", "-installPrefix", "@TargetDir@" + "\\" + "x64-windows"];
    undoOper = [ "powershell", "-ExecutionPolicy", "ByPass", "-File", "@TargetDir@"+"\\"+ "x64-windows" + "\\" + "removePathsFromEnvVariables.ps1", "-installPrefix", "@TargetDir@" + "\\" + "x64-windows" ];
    component.addOperation("Execute", oper, "UNDOEXECUTE", undoOper);
                           
                           
}
