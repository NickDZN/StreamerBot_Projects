using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Windows.Forms;
using System.ComponentModel; // For TypeDescriptor and EventDescriptor
using System.Reflection; // For BindingFlags

public class CPHInline
{
    // Importing user32.dll to use necessary methods
    [DllImport("user32.dll")]
    private static extern IntPtr GetForegroundWindow();
    private static LoadStartupConfigForm mainFormInstance = null;
    [DllImport("user32.dll", SetLastError = true)]
    private static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool GetWindowRect(IntPtr hWnd, out Rectangle lpRect);
    public bool Execute()
    {
        CPH.LogDebug("SBSAM Loaded.");
        // Create centralised SB instance. 
        SB.CPH = CPH;
        SB.args = args;
        CPHLogger.LogV("CPH + Args Created.");
        // Attempt to get the handle of the currently active window
        CPHLogger.LogD("Get Window Details");
        IntPtr activeWindowHandle = GetForegroundWindow();
        if (activeWindowHandle == IntPtr.Zero)
        {
            CPHLogger.LogE("No active window found.");
            return false;
        }

        // Get the window detals of the main Streamer.bot instance which this is loaded from. 
        StringBuilder windowTitle = new StringBuilder(256);
        GetWindowText(activeWindowHandle, windowTitle, windowTitle.Capacity);
        CPHLogger.LogI($"Window Details: Active Window Handle is {activeWindowHandle}. WindowTitle is {windowTitle}. Window Capacity is: {windowTitle.Capacity}");
        // Get the dimensions of the active window
        if (!GetWindowRect(activeWindowHandle, out Rectangle activeWindowRect))
        {
            CPHLogger.LogE("Failed to get window dimensions.");
            return false;
        }

        CPHLogger.LogI($"Active Window Rect Details: Size: {activeWindowRect.Size}. Height: {activeWindowRect.Height}. Width: {activeWindowRect.Width}");
        // Start new thread for the form.
        CPHLogger.LogD("Starting main form thread.");
        Thread staThread = new Thread(() =>
        {
            try
            {
                CPHLogger.LogD("Enabling application visual styles.");
                Application.EnableVisualStyles();
                CPHLogger.LogD("Populating list of actions.");
                List<ActionData> actionList = CPH.GetActions();
                CPHLogger.LogD("Open Form.");
                if (mainFormInstance == null || mainFormInstance.IsDisposed)
                {
                    CPHLogger.LogD("Loading a new form.");
                    mainFormInstance = new LoadStartupConfigForm(activeWindowRect, actionList);
                    Application.ThreadException += (sender, args) =>
                    {
                        CPHLogger.LogE($"Unhandled exception in STA thread: {args.Exception.Message}\n{args.Exception.StackTrace}");
                    };
                    Application.Run(mainFormInstance);
                }
                else
                {
                    CPHLogger.LogD("Bringing current form to front.");
                    mainFormInstance.BringToFront();
                }
            }
            catch (Exception ex)
            {
                CPHLogger.LogE($"Unhandled exception in STA thread: {ex.Message}\n{ex.StackTrace}");
            }
        });
        staThread.SetApartmentState(ApartmentState.STA);
        staThread.Start();
        return true;
    }
}

public class LoadStartupConfigForm : Form
{
    private readonly EventHandlers _eventHandlers;
    private readonly List<ActionData> actionDataList;
    public LoadStartupConfigForm(Rectangle activeWindowRect, List<ActionData> actions)
    {
        CPHLogger.LogD("[S]LoadStartupConfigForm.");
        // Initialise Event Handlers.
        CPHLogger.LogV("[LoadStartupConfigForm] Initialise Event Handlers");
        _eventHandlers = new EventHandlers();
        // Set Form Properties. 
        CPHLogger.LogV("[LoadStartupConfigForm] Set form variables");
        this.Text = Constants.FormName;
        this.MinimumSize = new Size(100, 100);
        this.BackColor = Constants.FormColour;
        this.Font = new Font("Segoe UI", 10);
        this.FormBorderStyle = FormBorderStyle.FixedDialog;
        // Create Tab Control. 
        CPHLogger.LogV("[LoadStartupConfigForm] Create main TabControl for the form.");
        var tabControl = BuildCoreForm(activeWindowRect);
        // Add tabs with their specific configurations

        // Add TabControl to the form
        CPHLogger.LogV("[LoadStartupConfigForm] Add TabControl to FormControl.");
        Controls.Add(tabControl);
        //LogAllControlSizes();
        // Refresh Layout.
        CPHLogger.LogV("[LoadStartupConfigForm] Refresh Layout.");
        this.SuspendLayout();
        this.ResumeLayout();


        
        // Log Results. 
        LogAllControlSizes();
    }


