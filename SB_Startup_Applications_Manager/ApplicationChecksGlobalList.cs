using System;
using System.Collections.Generic;
using Newtonsoft.Json;

public class CPHInline{
    public bool Execute() {

        const string gv_sbstartupaps = "SBCONFIG_STARTUP_APPS";

        try {

		    List<String> applicationsToRun = new List<string>{}; 

		    // your main code goes here
		    foreach (var kvp in args) {
		    	string keyValue = kvp.Key;	
                
		    	if (keyValue.StartsWith("startup_application", StringComparison.OrdinalIgnoreCase)) {
                    Log(logMessage: $"Processing {keyValue}", logLevel: 3);                	
		    		string pathToAdd = args[keyValue].ToString();
		    		
                    // If the path is not null or empty, add it to the list
                    if (!string.IsNullOrEmpty(pathToAdd)) {
                        applicationsToRun.Add(pathToAdd);
                        Log(logMessage: $"Adding {pathToAdd}", logLevel: 3);
                    } else {
                        Log(logMessage: $"Invalid path for {keyValue}.", logLevel: 0);
                    }
		    	}				
            }
        
            if (applicationsToRun.Count == 0) {
                return Log(logMessage: "No valid startup applications found.", logLevel: 0, halting: 1);
            }        

            string applicationListCSV = string.Join(",", applicationsToRun);

            // Store the JSON string as a global variable
            try {
                CPH.SetGlobalVar(gv_sbstartupaps, applicationListCSV, true);
            } catch (Exception ex) {
                return Log(logMessage: $"Failed to set the global variable. Error: {ex.Message}", logLevel: 0, halting: 1);
            }

            // Log the successful creation of the global variable
            return Log(logMessage: $"Applications dictionary stored as a global variable with {applicationsToRun.Count} entries", logLevel: 2);
        } catch (Exception ex) {
            // Log any unexpected errors that occur
            CPH.LogError($"An unexpected error occurred. Error: {ex.Message}");
            return false;
        }
    }

    private bool Log(string logMessage, int logLevel = 0, int halting = 0, Exception ex = null) {
        // Create the full log message, including the exception message if provided
        string fullMessage = logLevel == 0 ? $"Error: {logMessage}" : logMessage;
        if (ex != null) fullMessage += $", Exception: {ex.Message}";

        // Check if chat debugging is enabled by fetching the global variable "SBCONFIG_LOGGING_CHATDEBUG"
        int chatDebugMessage = CPH.GetGlobalVar<int>("SBCONFIG_LOGGING_CHATDEBUG", true);
        if (chatDebugMessage == 1) {
            CPH.SendMessage(fullMessage); // Send the message to chat if enabled
        }

        // Log the message based on the log level using a switch statement
        switch (logLevel) {
            case 0:
                CPH.LogError(fullMessage); 
                if (halting == 1) return false;
                break;
            case 1:
                CPH.LogWarn(fullMessage); 
                break;
            case 2:
                CPH.LogInfo(fullMessage); 
                break;
            case 3:
                CPH.LogDebug(fullMessage);
                break;
            case 4:
                CPH.LogVerbose(fullMessage);
                break;
            default:
                CPH.LogError($"Unknown log level: {logLevel}. Message: {fullMessage}"); 
                if (halting == 1) return false;
                break;
        }

        return true;
    }

}