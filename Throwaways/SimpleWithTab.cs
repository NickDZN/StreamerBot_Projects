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
        // Create centralized SB instance.
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

        // Get the window details of the main Streamer.bot instance which this is loaded from
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
        CPHLogger.LogI($"Raw Rectangle Values: Left={activeWindowRect.Left}, Top={activeWindowRect.Top}, Right={activeWindowRect.Right}, Bottom={activeWindowRect.Bottom}");
        // Validate and adjust window dimensions and position
        if (activeWindowRect.Top > activeWindowRect.Bottom || activeWindowRect.Height < 0)
        {
            activeWindowRect.Height = Math.Abs(activeWindowRect.Bottom - activeWindowRect.Top);
            CPHLogger.LogW($"Negative height detected. Corrected Height: {activeWindowRect.Height}");
        }

        if (activeWindowRect.Left > activeWindowRect.Right || activeWindowRect.Width < 0)
        {
            activeWindowRect.Width = Math.Abs(activeWindowRect.Right - activeWindowRect.Left);
            CPHLogger.LogW($"Negative width detected. Corrected Width: {activeWindowRect.Width}");
        }

        // Get the screen containing the active window
        var currentScreen = Screen.FromHandle(activeWindowHandle);
        CPHLogger.LogI($"Screen Bounds: {currentScreen.Bounds}. Working Area: {currentScreen.WorkingArea}");
        // Adjust window position to fit within the screen's working area
        int adjustedLeft = Math.Max(currentScreen.WorkingArea.Left, Math.Min(activeWindowRect.Left, currentScreen.WorkingArea.Right - activeWindowRect.Width));
        int adjustedTop = Math.Max(currentScreen.WorkingArea.Top, Math.Min(activeWindowRect.Top, currentScreen.WorkingArea.Bottom - activeWindowRect.Height));
        // Create a new Rectangle with adjusted values
        Rectangle adjustedRect = new Rectangle(adjustedLeft, adjustedTop, activeWindowRect.Width, activeWindowRect.Height);
        CPHLogger.LogI($"Adjusted Window Position: {adjustedRect}");
        // Log DPI scaling factors
        using (Graphics g = Graphics.FromHwnd(activeWindowHandle))
        {
            float dpiXScale = g.DpiX / 96.0f;
            float dpiYScale = g.DpiY / 96.0f;
            CPHLogger.LogI($"DPI Scaling Factors: Horizontal={dpiXScale}x, Vertical={dpiYScale}x (DPI Values: {g.DpiX}, {g.DpiY})");
        }

        // Log all screens and their DPI scaling factors
        foreach (var individualScreen in Screen.AllScreens)
        {
            using (Graphics g = Graphics.FromHwnd(activeWindowHandle))
            {
                float screenDpiX = g.DpiX;
                float screenDpiY = g.DpiY;
                CPHLogger.LogI($"Screen {individualScreen.DeviceName}: DPI Scaling Horizontal={screenDpiX / 96.0f}x, Vertical={screenDpiY / 96.0f}x");
            }
        }

        // Determine if the adjusted rectangle is fully contained in any screen
        bool isFullyContained = Screen.AllScreens.Any(s => s.Bounds.Contains(adjustedRect));
        CPHLogger.LogI($"Window Fully Contained in One Screen: {isFullyContained}");
        foreach (var individualScreen in Screen.AllScreens)
        {
            CPHLogger.LogI($"Screen: {individualScreen.DeviceName}, Bounds: {individualScreen.Bounds}, Working Area: {individualScreen.WorkingArea}");
        }

        // Start new thread for the form
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
                    mainFormInstance = new LoadStartupConfigForm(adjustedRect, actionList);
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
        CPHLogger.LogI($"[S]LoadStartupConfigForm. {activeWindowRect.Size}");
        // Initialise Event Handlers.
        CPHLogger.LogV("[LoadStartupConfigForm] Initialise Event Handlers");
        _eventHandlers = new EventHandlers();
        // Set Form Properties. 
        CPHLogger.LogV("[LoadStartupConfigForm] Set form variables");
        this.Text = Constants.FormName;
        
        this.Size = new Size(400, 400);
        this.MinimumSize = new Size(100, 100);
        this.MaximumSize = new Size(10000, 10000);
        this.AutoSize = true;
        this.AutoSizeMode = AutoSizeMode.GrowAndShrink;
        this.BackColor = Constants.FormColour;
        this.Font = new Font("Segoe UI", 10);
        CPHLogger.LogI($"[S]SIZELOGGING. {activeWindowRect.Size}");
        this.FormBorderStyle = FormBorderStyle.FixedDialog;
        CPHLogger.LogI($"[S]SIZELOGGING. {activeWindowRect.Size}");
        // Create Tab Control. 
        CPHLogger.LogV("[LoadStartupConfigForm] Create main TabControl for the form.");
        var tabControl = BuildCoreForm(activeWindowRect);
        CPHLogger.LogI($"[S]SIZELOGGING. {activeWindowRect.Size}");
        CPHLogger.LogI($"[S]SIZELOGGING. {tabControl.Size}");
        // Add TabControl to the form
        CPHLogger.LogV("[LoadStartupConfigForm] Add TabControl to FormControl.");
        Controls.Add(tabControl);
        // Refresh Layout.
        CPHLogger.LogV("[LoadStartupConfigForm] Refresh Layout.");
        this.SuspendLayout();
        this.ResumeLayout();
        // Log Results. 
        LogAllControlSizes();
    }

    /// <summary>
    /// Builds the main tab control for the form.
    /// </summary>
    /// <param name = "activeWindowRect">Rectangle dimensions for centering (not used in this example).</param>
    /// <returns>The constructed TabControl instance.</returns>
    private TabControl BuildCoreForm(Rectangle activeWindowRect)
    {
        var formTabControls = ControlFactory.CreateTabControl();
        // Create a TabPage for the "Startup" tab
        var startupTab = ControlFactory.CreateTabPage("Startup");
        // Add controls to the TabPage
        AddStartupTabControls(startupTab);
        // Add the TabPage to the TabControl
        formTabControls.TabPages.Add(startupTab);
        return formTabControls;
    }

    /// <summary>
    /// Populates the "Startup" tab with the necessary controls.
    /// </summary>
    /// <param name = "startupTab">The tab page to populate.</param>
    private void AddStartupTabControls(TabPage startupTabPage)
    {
        // Create the layout for the tab
        var layout = ControlFactory.CreateBaseTableLayoutPanel(6, 1);
        // Add sections to the layout
        layout.Controls.Add(BuildConfigSection(), 0, 0);
        layout.Controls.Add(BuildApplicationSection());
        // Add the layout to the TabPage (NOT directly to TabControl)
        startupTabPage.Controls.Add(layout);
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
        FlowLayoutPanel fpanelApplicationArrows = ControlFactory.CreateFlowLayoutPanel(FlowDirection.LeftToRight, DockStyle.Fill, autoSize: true, margin: new Padding(0), padding: new Padding(0), backColor: Color.WhiteSmoke);
        fpanelApplicationArrows.Controls.Add(ControlFactory.CreateButton("▲", _eventHandlers.RemoveApplication_Click, Constants.ButtonStyle.ArrowBtn));
        fpanelApplicationArrows.Controls.Add(ControlFactory.CreateButton("▼", _eventHandlers.AddPath_Click, Constants.ButtonStyle.ArrowBtn));
        tableLayoutApplicationControls.Controls.Add(fpanelApplicationArrows, 0, 1);
        // Add the layout to the group box
        groupBoxApplicationControls.Controls.Add(tableLayoutApplicationControls);
        return groupBoxApplicationControls;
    }

    public void LogAllControlSizes()
    {
        CPHLogger.LogI("Logging sizes of all controls in the form...");
        LogControlDetails(this); // Start logging from the form itself
    }

    private void LogControlDetails(Control parent, int depth = 0)
    {
        // Indentation for nested controls
        string indent = new string (' ', depth * 4);
        // Log the current control's basic details
        CPHLogger.LogI($"{indent}Control: {parent.Name ?? parent.GetType().Name}, " + $"Type: {parent.GetType().Name}, " + $"Size: {parent.Size.Width}x{parent.Size.Height}, " + $"Location: {parent.Location.X},{parent.Location.Y}, " + $"Dock: {parent.Dock}, " + $"Anchor: {parent.Anchor}, " + $"AutoSize: {parent.AutoSize}, " + $"AutoSizeMode: {(parent is TableLayoutPanel tlp ? tlp.AutoSizeMode.ToString() : "N/A")}, " + $"MinimumSize: {parent.MinimumSize.Width}x{parent.MinimumSize.Height}, " + $"MaximumSize: {parent.MaximumSize.Width}x{parent.MaximumSize.Height}, " + $"Margin: {parent.Margin.Left},{parent.Margin.Top},{parent.Margin.Right},{parent.Margin.Bottom}, " + $"Padding: {parent.Padding.Left},{parent.Padding.Top},{parent.Padding.Right},{parent.Padding.Bottom}, " + $"Text: \"{parent.Text}\"");
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
}

