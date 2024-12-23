using System;
using System.Collections.Generic;
using System.ComponentModel; // For TypeDescriptor and EventDescriptor
using System.Diagnostics; // For process management
using System.Drawing; // For graphical structures like Rectangle
using System.IO;
using System.Linq; // For LINQ queries
using System.Reflection; // For BindingFlags
using System.Runtime.InteropServices; // For importing DLL methods
using System.Text;
using System.Text.Json;
using System.Threading; // For managing threads
using System.Windows.Forms; // For creating Windows Forms


/// <summary>
/// Main class to launch the configuration form in Streamer.bot.
/// </summary>
public class CPHInline
{
    private static LoadStartupConfigForm mainFormInstance = null;

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool GetWindowRect(IntPtr hWnd, out Rectangle lpRect);

    public bool Execute()
    {
        try
        {
            // Set up static references
            CPH.LogDebug("SBSAM Loaded.");
            SB.CPH = CPH;
            SB.args = args;
        }
        catch (Exception ex)
        {
            return CPHLogger.LogE($"Unable to create static CPH reference: {ex.Message}\n{ex.StackTrace}");
        }

        try
        {
            CPHLogger.LogV("Attempting to get process details");
            Process currentProcess = Process.GetCurrentProcess();
            CPHLogger.logProcessDetails(currentProcess);

            if (currentProcess.MainWindowHandle == IntPtr.Zero)
            {
                CPHLogger.LogE("Main window handle is invalid. Streamer.bot is either not running, or running headlessly.");
                return false;
            }

            if (!GetWindowRect(currentProcess.MainWindowHandle, out Rectangle windowRect))
            {
                CPHLogger.LogE("Failed to retrieve the window rectangle.");
                return false;
            }
            
            // Log the dimensions of the Streamer.bot window
            CPHLogger.LogI($"Streamer.bot Window Rect: {windowRect}");
            CPHLogger.logRectDetails(windowRect);

            // Step 3: Determine the monitor where the window resides
            var monitors = Screen.AllScreens; // Get all monitors connected to the system
            CPHLogger.logMonitorDetails(monitors);

            Screen targetMonitor;

            if (monitors.Length == 1)
            {
                // If only one monitor exists, no calculations are needed
                targetMonitor = monitors[0];
                CPHLogger.LogI("Single monitor detected. Skipping multi-monitor calculations.");
            }
            else
            {
                // Use Screen.FromRectangle to determine the most relevant screen for the window
                targetMonitor = Screen.FromRectangle(windowRect);
                CPHLogger.LogI($"Determined monitor via FromRectangle: {targetMonitor.DeviceName}, Bounds: {targetMonitor.Bounds}");
            }

            // Log the details of the selected monitor
            CPHLogger.LogI($"Target Monitor: {targetMonitor.DeviceName}, Bounds: {targetMonitor.Bounds}");

            // Normalize the window rectangle coordinates to the selected monitor
            Rectangle normalizedWindowRect = NormalizeToMonitor(windowRect, targetMonitor);

            // Step 4: Start a new thread to open the form
            CPHLogger.LogD("Starting main form thread.");
            Thread staThread = new Thread(() =>
            {
                try
                {
                    CPHLogger.LogD("Enabling application visual styles.");
                    Application.EnableVisualStyles();

                    // Retrieve the list of actions from Streamer.bot
                    CPHLogger.LogD("Populating list of actions.");
                    List<ActionData> actionList = CPH.GetActions();

                    CPHLogger.LogD("Open Form.");
                    if (mainFormInstance == null || mainFormInstance.IsDisposed)
                    {
                        // Create a new instance of the form if it doesn't already exist
                        CPHLogger.LogD("Loading a new form.");
                        mainFormInstance = new LoadStartupConfigForm(normalizedWindowRect, actionList);

                        // Apply normalized position
                        CPHLogger.LogI($"Applying normalized rectangle: {normalizedWindowRect}");
                        mainFormInstance.StartPosition = FormStartPosition.Manual;
                        mainFormInstance.Location = new Point(
                            targetMonitor.Bounds.Left + normalizedWindowRect.X + 15,
                            targetMonitor.Bounds.Top + normalizedWindowRect.Y + 15
                        );

                        // Handle unhandled exceptions in the STA thread
                        Application.ThreadException += (sender, args) =>
                        {
                            CPHLogger.LogE(
                                $"Unhandled exception in STA thread: {args.Exception.Message}\n{args.Exception.StackTrace}"
                            );
                        };

                        // Run the form
                        Application.Run(mainFormInstance);
                    }
                    else
                    {
                        // Bring the existing form to the front
                        CPHLogger.LogD("Bringing current form to front.");
                        mainFormInstance.BringToFront();
                    }
                }
                catch (Exception ex)
                {
                    // Log any exceptions that occur
                    CPHLogger.LogE($"Unhandled exception in STA thread: {ex.Message}\n{ex.StackTrace}");
                }
            });

            // Set the thread apartment state to STA and start it
            staThread.SetApartmentState(ApartmentState.STA);
            staThread.Start();
            return true;
        }
        catch (Exception ex)
        {
            return CPHLogger.LogE($"An error occurred during execution: {ex.Message}\n{ex.StackTrace}");
        }
    }

