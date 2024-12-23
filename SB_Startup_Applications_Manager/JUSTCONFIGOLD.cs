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

public class CPHInline
{
    private static LoadStartupConfigForm mainFormInstance = null;


    // Importing user32.dll to get the rectangle of a window
    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool GetWindowRect(IntPtr hWnd, out Rectangle lpRect);

    // Main method that executes the logic for setting up and displaying the form
    public bool Execute()
    {
        try
        {
            // Set up a static reference for CPH and arguments
            CPH.LogDebug("SBSAM Loaded.");
            SB.CPH = CPH;
            SB.args = args;
        }
        catch (Exception ex)
        {
            return CPHLogger.LogE($"Unable to create static CPH reference: {ex.Message}\n{ex.StackTrace}");
        }

        // Get details of where to open new form and start population. 
        try
        {
            CPHLogger.LogV("Attempting to get process details");

            // Retrieve the current process, representing Streamer.bot
            Process currentProcess = Process.GetCurrentProcess();
            LayoutLogger.logProcessDetails(currentProcess);

            // Verify that the main window handle of the process is valid
            if (currentProcess.MainWindowHandle == IntPtr.Zero)
            {
                CPHLogger.LogE("Main window handle is invalid. Streamer.bot is either not running, or running headlessly.");
                return false;
            }

            // Retrieve the rectangle of the main window
            if (!GetWindowRect(currentProcess.MainWindowHandle, out Rectangle windowRect))
            {
                CPHLogger.LogE("Failed to retrieve the window rectangle.");
                return false;
            }

            // Log the dimensions of the Streamer.bot window
            CPHLogger.LogI($"Streamer.bot Window Rect: {windowRect}");
            LayoutLogger.logRectDetails(windowRect);

            // Step 3: Determine the monitor where the window resides
            var monitors = Screen.AllScreens; // Get all monitors connected to the system
            LayoutLogger.logMonitorDetails(monitors);

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

    // Helper method to calculate the overlap area between a window and a monitor
    private int GetOverlapArea(Rectangle windowRect, Rectangle monitorBounds)
    {
        var intersection = Rectangle.Intersect(windowRect, monitorBounds);

        CPHLogger.LogD($"Calculating overlap: Window Rect={windowRect}, Monitor Bounds={monitorBounds}");
        CPHLogger.LogD($"Intersection: {intersection}");

        int overlapArea = intersection.Width > 0 && intersection.Height > 0 
            ? intersection.Width * intersection.Height 
            : 0;

        CPHLogger.LogD($"Calculated Overlap Area: {overlapArea}");
        return overlapArea;
    }

    // Helper method to normalize the window rectangle to the bounds of a monitor
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
///
/// </summary>
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
        SetFormProps(this);
        // Create base layout.
        var coreLayoutPanelForForm = UIComponentFactory.CreateTableLayoutPanel(rows: 6, columns: 1);
        CPHLogger.LogD("Adding the required controls to the form.");
        AddUserConfigurationControlls(coreLayoutPanelForForm);

        this.Controls.Add(coreLayoutPanelForForm);
        this.SuspendLayout();
        this.ResumeLayout();
        LayoutLogger.LogAll(this);
        LayoutLogger.logRectDetails(activeWindowRect);
    }

    private void SetFormProps(Form form)
    {
        CPHLogger.LogD("[S]SetFormProps.");
        this.Text = Constants.FormName;
        //this.MinimumSize = new Size(100, 100);
        this.BackColor = Constants.FormColour;
        this.Font = new Font("Segoe UI", 10);
        this.FormBorderStyle = FormBorderStyle.FixedDialog;
        this.AutoSize = true;
    }


    /// <summary>
    ///
    /// </summary>
    /// <param name = "coreLayoutPanelForForm"></param>
    private void AddUserConfigurationControlls(TableLayoutPanel coreLayoutPanelForForm)
    {
        // Create GroupBox using the factory
        CPHLogger.LogD("[S]AddUserConfigurationControlls Creating GroupBox.");
        var configurationGroupBox = UIComponentFactory.CreateGroupBox("Manage your configuration");
        // Create TableLayoutPanel for buttons
        CPHLogger.LogV("[AddUserConfigurationControlls] Creating TableLayoutPanel for buttons.");
        var buttonTable = UIComponentFactory.CreateTableLayoutPanel(rows: 1, columns: 5, columnStyling: Constants.ColumnStyling.Distributed);
        // Add buttons to the button table
        CPHLogger.LogV("[AddUserConfigurationControlls] Adding buttons to TableLayoutPanel.");
        buttonTable.Controls.Add(UIComponentFactory.CreateButton("Reset All", Constants.ButtonStyle.Default, _eventHandlers.MainCanvasCloseButton_Click), 0, 0);
        buttonTable.Controls.Add(UIComponentFactory.CreateButton("Import", Constants.ButtonStyle.Default, _eventHandlers.MainCanvasCloseButton_Click), 1, 0);
        buttonTable.Controls.Add(UIComponentFactory.CreateButton("Export", Constants.ButtonStyle.Default, _eventHandlers.MainCanvasCloseButton_Click), 2, 0);
        buttonTable.Controls.Add(UIComponentFactory.CreateButton("About", Constants.ButtonStyle.Default, _eventHandlers.MainCanvasCloseButton_Click), 3, 0);
        buttonTable.Controls.Add(UIComponentFactory.CreateButton("Test Config", Constants.ButtonStyle.Default, _eventHandlers.MainCanvasCloseButton_Click), 4, 0);
        // Add TableLayoutPanel to GroupBox
        CPHLogger.LogV("[AddUserConfigurationControlls] Adding TableLayoutPanel to GroupBox.");
        configurationGroupBox.Controls.Add(buttonTable);
        // Add GroupBox to the main layout
        CPHLogger.LogI("[AddUserConfigurationControlls] Adding GroupBox added to form base table.");
        coreLayoutPanelForForm.Controls.Add(configurationGroupBox, 0, 0);
    }


}








public class EventHandlers
{
    public void AddApplicationPath_Click(object sender, EventArgs e)
    {
        int a = 1;
    }

