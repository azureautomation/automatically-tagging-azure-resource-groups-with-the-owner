Automatically tagging Azure Resource Groups with the owner
==========================================================

            

An Azure Automation Runbook, to automatically tag Azure Resource Groups with the owner alias.


  *  Create a new Azure Automation Runbook 
  *  Create an AzureRunAsConnection 
  *  Use the runbook supplied here (I would recommend a daily schedule) 

This is how the runbook works...


  *  Get all resources without an ALIAS tag 
  *  Search the Azure Logs whether there is any log records for these untagged ones

  *  Update the ALIAS tag with a user found in the logs. 

 


Run the cmdlet manually like this...




 




A more detailed description is available here..


[http://blog.knor.net/index.php/2016/12/14/automatically-tagging-azure-resource-groups-with-the-owner/](AutoTagResources.ps1 -WhatIf -To '<mknor@microsoft.com>;<max@knor.net>' -DayCount 2 -Verbose)


        
    
TechNet gallery is retiring! This script was migrated from TechNet script center to GitHub by Microsoft Azure Automation product group. All the Script Center fields like Rating, RatingCount and DownloadCount have been carried over to Github as-is for the migrated scripts only. Note : The Script Center fields will not be applicable for the new repositories created in Github & hence those fields will not show up for new Github repositories.