public static class Constants
{
    public const string FormName = "SBZen Config Manager";
    public static readonly Color FormColour = Color.WhiteSmoke;
    public enum ButtonStyle
    {
        Default, // White background, black text
        Primary, // Blue background, white text
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
}

public static class ControlFactory
{
    public static TabControl CreateTabControl()
    {
        var tabControl = new TabControl
        {
            AutoSize = false,
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
            Dock = DockStyle.Fill,
            BackColor = Constants.FormColour,
            AutoSize = true,
            //Anchor = AnchorStyles.Top | AnchorStyles.Bottom | AnchorStyles.Left | AnchorStyles.Right,
            Padding = new Padding(5),
            Font = new Font("Segoe UI", 10)
        };
    }

    public static Button CreateButton(string text, EventHandler clickEvent = null, Constants.ButtonStyle buttonStyle = Constants.ButtonStyle.Default, bool btnEnabled = true)
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
                btn.Dock = DockStyle.Fill;
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

    public static FlowLayoutPanel CreateFlowLayoutPanel(FlowDirection flowDirection = FlowDirection.LeftToRight, DockStyle dockStyle = DockStyle.None, bool autoSize = false, Padding? margin = null, Padding? padding = null, Color? backColor = null)
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
        CPHLogger.LogD($"FlowLayoutPanel created: FlowDirection={flowDirection}, Dock={dockStyle}, AutoSize={autoSize}, " + $"Margin={flowLayout.Margin}, Padding={flowLayout.Padding}, BackColor={flowLayout.BackColor}");
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
            AutoSize = true,
            AutoSizeMode = AutoSizeMode.GrowOnly,
            CellBorderStyle = TableLayoutPanelCellBorderStyle.Single,
            Padding = new Padding(5)
        };
        for (int i = 0; i < tableLayout.ColumnCount; i++)
        {
            tableLayout.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        }

        CPHLogger.LogD($"TableLayoutPanel created with {rowCount} rows and {columnCount} columns.");
        return tableLayout;
    }

    public static TableLayoutPanel CreateBaseTableLayoutPanel(int rowCount, int columnCount)
    {
        var tableLayout = new TableLayoutPanel
        {
            Dock = DockStyle.Fill,
            ColumnCount = columnCount,
            RowCount = rowCount,
            AutoSize = true,
            AutoSizeMode = AutoSizeMode.GrowOnly,
            CellBorderStyle = TableLayoutPanelCellBorderStyle.Single,
            Padding = new Padding(5)
        };
        CPHLogger.LogD($"TableLayoutPanel created with {rowCount} rows and {columnCount} columns.");
        return tableLayout;
    }
}