    private Rectangle NormalizeToMonitor(Rectangle windowRect, Screen monitor)
    {
        var monitorBounds = monitor.Bounds;

        // Log initial values for debugging
        CPHLogger.LogI($"Initial Window Rect: {windowRect}");
        CPHLogger.LogI($"Monitor Bounds: {monitorBounds}");

        // Adjust coordinates to align with the monitor's bounds
        int normalizedX = windowRect.Left - monitorBounds.Left;
        int normalizedY = windowRect.Top - monitorBounds.Top;

        CPHLogger.LogD($"Monitor Alignment: Top={monitorBounds.Top}, Bottom={monitorBounds.Bottom}, Left={monitorBounds.Left}, Right={monitorBounds.Right}");

        // Consider vertical and horizontal offsets if monitors are centered
        if (monitorBounds.Top < 0 && monitorBounds.Bottom > 0)
        {
            normalizedY += Math.Abs(monitorBounds.Top);
        }
        if (monitorBounds.Left < 0 && monitorBounds.Right > 0)
        {
            normalizedX += Math.Abs(monitorBounds.Left);
        }

        Rectangle normalizedRect = new Rectangle(
            normalizedX,
            normalizedY,
            windowRect.Width,
            windowRect.Height
        );

        // Log the normalized rectangle for debugging
        CPHLogger.LogI($"Normalized Window Rect: {normalizedRect}");
        return normalizedRect;
    }
}

/// <summary>
/// Main configuration form for managing Streamer.bot settings.
/// </summary>
/// <summary>
/// Main configuration form for managing Streamer.bot settings.
/// </summary>
public class LoadStartupConfigForm : Form
{
    // Panel Controls
    private readonly UserConfigurationPanel _userConfigurationControls;       // User settings and configuration controls
 

    private readonly List<ActionData> actionDataList;

    /// <summary>
    /// Initializes the configuration form with active window dimensions and action data.
    /// </summary>
    /// <param name="activeWindowRect">Screen rectangle for positioning the form.</param>
    /// <param name="actions">List of actions to populate permitted and blocked sections.</param>
    public LoadStartupConfigForm(Rectangle activeWindowRect, List<ActionData> actions)
    {
        CPHLogger.LogC("[S]LoadStartupConfigForm.");
        SetFormProperties(this);

        // Create the core layout panel for organizing all sections
        CPHLogger.LogC("Creating Table Layout"); 
        var coreLayoutPanelForForm = UIComponentFactory.CreateTableLayoutPanel(rows: 6, columns: 1);






        // 🧩 User Configuration Panel
        CPHLogger.LogC("Creating _userConfigurationControls"); 
        _userConfigurationControls = new UserConfigurationPanel();
        //_userConfigurationControls.Dock = DockStyle.Fill;
        //_userConfigurationControls.AutoSize = true; 
        coreLayoutPanelForForm.Controls.Add(_userConfigurationControls, 0, 0);

        // Add the core layout panel to the form
        CPHLogger.LogC("Adding coreLayoutPanelForForm to Controls."); 
        Controls.Add(coreLayoutPanelForForm);
        SuspendLayout();
        ResumeLayout();

        CPHLogger.LogAll(this);
        CPHLogger.logRectDetails(activeWindowRect);
    }

