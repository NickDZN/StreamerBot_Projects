using System;
using System.Diagnostics;
using System.Linq;
using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;

public class CPHInline
{
    public bool Execute()
    {
        const string gv_sbstartupaps = "SBCONFIG_STARTUP_APPS";
        string trimmedPath = null;
        string appName = null; 

        try
        {
            // Log starting point
            Log("Starting execution of Startup App Loader.", logLevel: 3);

            // Get the application dictionary stored as a JSON string in the global variable
            Log("Fetching list of paths to open.", logLevel: 3);
            string applicationListString = CPH.GetGlobalVar<string>(gv_sbstartupaps, true);
            if (applicationListString == null || !applicationListString.Any()) return Log(logMessage: "Application list is empty, or failed to parse", logLevel: 0, halting: 1); 

            Log("Splitting application list string.", logLevel: 3);
            var applicationList = applicationListString.Split(new[] {','}, StringSplitOptions.RemoveEmptyEntries).ToList();

            // Log the number of entries found in the dictionary
            Log($"Application list contains {applicationList.Count} entries.", logLevel: 3);            
            foreach (var applicationPath in applicationList) {
                
                trimmedPath = applicationPath.Trim(); 
                var appPath = Path.GetDirectoryName(trimmedPath); 
                var appExe = Path.GetFileName(trimmedPath); 
                appName = Path.GetFileNameWithoutExtension(trimmedPath); 

                Log($"Processing application: {appName} with path: {trimmedPath}", logLevel: 3);

                // Check if the process is already open
                if (!IsProcessOpen(appName)) {
                    // If the process is not running, try to open it
                    Log($"Attempting to open process: {appName}.", logLevel: 3);

                    if (!OpenProcess(appPath, appExe)) Log($"Failed to open process: {appName}.", logLevel: 1);
                } else {
                    Log($"{appName} is already running.", logLevel: 1);
                }
            }

            // Log successful execution
            Log("Completed execution of Startup App Loader.", logLevel: 3);
        }
        catch (Exception ex)
        {
            // Log any unexpected errors
            string errorMessage = appName != null ? 
                $"An unexpected error occurred while processing {appName}." : 
                "An unexpected error occurred during execution.";
                
            return Log(logMessage: errorMessage, logLevel: 0, halting: 1, ex: ex);
        }

        return true;
    }

    private bool IsProcessOpen(string processName) {
        // Log the process name being checked
        Log($"Checking if process {processName} is already open.", logLevel: 3);
        
        // Get all processes with the specified name and check if any are running
        Process[] processes = Process.GetProcessesByName(processName);
        return processes.Length > 0;
    }


    private bool OpenProcess(string workingDirectory, string executableName) {
        try {

            string fullPath = Path.Combine(workingDirectory, executableName);

            var processStartInfo = new ProcessStartInfo { 
                FileName = fullPath, 
                CreateNoWindow = true, 
                UseShellExecute = false, 
                WorkingDirectory = workingDirectory
            }; 

            // Start a new process using the specified executable path
            Process.Start(processStartInfo );
            CPH.LogDebug($"Opened {executableName} successfully.");
            return true;
        }
        catch (Exception ex)
        {
            // Log an error message if the process fails to start
            return Log(logMessage: $"Failed to open {executableName}.", logLevel: 1, halting: 0, ex: ex);
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