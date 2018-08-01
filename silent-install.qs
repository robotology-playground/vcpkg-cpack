function Controller()
{
    installer.installationFinished.connect(function() {
        gui.clickButton(buttons.FinishButton);
    })
}

Controller.prototype.IntroductionPageCallback = function()
{
    gui.clickButton(buttons.NextButton); // automatically click the Next button
}

Controller.prototype.TargetDirectoryPageCallback = function()
{
    gui.clickButton(buttons.NextButton); // automatically click the Next button
}

Controller.prototype.ComponentSelectionPageCallback = function()
{
    gui.clickButton(buttons.NextButton); // automatically click the Next button
}

Controller.prototype.LicenseAgreementPageCallback = function()
{
    gui.currentPageWidget().AcceptLicenseRadioButton.setChecked(true);
    gui.clickButton(buttons.NextButton); // automatically click the Next button
}

Controller.prototype.StartMenuDirectoryPageCallback = function()
{
    gui.clickButton(buttons.NextButton); // automatically click the Next button
}

Controller.prototype.ReadyForInstallationPageCallback = function()
{
    gui.clickButton(buttons.NextButton); // automatically click the Next button
}

Controller.prototype.PerformInstallationPageCallback = function()
{
    gui.clickButton(buttons.NextButton); // automatically click the Next button
}

Controller.prototype.InstallationFinishedPageCallback = function()
{
    gui.clickButton(buttons.NextButton); // automatically click the Next button
}