    /// <summary>
    /// Sets the default properties for the form.
    /// </summary>
    /// <param name="form">The target form object.</param>
    private void SetFormProperties(Form form)
    {
        CPHLogger.LogC("[S]SetFormProps.");
        form.Text = Constants.FormName;
        form.BackColor = Constants.FormColour;
        form.Font = new Font("Segoe UI", 10);
        form.FormBorderStyle = FormBorderStyle.FixedDialog;
        form.AutoSize = true;
        
        CPHLogger.LogC("[E]SetFormProps.");
    }
}

public class BaseConfigurationPanel : UserControl
{
    public BaseConfigurationPanel()
    {
        Dock = DockStyle.Fill;
        AutoSize = true;
        AutoSizeMode = AutoSizeMode.GrowAndShrink;
        Padding = new Padding(5);
        Margin = new Padding(5);

        CPHLogger.LogV($"BaseConfigurationPanel layout settings applied");
    }
}



public class UserConfigurationPanel : BaseConfigurationPanel 
{
    protected readonly Button _resetSettings;
    protected readonly Button _importConfig;
    protected readonly Button _exportConfig;
    protected readonly Button _testConfig;
    protected readonly Button _aboutApplication;

    public UserConfigurationPanel()
    {
        CPHLogger.LogC("[S]UserConfigurationPanel.");
        var configurationGroupBox = UIComponentFactory.CreateGroupBox("Manage your configuration");
        var buttonTable = UIComponentFactory.CreateTableLayoutPanel(rows: 1, columns: 5, columnStyling: Constants.ColumnStyling.Distributed);

        // Initialize Buttons
        CPHLogger.LogV("[UserConfigurationPanel] Creating Buttons.");
        _resetSettings = UIComponentFactory.CreateButton("Reset All", Constants.ButtonStyle.Primary, OnResetAll);
        _importConfig = UIComponentFactory.CreateButton("Import", Constants.ButtonStyle.Primary, OnImport);
        _exportConfig = UIComponentFactory.CreateButton("Export", Constants.ButtonStyle.Primary, OnExport);
        _testConfig = UIComponentFactory.CreateButton("Test Config", Constants.ButtonStyle.Primary, OnTestConfig);
        _aboutApplication = UIComponentFactory.CreateButton("About", Constants.ButtonStyle.Primary, OnAbout);

        // Add buttons to the TableLayoutPanel
        buttonTable.Controls.Add(_resetSettings, 0, 0);
        buttonTable.Controls.Add(_importConfig, 1, 0);
        buttonTable.Controls.Add(_exportConfig, 2, 0);
        buttonTable.Controls.Add(_testConfig, 3, 0);
        buttonTable.Controls.Add(_aboutApplication, 4, 0);

        // Add TableLayoutPanel to GroupBox
        CPHLogger.LogV("[AddUserConfigurationControlls] Adding TableLayoutPanel to GroupBox.");
        configurationGroupBox.Controls.Add(buttonTable);

        // Add GroupBox to UserControl
        Controls.Add(configurationGroupBox);     
        CPHLogger.LogC("[E]UserConfigurationPanel.");
    }

    protected virtual void OnResetAll(object sender, EventArgs e)
    {
        DialogResult result = MessageBox.Show(
            "Are you sure you want to reset the configuration?",
            "Confirm Reset",
            MessageBoxButtons.YesNo,
            MessageBoxIcon.Warning
        );
        if (result == DialogResult.Yes)
        {
            CPHLogger.LogV("Reset Settings...");
        }
    }

    protected virtual void OnImport(object sender, EventArgs e)
    {
        CPHLogger.LogV("Importing Settings...");
    }

    protected virtual void OnExport(object sender, EventArgs e)
    {
        CPHLogger.LogV("Exporting Settings...");
    }        

