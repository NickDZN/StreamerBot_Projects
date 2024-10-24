using System;
using System.Collections.Generic;
using Newtonsoft.Json;

public class CPHInline{
    public bool Execute() {

        const string gv_sbstartupaps = "SBCONFIG_STARTUP_APPS";

        try {
            // Retrieve the comma-separated applications and paths from the arguments
            string applications = args.ContainsKey("apps") ? args["apps"]?.ToString() : string.Empty;
            string applicationPaths = args.ContainsKey("paths") ? args["paths"]?.ToString() : string.Empty;

            // Split the input strings into arrays
            string[] appsList = applications.Split(',');
            string[] appPathList = applicationPaths.Split(',');

            // Check if both lists have the same number of items
            if (appsList.Length != appPathList.Length) return Log(logMessage: "The number of applications and paths do not match.", logLevel: 0, halting: 1);

            // Create a dictionary to store application name and path pairs
            Dictionary<string, string> applicationDictionary = new Dictionary<string, string>();

            // Populate the dictionary with app name as key and app path as value
            for (int i = 0; i < appsList.Length; i++) {
                string appName = appsList[i].Trim(); 
                string appPath = appPathList[i].Trim(); 

                // Check if the appName or appPath is empty
                if (string.IsNullOrEmpty(appName) || string.IsNullOrEmpty(appPath)) return Log(logMessage: "Invalid entry at index {i}: App name or path is empty.", logLevel: 0, halting: 1);

                // Add the app name and path to the dictionary
                applicationDictionary[appName] = appPath;
            }

            // Serialize the dictionary to a JSON string
            string applicationDictionaryJson;
            try {
                applicationDictionaryJson = JsonConvert.SerializeObject(applicationDictionary);
            } catch (Exception ex) {
                return Log(logMessage: $"Failed to serialize the dictionary to JSON. Error: {ex.Message}", logLevel: 0, halting: 1);
            }

            // Store the JSON string as a global variable
            try {
                CPH.SetGlobalVar(gv_sbstartupaps, applicationDictionaryJson, true);
            } catch (Exception ex) {
                return Log(logMessage: $"Failed to set the global variable. Error: {ex.Message}", logLevel: 0, halting: 1);
            }

            // Log the successful creation of the global variable
            return Log(logMessage: $"Applications dictionary stored as a global variable with {applicationDictionary.Count} entries", logLevel: 2);
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