  public void LogAllControlSizes()
  {
    CPHLogger.LogI("Logging sizes of all controls in the form...");
    LogControlDetails(this); // Start logging from the form itself
  }

private void LogControlDetails(Control parent, int depth = 0)
{
    // Indentation for nested controls
    string indent = new string(' ', depth * 4);

    // Log the current control's basic details
    CPHLogger.LogI($"{indent}Control: {parent.Name ?? parent.GetType().Name}, " +
                   $"Type: {parent.GetType().Name}, " +
                   $"Size: {parent.Size.Width}x{parent.Size.Height}, " +
                   $"Location: {parent.Location.X},{parent.Location.Y}, " +
                   $"Dock: {parent.Dock}, " +
                   $"Anchor: {parent.Anchor}, " +
                   $"AutoSize: {parent.AutoSize}, " +
                   $"AutoSizeMode: {(parent is TableLayoutPanel tlp ? tlp.AutoSizeMode.ToString() : "N/A")}, " +
                   $"MinimumSize: {parent.MinimumSize.Width}x{parent.MinimumSize.Height}, " +
                   $"MaximumSize: {parent.MaximumSize.Width}x{parent.MaximumSize.Height}, " +
                   $"Margin: {parent.Margin.Left},{parent.Margin.Top},{parent.Margin.Right},{parent.Margin.Bottom}, " +
                   $"Padding: {parent.Padding.Left},{parent.Padding.Top},{parent.Padding.Right},{parent.Padding.Bottom}, " +
                   $"Text: \"{parent.Text}\"");

    // Log default values and differences for some standard control properties
    LogDefaultValuesComparison(parent, indent);

    // Iterate through child controls recursively
    foreach (Control child in parent.Controls)
    {
        LogControlDetails(child, depth + 1);
    }
}

private void LogDefaultValuesComparison(Control control, string indent)
{
    // Create a new instance of the same control type to compare defaults
    try
    {
        var defaultInstance = (Control)Activator.CreateInstance(control.GetType());

        // Compare some common properties
        if (control.Dock != defaultInstance.Dock)
            CPHLogger.LogD($"{indent}  Difference in Dock: Current={control.Dock}, Default={defaultInstance.Dock}");
        if (control.Anchor != defaultInstance.Anchor)
            CPHLogger.LogD($"{indent}  Difference in Anchor: Current={control.Anchor}, Default={defaultInstance.Anchor}");
        if (control.AutoSize != defaultInstance.AutoSize)
            CPHLogger.LogD($"{indent}  Difference in AutoSize: Current={control.AutoSize}, Default={defaultInstance.AutoSize}");
        if (control.Font != defaultInstance.Font)
            CPHLogger.LogD($"{indent}  Difference in Font: Current={control.Font}, Default={defaultInstance.Font}");
        if (control.Margin != defaultInstance.Margin)
            CPHLogger.LogD($"{indent}  Difference in Margin: Current={control.Margin}, Default={defaultInstance.Margin}");
        if (control.Padding != defaultInstance.Padding)
            CPHLogger.LogD($"{indent}  Difference in Padding: Current={control.Padding}, Default={defaultInstance.Padding}");

        // Dispose the default instance to free resources
        defaultInstance.Dispose();
    }
    catch (Exception ex)
    {
        CPHLogger.LogE($"{indent}  Failed to compare default values: {ex.Message}");
    }
}



    /// <summary>
    /// Builds the main tab control for the form.
    /// </summary>
    /// <param name = "activeWindowRect">Rectangle dimensions for centering (not used in this example).</param>
    /// <returns>The constructed TabControl instance.</returns>
    private TabControl BuildCoreForm(Rectangle activeWindowRect)
    {
        var tabControl = ControlFactory.CreateTabControl();
        AddTabWithControls(tabControl, "Startup", AddStartupTabControls);
        return tabControl;
    }