    protected virtual void OnAbout(object sender, EventArgs e)
    {
        CPHLogger.LogV("About...");
    }

    protected virtual void OnTestConfig(object sender, EventArgs e)
    {
        CPHLogger.LogV("Testing Settings...");
    }
}


public class UIComponentFactory
{
    /// <summary>
    /// Creates and styles a Button control.
    /// </summary>
    /// <param name = "text">The text displayed on the button.</param>
    /// <param name = "clickEvent">Optional click event handler.</param>
    /// <param name = "buttonStyle">The style of the button (from <see cref = "Constants.ButtonStyle"/>).</param>
    /// <param name = "btnEnabled">Specifies whether the button is enabled.</param>
    /// <returns>A styled <see cref = "Button"/> control.</returns>
    public static Button CreateButton(string text, Constants.ButtonStyle style = Constants.ButtonStyle.Default, EventHandler clickEvent = null, bool isEnabled = true)
    {
        var btn = new Button
        {
            Text = text,
            Enabled = isEnabled,
            Height = 26,
            AutoSize = false,
            FlatStyle = FlatStyle.Flat,
            Font = new Font("Microsoft Sans Serif", 8.5f),
            BackColor = Constants.PrimaryBtnBG,
            ForeColor = Constants.PrimaryBtnText
        };
        // Apply different styles based on the ButtonStyle enum
        switch (style)
        {
            case Constants.ButtonStyle.Primary:
                btn.Width = 90;
                btn.Margin = new Padding(0, 0, 15, 0);
                btn.Padding = new Padding(2, 2, 2, 2);
                btn.FlatAppearance.BorderSize = 1;
                btn.FlatAppearance.BorderColor = Constants.Border;
                break;
            case Constants.ButtonStyle.Longer:
                btn.Width = 130;
                btn.Margin = new Padding(1, 3, 1, 1);
                btn.Padding = new Padding(2, 2, 2, 2);
                btn.FlatAppearance.BorderSize = 1;
                btn.FlatAppearance.BorderColor = Constants.Border;
                break;
            case Constants.ButtonStyle.ArrowBtn:
                btn.Width = 20;
                btn.Height = 20;
                btn.Margin = new Padding(1, 0, 1, 0);
                btn.Padding = new Padding(0, 0, 0, 0);
                btn.FlatAppearance.BorderSize = 1;
                btn.FlatAppearance.BorderColor = Constants.Border;
                btn.BackgroundImageLayout = ImageLayout.Center;
                break;
            case Constants.ButtonStyle.FlowControl:
                btn.Width = 100;
                btn.Margin = new Padding(5, 2, 5, 2);
                btn.Padding = new Padding(5, 0, 5, 0);
                btn.FlatAppearance.BorderSize = 1;
                btn.FlatAppearance.BorderColor = Constants.Border;
                btn.BackgroundImageLayout = ImageLayout.Center;
                break;
            default:
                // Default style
                btn.Width = 90;
                btn.Margin = new Padding(0);
                btn.Padding = new Padding(2, 2, 2, 2);
                btn.FlatAppearance.BorderSize = 1;
                btn.FlatAppearance.BorderColor = Constants.Border;
                break;
        }

        if (clickEvent != null)
            btn.Click += clickEvent;
        // Verbose logging of all button properties
        CPHLogger.LogV($"Button created. Properties: Text=\"{btn.Text}\", Width={btn.Width}, Height={btn.Height}, Enabled={btn.Enabled}, " + $"Margin={btn.Margin}, Padding={btn.Padding}, Style={style}, BackColor={btn.BackColor}, ForeColor={btn.ForeColor}, " + $"FlatStyle={btn.FlatStyle}, BorderSize={btn.FlatAppearance.BorderSize}, BorderColor={btn.FlatAppearance.BorderColor}");
        return btn;
    }