    public void RemoveApplication_Click(object sender, EventArgs e)
    {
        int a = 1;
    }

    public void ApplicationListBox_SelectedIndexChanged(object sender, EventArgs e)
    {
        int a = 1;
    }

    public void AddActionPermitted_SelIndhanged(object sender, EventArgs e)
    {
        int a = 1;
    }

    public void AddActionPermitted_Click(object sender, EventArgs e)
    {
        int a = 1;
    }

    public void RemoveActionPermitted_Click(object sender, EventArgs e)
    {
        int a = 1;
    }

    public void AddActionBlocked_SelIndhanged(object sender, EventArgs e)
    {
        int a = 1;
    }

    public void AddActionBlocked_Click(object sender, EventArgs e)
    {
        int a = 1;
    }

    public void RemoveActionBlocked_Click(object sender, EventArgs e)
    {
        int a = 1;
    }

    // Start dragging the item if the mouse is pressed down
    public void ListBox_MouseDown(object sender, MouseEventArgs mouseEventArgs)
    {
        int a = 1;
    }

    // Handle moving the item if the mouse is dragged
    public void ListBox_MouseMove(object sender, MouseEventArgs mouseEventArgs)
    {
        int a = 1;
    }

    public void ListBox_DragOver(object sender, DragEventArgs dragEventArgs)
    {
        int a = 1;
    }

    public void btnApplicationsUp_Click(object sender, EventArgs clickEventArgs)
    {
        int a = 1;
    }

    public void btnApplicationsDown_Click(object sender, EventArgs clickEventArgs)
    {
        int a = 1;
    }

    // Reorder the item when dropped in a new position
    public void MainCanvasSaveButton_Click(object sender, EventArgs e)
    {
        int a = 1;
    }