    /// <summary>
    /// Adds a new tab to the TabControl and populates it with controls.
    /// </summary>
    /// <param name = "tabControl">The main TabControl to add the tab to.</param>
    /// <param name = "title">The title of the tab.</param>
    /// <param name = "addControls">An Action that adds controls to the tab.</param>
    private void AddTabWithControls(TabControl tabControl, string title, Action<TabPage> addControls)
    {
        CPHLogger.LogD($"[S]AddTabWithControls. TabControl: {tabControl}, Title: {title} Control action: {addControls}");
        var tabPage = ControlFactory.CreateTabPage(title);
        addControls(tabPage);
        tabControl.TabPages.Add(tabPage);
        CPHLogger.LogD($"[S]AddTabWithControls. TabControl: {tabControl}, Title: {title} TabPage count: {tabControl.TabPages.Count}");
    }


    /// <summary>
    /// Populates the "Startup" tab with the necessary controls.
    /// </summary>
    /// <param name = "startupTab">The tab page to populate.</param>
    private void AddStartupTabControls(TabPage startupTab)
    {
        // Create the layout for the tab
        var layout = ControlFactory.CreateTableLayoutPanel(6, 1);
        // Add different sections of the tab
        layout.Controls.Add(BuildConfigSection());
        layout.Controls.Add(BuildApplicationSection());
        layout.Controls.Add(BuildAllowedActionsSection());
        layout.Controls.Add(BuildBlockedActionsSection());
        layout.Controls.Add(BuildFlowControlButtons());
        // Add the layout to the tab page
        startupTab.Controls.Add(layout);
    }

    /// <summary>
    /// Creates the configuration section group box.
    /// </summary>
    /// <returns>A GroupBox containing configuration controls.</returns>
    private GroupBox BuildConfigSection()
    {
        CPHLogger.LogD($"[S]BuildCoreForm. Create configuration management section.");
        var groupBox = ControlFactory.CreateGroupBox("Manage your configuration");
        // Create the layout for buttons
        CPHLogger.LogV($"BuildCoreForm. Create table to help layout of management section buttons.");
        var layout = ControlFactory.CreateTableLayoutPanel(1, 5);
        // Add buttons for different configuration actions
        CPHLogger.LogV($"BuildCoreForm. Create Buttons.");
        layout.Controls.Add(ControlFactory.CreateButton("Remove All", _eventHandlers.ResetSettings_Click, Constants.ButtonStyle.Primary));
        layout.Controls.Add(ControlFactory.CreateButton("Import", _eventHandlers.ImportSettings_Click, Constants.ButtonStyle.Primary));
        layout.Controls.Add(ControlFactory.CreateButton("Export", _eventHandlers.ExportSettings_Click, Constants.ButtonStyle.Primary));
        layout.Controls.Add(ControlFactory.CreateButton("About", _eventHandlers.ShowAbout_Click, Constants.ButtonStyle.Primary));
        layout.Controls.Add(ControlFactory.CreateButton("Test", _eventHandlers.TestConfig_Click, Constants.ButtonStyle.Primary));
        // Add the layout to the group box
        CPHLogger.LogV($"BuildCoreForm. Add the layout to the groupbox, and return it.");
        groupBox.Controls.Add(layout);
        return groupBox;
    }