    public static TableLayoutPanel CreateTableLayoutPanel(int rows, int columns, int? height = null, Constants.RowStyling rowStyling = Constants.RowStyling.Default, Constants.ColumnStyling columnStyling = Constants.ColumnStyling.Default, List<RowStyle> customRowStyles = null, List<ColumnStyle> customColumnStyles = null)
    {
        var tableLayout = new TableLayoutPanel
        {
            Dock = DockStyle.Fill,
            ColumnCount = columns,
            RowCount = rows,
            AutoSize = height == null, // If height is not provided, enable AutoSize
            AutoSizeMode = AutoSizeMode.GrowAndShrink,
            CellBorderStyle = TableLayoutPanelCellBorderStyle.None,
            Padding = new Padding(0),
            Margin = new Padding(0),
            BackColor = Constants.FormColour            
        };
        // If height is explicitly provided, set it
        if (height != null)
        {
            tableLayout.Height = height.Value;
            tableLayout.AutoSize = false;
            tableLayout.AutoSizeMode = AutoSizeMode.GrowOnly;
        }

        // Apply row styles based on the specified RowStyling
        switch (rowStyling)
        {
            case Constants.RowStyling.Distributed:
                for (int i = 0; i < rows; i++)
                    tableLayout.RowStyles.Add(new RowStyle(SizeType.Percent, 100f / rows));
                break;
            case Constants.RowStyling.Custom:
                for (int i = 0; i < rows; i++)
                {
                    if (customRowStyles != null && i < customRowStyles.Count)
                    {
                        tableLayout.RowStyles.Add(customRowStyles[i]);
                    }
                    else
                    {
                        tableLayout.RowStyles.Add(new RowStyle(SizeType.AutoSize));
                    }
                }

                break;
            case Constants.RowStyling.Default:
            default:
                for (int i = 0; i < rows; i++)
                    tableLayout.RowStyles.Add(new RowStyle(SizeType.AutoSize));
                break;
        }

        // Apply column styles based on the specified ColumnStyling
        switch (columnStyling)
        {
            case Constants.ColumnStyling.Distributed:
                for (int j = 0; j < columns; j++)
                    tableLayout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100f / columns));
                break;
            case Constants.ColumnStyling.Custom:
                for (int j = 0; j < columns; j++)
                {
                    if (customColumnStyles != null && j < customColumnStyles.Count)
                    {
                        tableLayout.ColumnStyles.Add(customColumnStyles[j]);
                    }
                    else
                    {
                        tableLayout.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
                    }
                }

                break;
            case Constants.ColumnStyling.Default:
            default:
                for (int j = 0; j < columns; j++)
                    tableLayout.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
                break;
        }

        CPHLogger.LogI($"TableLayoutPanel created with {rows} rows and {columns} columns.");
        return tableLayout;
    }


    /// <summary>
    /// Factory for creating and styling GroupBox controls.
    /// </summary>
    public static GroupBox CreateGroupBox(string title, Padding? margin = null, Font font = null)
    {
        var groupBox = new GroupBox
        {
            Text = title,
            AutoSize = true,
            Dock = DockStyle.Fill,
            Margin = margin ?? new Padding(5),
            Font = font ?? new Font("Segoe UI", 10),
            ForeColor = Constants.PrimaryText,
            BackColor = Constants.FormColour            
        };
        CPHLogger.LogV($"GroupBox created. Properties: Text=\"{title}\", Margin={groupBox.Margin}, Font={groupBox.Font}");
        return groupBox;
    }


}





public class ApplicationDetails
{
    public string FileName { get; set; }
    public string FullPath { get; set; }
    public int Index { get; set; }

    public ApplicationDetails(string fullPath, int index)
    {
        FullPath = fullPath;
        FileName = Path.GetFileName(fullPath);
        Index = index;
    }

    public override string ToString()
    {
        return FileName;
    }
}



