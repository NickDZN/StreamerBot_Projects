using System;
using System.Diagnostics;
using System.Linq;
using System.Collections.Generic;
using Newtonsoft.Json;

public class CPHInline
{
    public bool Execute()
    {
        const string gv_sbstartupaps = "SBCONFIG_STARTUP_APPS";
        string processName = null;
        string processPath = null;

        try
        {
            // Log starting point
            Log("Starting execution of Startup Application Checker.", logLevel: 3);

            // Get the application dictionary stored as a JSON string in the global variable
            Log("Fetching application dictionary from global variable.", logLevel: 3);
            string applicationDictionaryJson = CPH.GetGlobalVar<string>(gv_sbstartupaps, true);

            // Deserialize the JSON string into a dictionary
            Log("Deserializing application dictionary JSON.", logLevel: 3);
            var applicationDictionary = JsonConvert.DeserializeObject<Dictionary<string, string>>(applicationDictionaryJson);

            // Exit if the dictionary is null or empty
            if (applicationDictionary == null || !applicationDictionary.Any())
            {
                return Log(logMessage: "Application dictionary is empty or failed to deserialize.", logLevel: 0, halting: 1);
            }

            // Log the number of entries found in the dictionary
            Log($"Application dictionary contains {applicationDictionary.Count} entries.", logLevel: 3);

            // Iterate over each key-value pair in the dictionary
            foreach (var application in applicationDictionary)
            {
                processName = application.Key; // The application name (key)
                processPath = application.Value; // The application path (value)

                // Log current application being processed
                Log($"Processing application: {processName} with path: {processPath}", logLevel: 3);

                // Check if the process is already open
                if (!IsProcessOpen(processName))
                {
                    // If the process is not running, try to open it
                    Log($"Attempting to open process: {processName}.", logLevel: 3);
                    if (!OpenProcess(processPath))
                    {
                        Log($"Failed to open process: {processName}.", logLevel: 1);
                    }
                }
                else
                {
                    // If the process is already running, log a message
                    Log($"{processName} is already running.", logLevel: 1);
                }
            }

            // Log successful execution
            Log("Completed execution of CPHInline.Execute.", logLevel: 3);
        }
        catch (Exception ex)
        {
            // Log any unexpected errors
            string errorMessage = processName != null ? 
                $"An unexpected error occurred while processing {processName}." : 
                "An unexpected error occurred during execution.";
                
            return Log(logMessage: errorMessage, logLevel: 0, halting: 1, ex: ex);
        }

        return true;
    }

    private static bool IsProcessOpen(string processName)
    {
        // Log the process name being checked
        Log($"Checking if process {processName} is already open.", logLevel: 3);
        
        // Get all processes with the specified name and check if any are running
        Process[] processes = Process.GetProcessesByName(processName);
        return processes.Length > 0;
    }

    private bool OpenProcess(string processPath)
    {
        try
        {
            // Start a new process using the specified executable path
            Process.Start(processPath);
            CPH.LogDebug($"Opened {processPath} successfully.");
            return true;
        }
        catch (Exception ex)
        {
            // Log an error message if the process fails to start
            return Log(logMessage: $"Failed to open {processPath}.", logLevel: 1, halting: 0, ex: ex);
        }
    }


    // Method to log messages and handle error reporting
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