    /// <summary>
    /// Creates the application section group box.
    /// </summary>
    /// <returns>A GroupBox containing application management controls.</returns>
    private GroupBox BuildApplicationSection()
    {
        CPHLogger.LogD($"[S]BuildCoreForm. Create application management section.");
        var groupBoxApplicationControls = ControlFactory.CreateGroupBox("Applications to run on bot startup");

        // Create the layout for the section
        CPHLogger.LogV($"BuildCoreForm. Create table to help layout of management section buttons.");
        var tableLayoutApplicationControls = ControlFactory.CreateTableLayoutPanel(2, 2);

        // Add a list box for applications
        CPHLogger.LogV($"BuildCoreForm. Create table to help layout of management section buttons.");
        var listBoxApplicationsChosen = ControlFactory.CreateListBox();
        tableLayoutApplicationControls.Controls.Add(listBoxApplicationsChosen, 0, 0);

        // Add action buttons for applications
        CPHLogger.LogV($"BuildCoreForm. Create table to help layout of management section buttons.");
        var flowpanelApplicationControls = new FlowLayoutPanel
        {
            FlowDirection = FlowDirection.TopDown,
            Dock = DockStyle.Fill,
            AutoSize = true
        };


        CPHLogger.LogV($"BuildCoreForm. Create table to help layout of management section buttons.");
        flowpanelApplicationControls.Controls.Add(ControlFactory.CreateButton("Add Application", _eventHandlers.AddApplication_Click, Constants.ButtonStyle.Longer));
        flowpanelApplicationControls.Controls.Add(ControlFactory.CreateButton("Remove Application", _eventHandlers.RemoveApplication_Click, Constants.ButtonStyle.Longer));
        flowpanelApplicationControls.Controls.Add(ControlFactory.CreateButton("Add Path", _eventHandlers.AddPath_Click, Constants.ButtonStyle.Longer));
        tableLayoutApplicationControls.Controls.Add(flowpanelApplicationControls, 1, 0);


        FlowLayoutPanel fpanelApplicationArrows = ControlFactory.CreateFlowLayoutPanel(
            FlowDirection.LeftToRight,
            DockStyle.Fill,
            autoSize: true,
            margin: new Padding(0),
            padding: new Padding(0),
            backColor: Color.WhiteSmoke
        );

        fpanelApplicationArrows.Controls.Add(ControlFactory.CreateButton("▲", _eventHandlers.RemoveApplication_Click, Constants.ButtonStyle.ArrowBtn));
        fpanelApplicationArrows.Controls.Add(ControlFactory.CreateButton("▼", _eventHandlers.AddPath_Click, Constants.ButtonStyle.ArrowBtn));

        tableLayoutApplicationControls.Controls.Add(fpanelApplicationArrows, 0, 1);

        // Add the layout to the group box
        groupBoxApplicationControls.Controls.Add(tableLayoutApplicationControls);
        return groupBoxApplicationControls;
    }

    /// <summary>
    /// Creates the "Allowed Actions" section.
    /// </summary>
    /// <returns>A GroupBox containing controls for allowed actions.</returns>
    private GroupBox BuildAllowedActionsSection()
    {
        return BuildActionSection("Allowed Actions", _eventHandlers.AddAllowedAction_Click, _eventHandlers.RemoveAllowedAction_Click);
    }

    /// <summary>
    /// Creates the "Blocked Actions" section.
    /// </summary>
    /// <returns>A GroupBox containing controls for blocked actions.</returns>
    private GroupBox BuildBlockedActionsSection()
    {
        return BuildActionSection("Blocked Actions", _eventHandlers.AddBlockedAction_Click, _eventHandlers.RemoveBlockedAction_Click);
    }

    /// <summary>
    /// Creates an action section group box (e.g., Allowed or Blocked Actions).
    /// </summary>
    /// <param name = "title">The title of the section.</param>
    /// <param name = "addClick">Event handler for the Add button.</param>
    /// <param name = "removeClick">Event handler for the Remove button.</param>
    /// <returns>A GroupBox containing controls for the action section.</returns>
    private GroupBox BuildActionSection(string title, EventHandler addClick, EventHandler removeClick)
    {
        var groupBox = ControlFactory.CreateGroupBox(title);
        // Create the layout for the section
        var layout = ControlFactory.CreateTableLayoutPanel(1, 2);
        // Add a list box
        var listBox = ControlFactory.CreateListBox();
        layout.Controls.Add(listBox, 0, 0);
        // Add action buttons
        var buttonPanel = new FlowLayoutPanel
        {
            FlowDirection = FlowDirection.TopDown,
            Dock = DockStyle.Fill,
            
            AutoSize = true
        };
        buttonPanel.Controls.Add(ControlFactory.CreateButton("Add Action", addClick, Constants.ButtonStyle.Longer));
        buttonPanel.Controls.Add(ControlFactory.CreateButton("Remove Action", removeClick, Constants.ButtonStyle.Longer));
        layout.Controls.Add(buttonPanel, 1, 0);
        groupBox.Controls.Add(layout);
        return groupBox;
    }

    /// <summary>
    /// Creates the flow control buttons at the bottom of the tab.
    /// </summary>
    /// <returns>A FlowLayoutPanel containing Save and Close buttons.</returns>
    private FlowLayoutPanel BuildFlowControlButtons()
    {
        var panel = new FlowLayoutPanel
        {
            FlowDirection = FlowDirection.LeftToRight,
            Dock = DockStyle.Bottom,
            
            AutoSize = true
        };
        panel.Controls.Add(ControlFactory.CreateButton("Save", _eventHandlers.SaveSettings_Click, Constants.ButtonStyle.FlowControl));
        panel.Controls.Add(ControlFactory.CreateButton("Close", _eventHandlers.CloseForm_Click, Constants.ButtonStyle.FlowControl));
        return panel;
    }
}