/// <summary>
/// A static class containing constants used throughout the application.
/// </summary>
public static class Constants
{
    // Strings.
    public static readonly string DataDir = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "data");
    public const string ExecutableFilter = "Executable Files (*.exe)|*.exe|All Files (*.*)|*.*";
    public const string SettingsFileName = "settings.json";
    public const string FormName = "SBZen Config Manager";

    //Colours
    public static readonly Color FormColour = ColorTranslator.FromHtml("#151515");
    public static readonly Color PrimaryText = ColorTranslator.FromHtml("#FFFFFF");
    public static readonly Color SecondaryText = ColorTranslator.FromHtml("#B0B0B0");
    public static readonly Color Accent = ColorTranslator.FromHtml("#BB86FC");
    public static readonly Color Surface = ColorTranslator.FromHtml("#2A313E");
    public static readonly Color Border = ColorTranslator.FromHtml("#373737");
    public static readonly Color BtnBG = ColorTranslator.FromHtml("#1E1E1E");
    public static readonly Color BtnText = ColorTranslator.FromHtml("#FFFFFF");
    public static readonly Color PrimaryBtnBG = ColorTranslator.FromHtml("#0F40A9");
    public static readonly Color PrimaryBtnText = ColorTranslator.FromHtml("#FFFFFF");

    //Enums    
    public enum StartupMode {Yes, No, Prompt,}
    public enum ButtonStyle {Default, Primary, Longer, ArrowBtn, FlowControl,}    
    public enum RowStyling {Default, Distributed, Custom,}
    public enum ColumnStyling {Default, Distributed, Custom,}
}


/// <summary>
/// A logging class to encapsulate and provide static logging methods.
/// Inherits from the SB class to access shared functionality.
/// </summary>
public class CPHLogger : SB
{
    private static int controlCounter = 0;

    // Log Levels. 
    public static void LogD(string message) => CPH.LogDebug($"[DEBUG] {message}");
    public static void LogI(string message) => CPH.LogInfo($"[INFO] {message}");
    public static void LogV(string message) => CPH.LogVerbose($"[VERBOSE] {message}");
    public static void LogW(string message) => CPH.LogWarn($"[WARN] {message}");

    // Error has return to cause exit. 
    public static bool LogE(string message)
    {
        CPH.LogError($"[ERROR] {message}");
        return false;
    }

    public static void LogC(string message) => CPH.LogDebug($"[Checkpoint] {message}");


    // Prebuilt Logging Methods. 
    public static void logProcessDetails(Process currentProcess)
    {
        if (currentProcess == null) CPHLogger.LogE("Process object is null. Unable to log process details.");

        try
        {
            CPHLogger.LogI("====== Process Details ======");
            CPHLogger.LogI($"Process ID: {currentProcess.Id}");
            CPHLogger.LogI($"Process Name: {currentProcess.ProcessName}");
            CPHLogger.LogI($"Main Window Handle: {currentProcess.MainWindowHandle}");
            CPHLogger.LogI($"Main Window Title: {currentProcess.MainWindowTitle}");
            CPHLogger.LogI($"Start Time: {currentProcess.StartTime}");
            CPHLogger.LogI($"Responding: {currentProcess.Responding}");
            CPHLogger.LogI($"Memory Usage: {currentProcess.WorkingSet64 / 1024 / 1024} MB");
            CPHLogger.LogI($"Total Processor Time: {currentProcess.TotalProcessorTime}");
            CPHLogger.LogI("=============================");
        }
        catch (Exception ex)
        {
            CPHLogger.LogE($"An error occurred while logging process details: {ex.Message}\n{ex.StackTrace}");
        }
    }

    public static void logRectDetails(Rectangle rect)
    {
        try
        {
            CPHLogger.LogI("=== Active Window Details ===");
            CPHLogger.LogI($"Left Pos: {rect.Left}");
            CPHLogger.LogI($"Top Pos: {rect.Top}");
            CPHLogger.LogI($"Right Pos: {rect.Right}");
            CPHLogger.LogI($"Bottom Pos: {rect.Bottom}");
            CPHLogger.LogI($"Height: {rect.Height}");
            CPHLogger.LogI($"Width: {rect.Width}");
            CPHLogger.LogI($"Location: {rect.Location}");
            CPHLogger.LogI($"Size: {rect.Size}");
            CPHLogger.LogI($"IsEmpty: {rect.IsEmpty}");
            CPHLogger.LogI($"ToString: {rect.ToString()}");
            CPHLogger.LogI("=============================");
        }
        catch (Exception ex)
        {
            CPHLogger.LogE($"An error occurred while logging process details: {ex.Message}\n{ex.StackTrace}");
        }
    }