    public void MainCanvasCloseButton_Click(object sender, EventArgs e)
    {
        Application.Exit();
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

public class UIComponentFactory
{
    /// <summary>
    /// Creates and styles a NumericUpDown control.
    /// </summary>
    /// <param name = "width">The width of the NumericUpDown control.</param>
    /// <param name = "height">The height of the NumericUpDown control.</param>
    /// <param name = "minimum">The minimum value for the NumericUpDown control.</param>
    /// <param name = "maximum">The maximum value for the NumericUpDown control.</param>
    /// <param name = "value">The default value for the NumericUpDown control.</param>
    /// <returns>A styled <see cref = "NumericUpDown"/> control.</returns>
    public static NumericUpDown CreateNumericUpDown(int width = 40, int height = 20, int minimum = 0, int maximum = 30, int defaultValue = 2)
    {
        var numericUpDown = new NumericUpDown
        {
            Width = width,
            Height = height,
            Minimum = minimum,
            Maximum = maximum,
            Value = defaultValue,
            Anchor = AnchorStyles.Left,
            Margin = new Padding(2, 0, 0, 0),
        };
        CPHLogger.LogV($"NumericUpDown created: Width={numericUpDown.Width}, Height={numericUpDown.Height}, Minimum={numericUpDown.Minimum}, " + $"Maximum={numericUpDown.Maximum}, DefaultValue={numericUpDown.Value}");
        return numericUpDown;
    }

    /// <summary>
    /// Creates and styles a RadioButton control.
    /// </summary>
    /// <param name = "text">The text for the RadioButton.</param>
    /// <param name = "autoSize">Indicates if the RadioButton should automatically size itself.</param>
    /// <param name = "isChecked">Indicates if the RadioButton is initially checked.</param>
    /// <returns>A styled <see cref = "RadioButton"/> control.</returns>
    public static RadioButton CreateRadioButton(string text, bool autoSize = true, bool isChecked = false)
    {
        var radioButton = new RadioButton
        {
            Text = text,
            AutoSize = autoSize,
            Dock = DockStyle.Fill,
            TextAlign = ContentAlignment.MiddleLeft,
            Checked = isChecked,
        };
        CPHLogger.LogV($"RadioButton created. Properties: Text=\"{radioButton.Text}\", AutoSize={radioButton.AutoSize}, Dock={radioButton.Dock}, " + $"TextAlign={radioButton.TextAlign}, Checked={radioButton.Checked}");
        return radioButton;
    }

    /// <summary>
    /// Creates and styles a Label control.
    /// </summary>
    /// <param name = "text">The text for the Label.</param>
    /// <param name = "textAlign">The text alignment for the Label.</param>
    /// <param name = "margin">Optional margin for the Label.</param>
    /// <param name = "padding">Optional padding for the Label.</param>
    /// <returns>A styled <see cref = "Label"/> control.</returns>
    public static Label CreateLabel(string text, ContentAlignment textAlign = ContentAlignment.MiddleLeft, Padding? margin = null, Padding? padding = null)
    {
        var label = new Label
        {
            Text = text,
            AutoSize = true,
            Dock = DockStyle.Fill,
            TextAlign = textAlign,
            Margin = margin ?? new Padding(5),
            Padding = padding ?? new Padding(5),
        };
        CPHLogger.LogV($"Label created. Properties: Text=\"{label.Text}\", AutoSize={label.AutoSize}, Dock={label.Dock}, TextAlign={label.TextAlign}, " + $"Margin={label.Margin}, Padding={label.Padding}");
        return label;
    }

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

    /// <summary>
    /// Factory for creating and styling FlowLayoutPanel controls.
    /// </summary>
    public static FlowLayoutPanel CreateFlowLayoutPanel(FlowDirection direction = FlowDirection.LeftToRight, bool wrapContents = true, bool autoSize = false, AnchorStyles anchor = AnchorStyles.Top | AnchorStyles.Left, Padding? margin = null)
    {
        var flowPanel = new FlowLayoutPanel
        {
            FlowDirection = direction,
            WrapContents = wrapContents,
            AutoSize = autoSize,
            Dock = DockStyle.Fill,
            Anchor = anchor,
            Margin = margin ?? new Padding(0),
            Padding = margin ?? new Padding(0),
            BackColor = Constants.FormColour        
        };
        CPHLogger.LogV($"FlowLayoutPanel created: Direction={flowPanel.FlowDirection}, WrapContents={flowPanel.WrapContents}, AutoSize={flowPanel.AutoSize}");
        return flowPanel;
    }

    /// <summary>
    /// Factory for creating and styling ListBox controls.
    /// </summary>
    public static ListBox CreateListBox(int? widthParam = null, int? heightParam = null, bool multiSelect = false, bool sorted = false, bool iHeight = false, AnchorStyles anchor = AnchorStyles.Left | AnchorStyles.Right)
    {
        // Create the ListBox instance
        var listBox = new ListBox
        {
            SelectionMode = multiSelect ? SelectionMode.MultiExtended : SelectionMode.One,
            Sorted = sorted,
            Anchor = anchor,
            Dock = DockStyle.Fill,
            Padding = new Padding(0),
            Margin = new Padding(0),
            IntegralHeight = iHeight,
            BackColor = Constants.Surface,
            ForeColor = Constants.PrimaryText            
        };
        // Set Width and Height only if specified (not null)
        if (widthParam.HasValue)
        {
            listBox.Width = widthParam.Value;
        }

        if (heightParam.HasValue)
        {
            listBox.Height = heightParam.Value;
        }

        // Logging for debugging
        CPHLogger.LogV($"ListBox created: Width={(widthParam.HasValue ? widthParam.Value.ToString() : "Auto")}, " + $"Height={(heightParam.HasValue ? heightParam.Value.ToString() : "Auto")}, " + $"MultiSelect={multiSelect}, Sorted={sorted}");
        return listBox;
    }
}

/// <summary>
/// A static class containing constants used throughout the application.
/// </summary>
public static class Constants
{
    public const string ExecutableFilter = "Executable Files (*.exe)|*.exe|All Files (*.*)|*.*";
    public const string SettingsFileName = "settings.json";
    public const string FormName = "SBZen Config Manager";



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



    public static readonly string DataDir = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "data");
    public enum StartupMode
    {
        Yes,
        No,
        Prompt,
    }

    public enum ButtonStyle
    {
        Default,
        Primary,
        Longer,
        ArrowBtn,
        FlowControl,
    }

    public enum RowStyling
    {
        Default,
        Distributed,
        Custom,
    }

    public enum ColumnStyling
    {
        Default,
        Distributed,
        Custom,
    }
}

/// <summary>
/// A logging class to encapsulate and provide static logging methods.
/// Inherits from the SB class to access shared functionality.
/// </summary>
public class CPHLogger : SB
{
    public static void LogD(string message) => CPH.LogDebug($"[DEBUG] {message}");
    public static void LogI(string message) => CPH.LogInfo($"[INFO] {message}");
    public static void LogV(string message) => CPH.LogVerbose($"[VERBOSE] {message}");
    public static void LogW(string message) => CPH.LogWarn($"[WARN] {message}");
    public static bool LogE(string message)
    {
        CPH.LogError($"[ERROR] {message}");
        return false;
    }
}

public static class LayoutLogger
{
    private static int controlCounter = 0;
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