public class ApplicationFileDetails
{
    public string FileName { get; set; }
    public string FullPath { get; set; }
    public int Index { get; set; } // New property to store the index

    public ApplicationFileDetails(string fullPath, int index)
    {
        FullPath = fullPath;
        FileName = Path.GetFileName(fullPath);
        Index = index; // Initialize the index
    }

    public override string ToString()
    {
        return FileName;
    }
}

public class StartupManagerSettings
{
    public LoadOnStartupConfig LoadOnStartup { get; set; }
    public List<ApplicationConfig> Applications { get; set; }
    public ActionConfigs Actions { get; set; }
    public UserSettingsConfig UserSettings { get; set; }
}

public class LoadOnStartupConfig
{
    public bool Enabled { get; set; }
    public string Mode { get; set; } // Options: "Yes", "No", "Prompt"
    public int DelayInSeconds { get; set; }
}

public class ApplicationConfig
{
    public string Path { get; set; }
    public bool IsEnabled { get; set; }
    public int Order { get; set; }
}

public class ActionConfigs
{
    public List<ActionConfig> Permitted { get; set; }
    public List<ActionConfig> Blocked { get; set; }
}

public class ActionConfig
{
    public string Name { get; set; }
    public bool IsEnabled { get; set; }
    public int Order { get; set; }
}

public class UserSettingsConfig
{
    public bool ResetConfig { get; set; }
    public ExportImportConfig ExportSettings { get; set; }
    public ExportImportConfig ImportSettings { get; set; }
    public DateTime LastSaveTime { get; set; }
}

public class ExportImportConfig
{
    public string Path { get; set; }
}

public static class Constants
{
    public const string ExecutableFilter = "Executable Files (*.exe)|*.exe|All Files (*.*)|*.*";
    public const string SettingsFileName = "settings.json";
    public const string FormName = "SBZen Config Manager";
    public static readonly string DataDir = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "data");
    public static readonly Color FormColour = Color.WhiteSmoke;
    public enum StartupMode
    {
        Yes,
        No,
        Prompt,
    }

    public enum ButtonStyle
    {
        Default, // White background, black text
        Primary, // Blue background, white text
        Secondary, // Gray background, black text
        Danger, // Red background, white text
        IconBtn, // Icon-only button
        ArrowBtn, 
        Longer, 
        FlowControl
    }
}

public class CPHLogger : SB
{
    // LogD: Logs a debug-level message.
    public static void LogD(string message)
    {
        CPH.LogDebug($"[DEBUG] {message}");
    }

    // LogE: Logs an error-level message.
    public static void LogE(string message)
    {
        CPH.LogError($"[ERROR] {message}");
    }

    // LogI: Logs an info-level message.
    public static void LogI(string message)
    {
        CPH.LogInfo($"[INFO] {message}");
    }

    // LogV: Logs a verbose-level message.
    public static void LogV(string message)
    {
        CPH.LogVerbose($"[VERBOSE] {message}");
    }

    // LogWarn: Logs a warning-level message.
    public static void LogW(string message)
    {
        CPH.LogWarn($"[WARN] {message}");
    }
}

public class SB
{
    public static IInlineInvokeProxy CPH;
    public static Dictionary<string, object> args;
}

/// <summary>
/// Handles all event actions for buttons in the configuration manager.
/// </summary>
public class EventHandlers
{
    public void ResetSettings_Click(object sender, EventArgs e) => CPHLogger.LogI("Reset settings clicked.");
    public void ImportSettings_Click(object sender, EventArgs e) => CPHLogger.LogI("Import settings clicked.");
    public void ExportSettings_Click(object sender, EventArgs e) => CPHLogger.LogI("Export settings clicked.");
    public void ShowAbout_Click(object sender, EventArgs e) => CPHLogger.LogI("Show about clicked.");
    public void TestConfig_Click(object sender, EventArgs e) => CPHLogger.LogI("Test configuration clicked.");
    public void AddApplication_Click(object sender, EventArgs e) => CPHLogger.LogI("Add application clicked.");
    public void RemoveApplication_Click(object sender, EventArgs e) => CPHLogger.LogI("Remove application clicked.");
    public void AddPath_Click(object sender, EventArgs e) => CPHLogger.LogI("Add application path clicked.");
    public void AddAllowedAction_Click(object sender, EventArgs e) => CPHLogger.LogI("Add allowed action clicked.");
    public void RemoveAllowedAction_Click(object sender, EventArgs e) => CPHLogger.LogI("Remove allowed action clicked.");
    public void AddBlockedAction_Click(object sender, EventArgs e) => CPHLogger.LogI("Add blocked action clicked.");
    public void RemoveBlockedAction_Click(object sender, EventArgs e) => CPHLogger.LogI("Remove blocked action clicked.");
    public void SaveSettings_Click(object sender, EventArgs e) => CPHLogger.LogI("Save settings clicked.");
    public void CloseForm_Click(object sender, EventArgs e) => Application.Exit();
}