    public static void logMonitorDetails(Screen[] monitors)
    {
        if (monitors == null || monitors.Length == 0)
        {
            CPHLogger.LogE("No monitors detected.");
            return;
        }

        CPHLogger.LogI("====== Monitor Details ======");
        foreach (var monitor in monitors)
        {
            CPHLogger.LogI($"Monitor: {monitor.DeviceName}");
            CPHLogger.LogI($"  Bounds: {monitor.Bounds}");
            CPHLogger.LogI($"    X: {monitor.Bounds.X}, Y: {monitor.Bounds.Y}, Width: {monitor.Bounds.Width}, Height: {monitor.Bounds.Height}");
            CPHLogger.LogI($"  Working Area: {monitor.WorkingArea}");
            CPHLogger.LogI($"    X: {monitor.WorkingArea.X}, Y: {monitor.WorkingArea.Y}, Width: {monitor.WorkingArea.Width}, Height: {monitor.WorkingArea.Height}");
            CPHLogger.LogI($"  Primary Monitor: {monitor.Primary}");
        }

        CPHLogger.LogI("=============================");
    }
    

    public static void LogPerformanceMetrics(string eventName, Action action)
    {
        var start = DateTime.Now;
        action();
        var end = DateTime.Now;

        CPHLogger.LogI("==== Performance Details ====");
        CPHLogger.LogI($"[PERFORMANCE] {eventName} completed in {(end - start).TotalMilliseconds} ms");
        CPHLogger.LogI("=============================");
    }


    public static void LogAll(Control control, string context = "General")
    {
        controlCounter = 0;
        CPHLogger.LogI($"[LAYOUT] ===== BEGIN LAYOUT DEBUG LOG [{context}] =====");
        //LogControlHierarchy(control);
        LogDpiAndBounds(control);
        foreach (Control child in control.Controls)
        {
            if (child is TableLayoutPanel tableLayoutPanel) 
                LogTableLayoutPanelDetails(tableLayoutPanel);
            
            LogScrollableContent(child);
            LogMarginPadding(child);
        }

        CPHLogger.LogI($"[LAYOUT] ===== END LAYOUT DEBUG LOG [{context}] =====");
    }


    private static void LogTableLayoutPanelDetails(TableLayoutPanel tableLayoutPanel)
    {
        CPHLogger.LogI($"[TableLayoutPanel] {tableLayoutPanel.Name}, Rows: {tableLayoutPanel.RowCount}, Columns: {tableLayoutPanel.ColumnCount}");
        for (int row = 0; row < tableLayoutPanel.RowCount; row++)
        {
            for (int col = 0; col < tableLayoutPanel.ColumnCount; col++)
            {
                Control cellControl = tableLayoutPanel.GetControlFromPosition(col, row);
                CPHLogger.LogI($"    [Row {row}, Col {col}] => {(cellControl != null ? cellControl.GetType().Name : "Empty")}");
            }
        }
    }


    private static void LogDpiAndBounds(Control control)
    {
        using (Graphics g = control.CreateGraphics())
        {
            CPHLogger.LogI($"[DPI] Scaling: {g.DpiX / 96.0f}x, {g.DpiY / 96.0f}y");
        }

        var screen = Screen.FromControl(control);
        CPHLogger.LogI($"[Screen] Bounds: {screen.Bounds}, Working Area: {screen.WorkingArea}, Control Bounds: {control.Bounds}");
    }


    private static void LogScrollableContent(Control control)
    {
        if (control is ScrollableControl scrollableControl)
        {
            CPHLogger.LogI($"[ScrollableControl] {scrollableControl.Name}, Size: {scrollableControl.Width}x{scrollableControl.Height}");
        }
    }


    private static void LogMarginPadding(Control control)
    {
        CPHLogger.LogI($"[Margins & Padding] Control: {control.Name}, Margin: {control.Margin}, Padding: {control.Padding}");
    }
}


/// <summary>
/// A base class that serves as a foundation for shared resources or functionality.
/// </summary>
public class SB
{
    public static IInlineInvokeProxy CPH;
    public static Dictionary<string, object> args;
}