    public static void logProcessDetails(Process currentProcess)
    {
        if (currentProcess == null)
        {
            CPHLogger.LogE("Process object is null. Unable to log process details.");
            return;
        }

        try
        {
            CPHLogger.LogI("=== Process Details ===");
            CPHLogger.LogI($"Process ID: {currentProcess.Id}");
            CPHLogger.LogI($"Process Name: {currentProcess.ProcessName}");
            CPHLogger.LogI($"Main Window Handle: {currentProcess.MainWindowHandle}");
            CPHLogger.LogI($"Main Window Title: {currentProcess.MainWindowTitle}");
            CPHLogger.LogI($"Start Time: {currentProcess.StartTime}");
            CPHLogger.LogI($"Responding: {currentProcess.Responding}");
            CPHLogger.LogI($"Memory Usage: {currentProcess.WorkingSet64 / 1024 / 1024} MB");
            CPHLogger.LogI($"Total Processor Time: {currentProcess.TotalProcessorTime}");
            CPHLogger.LogI("=======================");
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
            CPHLogger.LogI("=======================");
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

        CPHLogger.LogI("=== Monitor Details ===");
        foreach (var monitor in monitors)
        {
            CPHLogger.LogI($"Monitor: {monitor.DeviceName}");
            CPHLogger.LogI($"  Bounds: {monitor.Bounds}");
            CPHLogger.LogI($"    X: {monitor.Bounds.X}, Y: {monitor.Bounds.Y}, Width: {monitor.Bounds.Width}, Height: {monitor.Bounds.Height}");
            CPHLogger.LogI($"  Working Area: {monitor.WorkingArea}");
            CPHLogger.LogI($"    X: {monitor.WorkingArea.X}, Y: {monitor.WorkingArea.Y}, Width: {monitor.WorkingArea.Width}, Height: {monitor.WorkingArea.Height}");
            CPHLogger.LogI($"  Primary Monitor: {monitor.Primary}");
        }

        CPHLogger.LogI("=======================");
    }

    private static void LogPerformanceMetrics(string eventName, Action action)
    {
        var start = DateTime.Now;
        action();
        var end = DateTime.Now;
        CPHLogger.LogI($"[PERFORMANCE] {eventName} completed in {(end - start).TotalMilliseconds} ms");
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