public static class ControlFactory
{
    public static TabControl CreateTabControl()
    {
        var tabControl = new TabControl
        {
            AutoSize = true,
            Dock = DockStyle.Fill,
            Font = new Font("Segoe UI", 10),
            Appearance = TabAppearance.Normal
        };
        return tabControl;
    }

    public static TabPage CreateTabPage(string title)
    {
        return new TabPage
        {
            Text = title,
            AutoSize = true,
            Dock = DockStyle.Fill,
            BackColor = Constants.FormColour,
            Padding = new Padding(5),
            Font = new Font("Segoe UI", 10)
        };
    }

    public static Label CreateLabel(string text)
    {
        var label = new Label
        {
            Text = text,
            AutoSize = true,
            Dock = DockStyle.Fill,
            TextAlign = ContentAlignment.MiddleLeft,
            Margin = new Padding(5)
            Padding = new Padding(5)
        };
        CPHLogger.LogV($"Label created. Properties: Text: {text} Text: {text} Text: {text} Text: {text}");
        return label;
    }


    public static Button CreateButton(string text, EventHandler clickEvent = null, Constants.ButtonStyle buttonStyle = Constants.ButtonStyle.Default, bool btnEnabled = true )
    {
        // Create a base button with common properties
        var btn = new Button
        {
            Text = text,
            Height = 24,
            Enabled = btnEnabled,
            AutoSize = false,
            FlatStyle = FlatStyle.Flat,
            Font = new Font("Microsoft Sans Serif", 8.5f),
            BackColor = Color.White,
            ForeColor = SystemColors.ControlText,
        };
        // Apply different styles based on the ButtonStyle enum
        switch (buttonStyle)
        {
            case Constants.ButtonStyle.Primary:
                btn.Width = 90;
                btn.Margin = new Padding(0, 0, 0, 0);
                btn.Padding = new Padding(2, 2, 2, 2);
                
                btn.BackColor = Color.DodgerBlue;
                btn.ForeColor = Color.White;
                btn.FlatAppearance.BorderSize = 1;
                btn.FlatAppearance.BorderColor = Color.RoyalBlue;
                break;
            case Constants.ButtonStyle.Longer:
                btn.Width = 120;
                btn.Margin = new Padding(1, 3, 1, 1);
                btn.Padding = new Padding(2, 2, 2, 2);

                btn.BackColor = Color.Gainsboro;
                btn.ForeColor = Color.Black;
                btn.FlatAppearance.BorderSize = 1;
                btn.FlatAppearance.BorderColor = Color.DarkGray;
                break;
            case Constants.ButtonStyle.ArrowBtn:
                btn.Width = 20;
                btn.Height = 20;
                btn.Margin = new Padding(1, 0, 1, 0);
                btn.Padding = new Padding(0, 0, 0, 0);

                btn.BackColor = Color.White;
                btn.ForeColor = SystemColors.ControlText;
                btn.FlatAppearance.BorderSize = 1;
                btn.FlatAppearance.BorderColor = Color.DarkGray;
                btn.BackgroundImageLayout = ImageLayout.Center;
                break;    

            case Constants.ButtonStyle.FlowControl:
                btn.Width = 100;
                btn.Margin = new Padding(5, 2, 5, 2); 
                btn.Padding = new Padding(5, 0, 5, 0); 

                btn.BackColor = Color.White;
                btn.ForeColor = SystemColors.ControlText;
                btn.FlatAppearance.BorderSize = 1;
                btn.FlatAppearance.BorderColor = Color.DarkGray;
                btn.BackgroundImageLayout = ImageLayout.Center;
                break;    

            case Constants.ButtonStyle.Danger: 
                btn.BackColor = Color.Red;
                btn.ForeColor = Color.White;
                btn.FlatAppearance.BorderColor = Color.DarkRed;
                break;
            case Constants.ButtonStyle.IconBtn:
                btn.Text = string.Empty; // For icon buttons, text is empty
                btn.Width = btn.Height; // Icon buttons are square
                btn.BackgroundImageLayout = ImageLayout.Center;
                break;
            
            default:
                // Default button style (white background, black text)
                btn.Width = 90;
                btn.Margin = new Padding(2, 2, 2, 2);
                btn.Padding = new Padding(2, 2, 2, 2);
                     
                
                btn.BackColor = Color.White;
                btn.ForeColor = SystemColors.ControlText;
                btn.FlatAppearance.BorderSize = 1;
                btn.FlatAppearance.BorderColor = Color.DarkGray;
                btn.BackgroundImageLayout = ImageLayout.Center;
                break;
        }

        // Attach the click event handler if provided
        if (clickEvent != null)
        {
            btn.Click += clickEvent;
            CPHLogger.LogD($"Button '{text}' attached to event handler.");
        }

        CPHLogger.LogD($"Button created: Text='{text}', Style='{buttonStyle}', Size={btn.Width}x{btn.Height}");
        return btn;
    }

    public static ListBox CreateListBox()
    {
        var listBox = new ListBox
        {
            //AutoSize = true,
            Dock = DockStyle.Fill,
            Height = 240,
            Padding = new Padding(5, 5, 5, 0),
            Margin = new Padding(5, 5, 5, 0),
            
            //Width = 250,

            Font = new Font("Segoe UI", 10, FontStyle.Regular),
            BackColor = Color.White,
            ForeColor = Color.Black,
            BorderStyle = BorderStyle.FixedSingle
        };
        CPHLogger.LogD("ListBox created.");
        return listBox;
    }


    public static GroupBox CreateGroupBox(string text)
    {
        var groupBox = new GroupBox
        {
            AutoSize = true,
            Dock = DockStyle.Fill,
            Padding = new Padding(2, 2, 2, 2),
            Margin = new Padding(2, 2, 2, 2),

            Text = text,
            Font = new Font("Segoe UI", 10, FontStyle.Bold),
            ForeColor = Color.DimGray,
            BackColor = Color.WhiteSmoke
        };
        CPHLogger.LogD($"GroupBox created with text: {text}");
        return groupBox;
    }


public static FlowLayoutPanel CreateFlowLayoutPanel(
    FlowDirection flowDirection = FlowDirection.LeftToRight,
    DockStyle dockStyle = DockStyle.None,
    bool autoSize = true,
    Padding? margin = null,
    Padding? padding = null,
    Color? backColor = null)
{
    var flowLayout = new FlowLayoutPanel
    {
        FlowDirection = flowDirection,
        Dock = dockStyle,
        AutoSize = autoSize,
        AutoSizeMode = AutoSizeMode.GrowOnly,
        WrapContents = true,
        Margin = margin ?? new Padding(0),
        Padding = padding ?? new Padding(0),
        BackColor = backColor ?? Color.Transparent,
    };

    // Verbose logging for debug
    CPHLogger.LogD($"FlowLayoutPanel created: FlowDirection={flowDirection}, Dock={dockStyle}, AutoSize={autoSize}, " +
                   $"Margin={flowLayout.Margin}, Padding={flowLayout.Padding}, BackColor={flowLayout.BackColor}");
    return flowLayout;
}


    public static TableLayoutPanel CreateTableLayoutPanel(int rowCount, int columnCount)
    {
        var tableLayout = new TableLayoutPanel
        {
            Dock = DockStyle.Fill,
            Height = 340,
            ColumnCount = columnCount,
            RowCount = rowCount,
            AutoSize = false,
            AutoSizeMode = AutoSizeMode.GrowOnly,
            CellBorderStyle = TableLayoutPanelCellBorderStyle.Single,
            Padding = new Padding(5)
        };


        
        for (int i = 0; i < columnCount; i++)
        {
            tableLayout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100f / columnCount));
        }

        for (int i = 0; i < rowCount; i++)
        {
            tableLayout.RowStyles.Add(new RowStyle(SizeType.Absolute, 340)); // Fixed height rows
        }

        CPHLogger.LogD($"TableLayoutPanel created with {rowCount} rows and {columnCount} columns.");
        return tableLayout;
    }
}