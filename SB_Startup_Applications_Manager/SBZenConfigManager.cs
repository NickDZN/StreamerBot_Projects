using System;
using System.Collections.Generic;
using System.ComponentModel; // For TypeDescriptor and EventDescriptor
using System.Drawing;
using System.IO;
using System.Linq;
using System.Reflection; // For BindingFlags
using System.Runtime.InteropServices;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Windows.Forms;

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
        // Start Execution and create centralised SB instance.
        CPH.LogDebug("SBSAM Loaded.");
        SB.CPH = CPH;
        SB.args = args;
        
        // Attempt to get the handle of the currently active window
        CPHLogger.LogV("[FORM INIT] Get Foreground Window.");
        IntPtr activeWindowHandle = GetForegroundWindow();
        if (activeWindowHandle == IntPtr.Zero)
        {
            CPHLogger.LogE("No active window found.");
            return false;
        }

        // Get the window details of the main Streamer.bot instance which this is loaded from.
        StringBuilder windowTitle = new StringBuilder(256);
        GetWindowText(activeWindowHandle, windowTitle, windowTitle.Capacity);
        CPHLogger.LogI($"Window Details: Active Window Handle is {activeWindowHandle}. WindowTitle is {windowTitle}. "
                     + $"Window Capacity is: {windowTitle.Capacity}"
        );
        // Get the dimensions of the active window
        if (!GetWindowRect(activeWindowHandle, out Rectangle activeWindowRect))
        {
            CPHLogger.LogE("Failed to get window dimensions.");
            return false;
        }

        CPHLogger.LogI(
            $"Active Window Rect Details: "
                + $"Size: {activeWindowRect.Size}. Height: {activeWindowRect.Height}. Width: {activeWindowRect.Width} "
                + $"Raw Rectangle Values: Left={activeWindowRect.Left}, Top={activeWindowRect.Top}, Right={activeWindowRect.Right}, Bottom={activeWindowRect.Bottom}"
        );
        // Validate and fix dimensions if required
        if (activeWindowRect.Top > activeWindowRect.Bottom || activeWindowRect.Height < 0)
        {
            activeWindowRect.Height = Math.Abs(activeWindowRect.Bottom - activeWindowRect.Top);
            CPHLogger.LogW(
                $"Negative height detected. Corrected Height: {activeWindowRect.Height}"
            );
        }

        if (activeWindowRect.Left > activeWindowRect.Right || activeWindowRect.Width < 0)
        {
            activeWindowRect.Width = Math.Abs(activeWindowRect.Right - activeWindowRect.Left);
            CPHLogger.LogW($"Negative width detected. Corrected Width: {activeWindowRect.Width}");
        }

        // Get the screen details of the active window
        var screen = Screen.FromHandle(activeWindowHandle);
        CPHLogger.LogI($"Screen Bounds: {screen.Bounds}. Working Area: {screen.WorkingArea}");
        // Calculate DPI scaling factor
        float dpiScalingFactor = Graphics.FromHwnd(activeWindowHandle).DpiX / 96.0f;
        CPHLogger.LogI($"DPI Scaling Factor: {dpiScalingFactor}x");
        // Adjust window placement if necessary
        int adjustedLeft = Math.Max(screen.WorkingArea.Left, activeWindowRect.Left);
        int adjustedTop = Math.Max(screen.WorkingArea.Top, activeWindowRect.Top);
        CPHLogger.LogI($"Adjusted Window Position: Left={adjustedLeft}, Top={adjustedTop}");
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
                    mainFormInstance = new LoadStartupConfigForm(activeWindowRect, actionList);
                    Application.ThreadException += (sender, args) =>
                    {
                        CPHLogger.LogE(
                            $"Unhandled exception in STA thread: {args.Exception.Message}\n{args.Exception.StackTrace}"
                        );
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
        CenterForm(activeWindowRect);
        // Create base layout.
        var coreLayoutPanelForForm = UIComponentFactory.CreateTableLayoutPanel(rows: 6, columns: 1);
        CPHLogger.LogD("Adding the required controls to the form.");
        AddUserConfigurationControlls(coreLayoutPanelForForm);
        AddPermittedApplicationsSection(coreLayoutPanelForForm);
        AddSeparateActionGroups(coreLayoutPanelForForm);
        AddBotStartupBehaviourControls(coreLayoutPanelForForm);
        AddFormFlowControls(coreLayoutPanelForForm);
        // Set Form Properties.
        CPHLogger.LogV("[LoadStartupConfigForm] Set form variables");
        CPHLogger.LogD("Adding layout panel directly to the form.");
        this.Controls.Add(coreLayoutPanelForForm);
        // Log Results.
        CPHLogger.LogV("[LoadStartupConfigForm] Refresh Layout.");
        this.SuspendLayout();
        this.ResumeLayout();
        LayoutLogger.LogAll(this);
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
    /// <param name = "activeWindowRect"></param>
    private void CenterForm(Rectangle activeWindowRect)
    {
        CPHLogger.LogD("[S]CenterForm.");
        CPHLogger.LogI(
            $"Active Window Rect Details: "
                + $"Size: {activeWindowRect.Size}. Height: {activeWindowRect.Height}. Width: {activeWindowRect.Width} "
                + $"Raw Rectangle Values: Left={activeWindowRect.Left}, Top={activeWindowRect.Top}, Right={activeWindowRect.Right}, Bottom={activeWindowRect.Bottom}"
        );
        CPHLogger.LogD("[CenterForm] Calculating form center position.");
        int centerX = activeWindowRect.Left + (activeWindowRect.Width - this.Width) / 2;
        int centerY = activeWindowRect.Top + (activeWindowRect.Height - this.Height) / 2;
        // Adjust to ensure the form is within screen bounds
        var screenBounds = Screen.FromRectangle(activeWindowRect).WorkingArea;
        centerX = Math.Max(screenBounds.Left, Math.Min(centerX, screenBounds.Right - this.Width));
        centerY = Math.Max(screenBounds.Top, Math.Min(centerY, screenBounds.Bottom - this.Height));
        this.Location = new Point(centerX, centerY);
        this.TopMost = true;
        CPHLogger.LogI($"[CenterForm] Centered at X:{centerX}, Y:{centerY}");
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
        var buttonTable = UIComponentFactory.CreateTableLayoutPanel(
            rows: 1,
            columns: 5,
            columnStyling: Constants.ColumnStyling.Distributed
        );
        // Add buttons to the button table
        CPHLogger.LogV("[AddUserConfigurationControlls] Adding buttons to TableLayoutPanel.");
        buttonTable.Controls.Add(
            UIComponentFactory.CreateButton(
                "Reset All",
                Constants.ButtonStyle.Default,
                _eventHandlers.MainCanvasCloseButton_Click
            ),
            0,
            0
        );
        buttonTable.Controls.Add(
            UIComponentFactory.CreateButton(
                "Import",
                Constants.ButtonStyle.Default,
                _eventHandlers.MainCanvasCloseButton_Click
            ),
            1,
            0
        );
        buttonTable.Controls.Add(
            UIComponentFactory.CreateButton(
                "Export",
                Constants.ButtonStyle.Default,
                _eventHandlers.MainCanvasCloseButton_Click
            ),
            2,
            0
        );
        buttonTable.Controls.Add(
            UIComponentFactory.CreateButton(
                "About",
                Constants.ButtonStyle.Default,
                _eventHandlers.MainCanvasCloseButton_Click
            ),
            3,
            0
        );
        buttonTable.Controls.Add(
            UIComponentFactory.CreateButton(
                "Test Config",
                Constants.ButtonStyle.Default,
                _eventHandlers.MainCanvasCloseButton_Click
            ),
            4,
            0
        );
        // Add TableLayoutPanel to GroupBox
        CPHLogger.LogV("[AddUserConfigurationControlls] Adding TableLayoutPanel to GroupBox.");
        configurationGroupBox.Controls.Add(buttonTable);
        // Add GroupBox to the main layout
        CPHLogger.LogI("[AddUserConfigurationControlls] Adding GroupBox added to form base table.");
        coreLayoutPanelForForm.Controls.Add(configurationGroupBox, 0, 0);
    }

    /// <summary>
    ///
    /// </summary>
    /// <param name = "coreLayoutPanelForForm"></param>
    private void AddPermittedApplicationsSection(TableLayoutPanel coreLayoutPanelForForm)
    {
        CPHLogger.LogD($"[S]AddPermittedApplicationsSection");
        // Create and style the GroupBox for applications
        CPHLogger.LogV("[AddPermittedApplicationsSection] Creating GroupBox for applications.");
        var applicationsGroupBox = UIComponentFactory.CreateGroupBox(
            "Applications to run on bot startup"
        );
        // Define row/columns settings the table will use.
        CPHLogger.LogV(
            "[AddPermittedApplicationsSection] Defining column styles for application table."
        );
        var rowStyling = new List<RowStyle>
        {
            new RowStyle(SizeType.Percent, 100f),
            new RowStyle(SizeType.AutoSize),
        };
        var columnStyling = new List<ColumnStyle>
        {
            new ColumnStyle(SizeType.Percent, 100f),
            new ColumnStyle(SizeType.AutoSize),
        };
        // Create the application table
        CPHLogger.LogV("[AddPermittedApplicationsSection] Creating application TableLayoutPanel.");
        var appTable = UIComponentFactory.CreateTableLayoutPanel(
            rows: 2,
            columns: 2,
            rowStyling: Constants.RowStyling.Custom,
            columnStyling: Constants.ColumnStyling.Custom,
            customRowStyles: rowStyling,
            customColumnStyles: columnStyling
        );
        // Add a ListBox for applications in the left column, first row
        CPHLogger.LogV("[AddPermittedApplicationsSection] Creating ListBox for applications.");
        var appListBox = UIComponentFactory.CreateListBox();
        appListBox.IntegralHeight = false;
        CPHLogger.LogV("[AddPermittedApplicationsSection] Add Listbox to table.");
        appTable.Controls.Add(appListBox, 0, 0);
        // Create a FlowLayoutPanel for Add/Remove buttons
        CPHLogger.LogV(
            "[AddPermittedApplicationsSection] Creating FlowLayoutPanel for Add/Remove buttons."
        );
        var buttonPanel = UIComponentFactory.CreateFlowLayoutPanel(
            FlowDirection.TopDown,
            wrapContents: true,
            autoSize: true,
            margin: new Padding(5),
            anchor: AnchorStyles.Top
        );
        // Add buttons for managing applications
        CPHLogger.LogV("[AddPermittedApplicationsSection] Add buttons for managing applications.");
        buttonPanel.Controls.Add(
            UIComponentFactory.CreateButton(
                "Add Application",
                Constants.ButtonStyle.Longer,
                _eventHandlers.AddApplication_Click
            )
        );
        //buttonPanel.Controls.Add(UIComponentFactory.CreateButton("Add Application Path", Constants.ButtonStyle.Longer, _eventHandlers.AddApplicationPath_Click));
        buttonPanel.Controls.Add(
            UIComponentFactory.CreateButton(
                "Remove Application",
                Constants.ButtonStyle.Longer,
                _eventHandlers.RemoveApplication_Click
            )
        );
        appTable.Controls.Add(buttonPanel, 1, 0);
        // Create a FlowLayoutPanel for arrow buttons in the left column, second row
        CPHLogger.LogV(
            "[AddPermittedApplicationsSection] Creating FlowLayoutPanel for arrow buttons."
        );
        var arrowPanel = UIComponentFactory.CreateFlowLayoutPanel(
            FlowDirection.LeftToRight,
            wrapContents: true,
            autoSize: true,
            margin: new Padding(0),
            anchor: AnchorStyles.Right
        );
        // Add arrow buttons for reordering applications
        CPHLogger.LogV(
            "[AddPermittedApplicationsSection] Adding arrow buttons to FlowLayoutPanel."
        );
        arrowPanel.Controls.Add(
            UIComponentFactory.CreateButton(
                "▲",
                Constants.ButtonStyle.ArrowBtn,
                _eventHandlers.btnApplicationsUp_Click
            )
        );
        arrowPanel.Controls.Add(
            UIComponentFactory.CreateButton(
                "▼",
                Constants.ButtonStyle.ArrowBtn,
                _eventHandlers.btnApplicationsDown_Click
            )
        );
        appTable.Controls.Add(arrowPanel, 0, 1);
        // Attach the ListBox event handler for selection changes
        CPHLogger.LogV(
            "[AddPermittedApplicationsSection] Attaching event handler for ListBox selection changes."
        );
        appListBox.SelectedIndexChanged += _eventHandlers.ApplicationListBox_SelectedIndexChanged;
        // Add the application table to the GroupBox
        CPHLogger.LogV("[AddPermittedApplicationsSection] TableLayoutPanel added to GroupBox.");
        applicationsGroupBox.Controls.Add(appTable);
        // Add the GroupBox to the main layout
        CPHLogger.LogV(
            "[AddPermittedApplicationsSection] GroupBox added to main TableLayoutPanel."
        );
        coreLayoutPanelForForm.Controls.Add(applicationsGroupBox, 0, 1);
    }

    private void LogControlDetails(Control control, string controlName)
    {
        // Log details for the current control
        CPHLogger.LogI($"[INFO] {controlName} Properties:");
        CPHLogger.LogI($"  Type: {control.GetType().Name}");
        CPHLogger.LogI($"  Size: {control.Size}");
        CPHLogger.LogI($"  Location: {control.Location}");
        CPHLogger.LogI($"  Dock: {control.Dock}");
        CPHLogger.LogI($"  Anchor: {control.Anchor}");
        CPHLogger.LogI($"  AutoSize: {control.AutoSize}");
        CPHLogger.LogI($"  Margin: {control.Margin}");
        CPHLogger.LogI($"  Padding: {control.Padding}");
        // Special handling for TableLayoutPanel
        if (control is TableLayoutPanel table)
        {
            CPHLogger.LogI($"  Rows: {table.RowCount}, Columns: {table.ColumnCount}");
            CPHLogger.LogI(
                $"  RowStyles: {string.Join(", ", table.RowStyles.Cast<RowStyle>().Select(rs => rs.SizeType.ToString()))}"
            );
            CPHLogger.LogI(
                $"  ColumnStyles: {string.Join(", ", table.ColumnStyles.Cast<ColumnStyle>().Select(cs => cs.SizeType.ToString()))}"
            );
        }

        // Log details for the parent hierarchy
        var parent = control.Parent;
        int depth = 1;
        while (parent != null)
        {
            CPHLogger.LogI($"  [Parent Level {depth}] Parent Control Properties:");
            CPHLogger.LogI($"    Type: {parent.GetType().Name}");
            CPHLogger.LogI($"    Size: {parent.Size}");
            CPHLogger.LogI($"    Location: {parent.Location}");
            CPHLogger.LogI($"    Dock: {parent.Dock}");
            CPHLogger.LogI($"    Anchor: {parent.Anchor}");
            CPHLogger.LogI($"    AutoSize: {parent.AutoSize}");
            CPHLogger.LogI($"    Margin: {parent.Margin}");
            CPHLogger.LogI($"    Padding: {parent.Padding}");
            depth++;
            parent = parent.Parent;
        }
    }

    /// <summary>
    ///
    /// </summary>
    /// <param name = "coreLayoutPanelForTab"></param>
    private void AddSeparateActionGroups(TableLayoutPanel coreLayoutPanelForTab)
    {
        CPHLogger.LogD("[S]AddSeparateActionGroups");
        CPHLogger.LogI($"[AddSeparateActionGroups] Table Size: {coreLayoutPanelForTab.Size}");
        // Create controls for the "Allowed Actions" group.
        CPHLogger.LogV("[AddSeparateActionGroups] Creating controls for 'Allowed Actions'.");
        var lstActionsPermitted = UIComponentFactory.CreateListBox();
        var btnAddActionPermitted = UIComponentFactory.CreateButton(
            "Add",
            Constants.ButtonStyle.Longer,
            _eventHandlers.AddActionPermitted_Click
        );
        var btnRemoveActionPermitted = UIComponentFactory.CreateButton(
            "Remove",
            Constants.ButtonStyle.Longer,
            _eventHandlers.RemoveActionPermitted_Click
        );
        // Create controls for the "Blocked Actions" group.
        CPHLogger.LogV("[AddSeparateActionGroups] Creating controls for 'Blocked Actions'.");
        var lstActionsBlocked = UIComponentFactory.CreateListBox();
        var btnAddActionBlocked = UIComponentFactory.CreateButton(
            "Add",
            Constants.ButtonStyle.Longer,
            _eventHandlers.AddActionBlocked_Click
        );
        var btnRemoveActionBlocked = UIComponentFactory.CreateButton(
            "Remove",
            Constants.ButtonStyle.Longer,
            _eventHandlers.RemoveActionBlocked_Click
        );
        // Create "Allowed Actions" GroupBox
        CPHLogger.LogV("[AddSeparateActionGroups] Creating 'Allowed Actions' GroupBox.");
        var allowedActionsGroupBox = CreateActionsGroupBox(
            "Allowed Actions",
            lstActionsPermitted,
            btnAddActionPermitted,
            btnRemoveActionPermitted,
            _eventHandlers.AddActionPermitted_SelIndhanged,
            _eventHandlers.AddActionPermitted_Click,
            _eventHandlers.RemoveActionPermitted_Click
        );
        CPHLogger.LogV("[AddSeparateActionGroups] Creating 'Blocked Actions' GroupBox.");
        var blockedActionsGroupBox = CreateActionsGroupBox(
            "Blocked Actions",
            lstActionsBlocked,
            btnAddActionBlocked,
            btnRemoveActionBlocked,
            _eventHandlers.AddActionBlocked_SelIndhanged,
            _eventHandlers.AddActionBlocked_Click,
            _eventHandlers.RemoveActionBlocked_Click
        );
        CPHLogger.LogV(
            "[AddSeparateActionGroups] Adding 'Allowed Actions' GroupBox to the main TableLayoutPanel."
        );
        coreLayoutPanelForTab.Controls.Add(allowedActionsGroupBox, 0, 2);
        CPHLogger.LogV(
            "[AddSeparateActionGroups] Adding 'Blocked Actions' GroupBox to the main TableLayoutPanel."
        );
        coreLayoutPanelForTab.Controls.Add(blockedActionsGroupBox, 0, 3);
    }

    /// <summary>
    ///
    /// </summary>
    /// <param name = "title"></param>
    /// <param name = "listBox"></param>
    /// <param name = "addButton"></param>
    /// <param name = "removeButton"></param>
    /// <param name = "listBoxSelected"></param>
    /// <param name = "addButtonClick"></param>
    /// <param name = "removeButtonClick"></param>
    /// <returns></returns>
    private GroupBox CreateActionsGroupBox(
        string title,
        ListBox listBox,
        Button addButton,
        Button removeButton,
        EventHandler listBoxSelected,
        EventHandler addButtonClick,
        EventHandler removeButtonClick
    )
    {
        CPHLogger.LogD($"[S]CreateActionsGroupBox - Title: {title}");
        // Create GroupBox using the factory
        CPHLogger.LogV("[CreateActionsGroupBox] Creating GroupBox.");
        var actionsGroupBox = UIComponentFactory.CreateGroupBox(title);
        // Define column styles for the layout panel
        CPHLogger.LogV("[CreateActionsGroupBox] Defining column styles for layout panel.");
        var columnStyling = new List<ColumnStyle>
        {
            new ColumnStyle(SizeType.Percent, 100),
            new ColumnStyle(SizeType.AutoSize),
        };
        // Create TableLayoutPanel
        CPHLogger.LogV("[CreateActionsGroupBox] Creating TableLayoutPanel.");
        var actionsTable = UIComponentFactory.CreateTableLayoutPanel(
            rows: 1,
            columns: 2,
            columnStyling: Constants.ColumnStyling.Custom,
            customColumnStyles: columnStyling
        );
        CPHLogger.LogV("[AddPermittedApplicationsSection] Creating ListBox for applications.");
        var actionListBox = UIComponentFactory.CreateListBox();
        // Add ListBox to the layout
        CPHLogger.LogV("[CreateActionsGroupBox] Adding ListBox to TableLayoutPanel.");
        actionsTable.Controls.Add(actionListBox, 0, 0);
        // Create FlowLayoutPanel for buttons
        CPHLogger.LogV("[CreateActionsGroupBox] Creating FlowLayoutPanel for Add/Remove buttons.");
        var buttonPanel = UIComponentFactory.CreateFlowLayoutPanel(
            FlowDirection.TopDown,
            wrapContents: true,
            autoSize: true,
            margin: new Padding(5),
            anchor: AnchorStyles.Top
        );
        // Add Add and Remove buttons to the button panel
        CPHLogger.LogV("[CreateActionsGroupBox] Adding 'Add' button to FlowLayoutPanel.");
        buttonPanel.Controls.Add(addButton);
        buttonPanel.Controls.Add(removeButton);
        actionsTable.Controls.Add(buttonPanel, 1, 0);
        // Attach event handlers
        CPHLogger.LogV("[CreateActionsGroupBox] Attaching event handlers to ListBox and buttons.");
        actionListBox.SelectedIndexChanged += listBoxSelected;
        addButton.Click += addButtonClick;
        removeButton.Click += removeButtonClick;
        // Add the layout to the GroupBox
        actionsGroupBox.Controls.Add(actionsTable);
        CPHLogger.LogV("[CreateActionsGroupBox] TableLayoutPanel added to GroupBox.");
        return actionsGroupBox;
    }

    /// <summary>
    ///
    /// </summary>
    /// <param name = "coreLayoutPanelForTab"></param>
    private void AddBotStartupBehaviourControls(TableLayoutPanel coreLayoutPanelForTab)
    {
        CPHLogger.LogD("[S]AddBotStartupBehaviourControls");
        CPHLogger.LogI(
            $"[AddBotStartupBehaviourControls] Table Size: {coreLayoutPanelForTab.Size}"
        );
        // Create GroupBox for Startup Configuration
        CPHLogger.LogD(
            "[AddBotStartupBehaviourControls] Creating GroupBox for Startup Configuration."
        );
        var startupOptionsGroup = UIComponentFactory.CreateGroupBox("Load Applications on Startup");
        CPHLogger.LogI("[AddBotStartupBehaviourControls] GroupBox created.");
        // Define column styles for the TableLayoutPanel
        CPHLogger.LogD(
            "[AddBotStartupBehaviourControls] Defining column styles for Startup Configuration panel."
        );
        var columnStyling = new List<ColumnStyle>
        {
            new ColumnStyle(SizeType.AutoSize), // Column for "Yes" radio button
            new ColumnStyle(SizeType.AutoSize), // Column for "No" radio button
            new ColumnStyle(SizeType.AutoSize), // Column for "Prompt" radio button
            new ColumnStyle(SizeType.Percent, 100), // Filler column
            new ColumnStyle(SizeType.AutoSize), // Column for "Delay Label"
            new ColumnStyle(
                SizeType.AutoSize
            ) // Column for NumericUpDown control
            ,
        };
        // Create and style the TableLayoutPanel
        CPHLogger.LogD(
            "[AddBotStartupBehaviourControls] Creating TableLayoutPanel for Startup Configuration."
        );
        var startupOptionsPanel = UIComponentFactory.CreateTableLayoutPanel(
            rows: 1,
            columns: 6,
            columnStyling: Constants.ColumnStyling.Custom,
            customColumnStyles: columnStyling
        );
        CPHLogger.LogI("[AddBotStartupBehaviourControls] TableLayoutPanel created.");
        // Create and style radio buttons
        CPHLogger.LogD("[AddBotStartupBehaviourControls] Creating and styling radio buttons.");
        var radioStartupConfigYes = UIComponentFactory.CreateRadioButton("Yes", true);
        var radioStartupConfigNo = UIComponentFactory.CreateRadioButton("No", true);
        var radioStartupConfigPrompt = UIComponentFactory.CreateRadioButton("Prompt", true);
        CPHLogger.LogI("[AddBotStartupBehaviourControls] Radio buttons created.");
        // Style delay label and NumericUpDown
        CPHLogger.LogD(
            "[AddBotStartupBehaviourControls] Creating and styling delay label and NumericUpDown."
        );
        var lblStartupConfigDelay = UIComponentFactory.CreateLabel(
            "Delay (seconds):",
            textAlign: ContentAlignment.MiddleRight
        );
        var numupdwnStartupConfigDelay = UIComponentFactory.CreateNumericUpDown(
            minimum: 0,
            maximum: 30,
            defaultValue: 5
        );
        CPHLogger.LogI("[AddBotStartupBehaviourControls] Delay label and NumericUpDown created.");
        // Add controls to the layout panel
        CPHLogger.LogD("[AddBotStartupBehaviourControls] Adding controls to TableLayoutPanel.");
        startupOptionsPanel.Controls.Add(radioStartupConfigYes, 0, 0);
        startupOptionsPanel.Controls.Add(radioStartupConfigNo, 1, 0);
        startupOptionsPanel.Controls.Add(radioStartupConfigPrompt, 2, 0);
        startupOptionsPanel.Controls.Add(lblStartupConfigDelay, 4, 0);
        startupOptionsPanel.Controls.Add(numupdwnStartupConfigDelay, 5, 0);
        CPHLogger.LogI("[AddBotStartupBehaviourControls] Controls added to TableLayoutPanel.");
        // Add the TableLayoutPanel to the GroupBox
        CPHLogger.LogD("[AddBotStartupBehaviourControls] Adding TableLayoutPanel to GroupBox.");
        startupOptionsGroup.Controls.Add(startupOptionsPanel);
        CPHLogger.LogI("[AddBotStartupBehaviourControls] TableLayoutPanel added to GroupBox.");
        // Add the GroupBox to the main layout panel
        CPHLogger.LogD("[AddBotStartupBehaviourControls] Adding GroupBox to main layout panel.");
        coreLayoutPanelForTab.Controls.Add(startupOptionsGroup, 0, 4); // Adjust row/column indices as needed
        CPHLogger.LogI("[AddBotStartupBehaviourControls] GroupBox added to main TableLayoutPanel.");
    }

    private void AddFormFlowControls(TableLayoutPanel coreLayoutPanelForForm)
    {
        CPHLogger.LogD("[S]AddFormFlowControls");
        CPHLogger.LogI($"[AddFormFlowControls] Table Size: {coreLayoutPanelForForm.Size}");
        // Create FlowLayoutPanel for buttons
        CPHLogger.LogD("[AddFormFlowControls] Creating FlowLayoutPanel.");
        var flowControlButtonPanel = UIComponentFactory.CreateFlowLayoutPanel(
            autoSize: true,
            wrapContents: false,
            anchor: AnchorStyles.None
        );
        CPHLogger.LogI("[AddFormFlowControls] FlowLayoutPanel created.");
        // Add Save button
        CPHLogger.LogD("[AddFormFlowControls] Adding 'Save' button.");
        flowControlButtonPanel.Controls.Add(
            UIComponentFactory.CreateButton(
                "Save",
                Constants.ButtonStyle.FlowControl,
                _eventHandlers.MainCanvasSaveButton_Click
            )
        );
        CPHLogger.LogI("[AddFormFlowControls] 'Save' button added.");
        // Add Close button
        CPHLogger.LogD("[AddFormFlowControls] Adding 'Close' button.");
        flowControlButtonPanel.Controls.Add(
            UIComponentFactory.CreateButton(
                "Close",
                Constants.ButtonStyle.FlowControl,
                _eventHandlers.MainCanvasCloseButton_Click
            )
        );
        CPHLogger.LogI("[AddFormFlowControls] 'Close' button added.");
        // Add FlowLayoutPanel to the main layout
        coreLayoutPanelForForm.Controls.Add(flowControlButtonPanel, 0, 5);
        CPHLogger.LogI("[AddFormFlowControls] FlowLayoutPanel added to main TableLayoutPanel.");
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
        CPHLogger.LogI(
            $"{indent}Control: {parent.Name ?? parent.GetType().Name}, "
                + $"Type: {parent.GetType().Name}, "
                + $"Size: {parent.Size.Width}x{parent.Size.Height}, "
                + $"Location: {parent.Location.X},{parent.Location.Y}, "
                + $"Dock: {parent.Dock}, "
                + $"Anchor: {parent.Anchor}, "
                + $"AutoSize: {parent.AutoSize}, "
                + $"AutoSizeMode: {(parent is TableLayoutPanel tlp ? tlp.AutoSizeMode.ToString() : "N/A")}, "
                + $"MinimumSize: {parent.MinimumSize.Width}x{parent.MinimumSize.Height}, "
                + $"MaximumSize: {parent.MaximumSize.Width}x{parent.MaximumSize.Height}, "
                + $"Margin: {parent.Margin.Left},{parent.Margin.Top},{parent.Margin.Right},{parent.Margin.Bottom}, "
                + $"Padding: {parent.Padding.Left},{parent.Padding.Top},{parent.Padding.Right},{parent.Padding.Bottom}, "
                + $"Text: \"{parent.Text}\""
        );
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
                CPHLogger.LogD(
                    $"{indent}  Difference in Dock: Current={control.Dock}, Default={defaultInstance.Dock}"
                );
            if (control.Anchor != defaultInstance.Anchor)
                CPHLogger.LogD(
                    $"{indent}  Difference in Anchor: Current={control.Anchor}, Default={defaultInstance.Anchor}"
                );
            if (control.AutoSize != defaultInstance.AutoSize)
                CPHLogger.LogD(
                    $"{indent}  Difference in AutoSize: Current={control.AutoSize}, Default={defaultInstance.AutoSize}"
                );
            if (control.Font != defaultInstance.Font)
                CPHLogger.LogD(
                    $"{indent}  Difference in Font: Current={control.Font}, Default={defaultInstance.Font}"
                );
            if (control.Margin != defaultInstance.Margin)
                CPHLogger.LogD(
                    $"{indent}  Difference in Margin: Current={control.Margin}, Default={defaultInstance.Margin}"
                );
            if (control.Padding != defaultInstance.Padding)
                CPHLogger.LogD(
                    $"{indent}  Difference in Padding: Current={control.Padding}, Default={defaultInstance.Padding}"
                );
            // Dispose the default instance to free resources
            defaultInstance.Dispose();
        }
        catch (Exception ex)
        {
            CPHLogger.LogE($"{indent}  Failed to compare default values: {ex.Message}");
        }
    }
}

public class EventHandlers
{
    public void AddApplication_Click(object sender, EventArgs e)
    {
        int a = 1;
    }

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
    public static NumericUpDown CreateNumericUpDown(
        int width = 40,
        int height = 20,
        int minimum = 0,
        int maximum = 30,
        int defaultValue = 2
    )
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
        CPHLogger.LogV(
            $"NumericUpDown created: Width={numericUpDown.Width}, Height={numericUpDown.Height}, Minimum={numericUpDown.Minimum}, "
                + $"Maximum={numericUpDown.Maximum}, DefaultValue={numericUpDown.Value}"
        );
        return numericUpDown;
    }

    /// <summary>
    /// Creates and styles a RadioButton control.
    /// </summary>
    /// <param name = "text">The text for the RadioButton.</param>
    /// <param name = "autoSize">Indicates if the RadioButton should automatically size itself.</param>
    /// <param name = "isChecked">Indicates if the RadioButton is initially checked.</param>
    /// <returns>A styled <see cref = "RadioButton"/> control.</returns>
    public static RadioButton CreateRadioButton(
        string text,
        bool autoSize = true,
        bool isChecked = false
    )
    {
        var radioButton = new RadioButton
        {
            Text = text,
            AutoSize = autoSize,
            Dock = DockStyle.Fill,
            TextAlign = ContentAlignment.MiddleLeft,
            Checked = isChecked,
        };
        CPHLogger.LogV(
            $"RadioButton created. Properties: Text=\"{radioButton.Text}\", AutoSize={radioButton.AutoSize}, Dock={radioButton.Dock}, "
                + $"TextAlign={radioButton.TextAlign}, Checked={radioButton.Checked}"
        );
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
    public static Label CreateLabel(
        string text,
        ContentAlignment textAlign = ContentAlignment.MiddleLeft,
        Padding? margin = null,
        Padding? padding = null
    )
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
        CPHLogger.LogV(
            $"Label created. Properties: Text=\"{label.Text}\", AutoSize={label.AutoSize}, Dock={label.Dock}, TextAlign={label.TextAlign}, "
                + $"Margin={label.Margin}, Padding={label.Padding}"
        );
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
    public static Button CreateButton(
        string text,
        Constants.ButtonStyle style = Constants.ButtonStyle.Default,
        EventHandler clickEvent = null,
        bool isEnabled = true
    )
    {
        var btn = new Button
        {
            Text = text,
            Enabled = isEnabled,
            Height = 26,
            AutoSize = false,
            FlatStyle = FlatStyle.Flat,
            Font = new Font("Microsoft Sans Serif", 8.5f),
            BackColor = Color.White,
            ForeColor = SystemColors.ControlText,
        };
        // Apply different styles based on the ButtonStyle enum
        switch (style)
        {
            case Constants.ButtonStyle.Primary:
                btn.Width = 90;
                btn.Margin = new Padding(0, 0, 15, 0);
                btn.Padding = new Padding(2, 2, 2, 2);
                btn.BackColor = Color.DodgerBlue;
                btn.ForeColor = Color.White;
                btn.FlatAppearance.BorderSize = 1;
                btn.FlatAppearance.BorderColor = Color.RoyalBlue;
                break;
            case Constants.ButtonStyle.Longer:
                btn.Width = 130;
                btn.Margin = new Padding(1, 3, 1, 1);
                btn.Padding = new Padding(2, 2, 2, 2);
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
            default:
                // Default style
                btn.Width = 90;
                btn.Margin = new Padding(0);
                btn.Padding = new Padding(2, 2, 2, 2);
                btn.BackColor = Color.White;
                btn.ForeColor = SystemColors.ControlText;
                btn.FlatAppearance.BorderSize = 1;
                btn.FlatAppearance.BorderColor = Color.DarkGray;
                break;
        }

        if (clickEvent != null)
            btn.Click += clickEvent;
        // Verbose logging of all button properties
        CPHLogger.LogV(
            $"Button created. Properties: Text=\"{btn.Text}\", Width={btn.Width}, Height={btn.Height}, Enabled={btn.Enabled}, "
                + $"Margin={btn.Margin}, Padding={btn.Padding}, Style={style}, BackColor={btn.BackColor}, ForeColor={btn.ForeColor}, "
                + $"FlatStyle={btn.FlatStyle}, BorderSize={btn.FlatAppearance.BorderSize}, BorderColor={btn.FlatAppearance.BorderColor}"
        );
        return btn;
    }

    public static TableLayoutPanel CreateTableLayoutPanel(
        int rows,
        int columns,
        int? height = null,
        Constants.RowStyling rowStyling = Constants.RowStyling.Default,
        Constants.ColumnStyling columnStyling = Constants.ColumnStyling.Default,
        List<RowStyle> customRowStyles = null,
        List<ColumnStyle> customColumnStyles = null
    )
    {
        var tableLayout = new TableLayoutPanel
        {
            Dock = DockStyle.Fill,
            ColumnCount = columns,
            RowCount = rows,
            AutoSize = height == null, // If height is not provided, enable AutoSize
            AutoSizeMode = AutoSizeMode.GrowAndShrink,
            CellBorderStyle = TableLayoutPanelCellBorderStyle.Single,
            Padding = new Padding(0),
            Margin = new Padding(0),
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
        };
        CPHLogger.LogV(
            $"GroupBox created. Properties: Text=\"{title}\", Margin={groupBox.Margin}, Font={groupBox.Font}"
        );
        return groupBox;
    }

    /// <summary>
    /// Factory for creating and styling FlowLayoutPanel controls.
    /// </summary>
    public static FlowLayoutPanel CreateFlowLayoutPanel(
        FlowDirection direction = FlowDirection.LeftToRight,
        bool wrapContents = true,
        bool autoSize = false,
        AnchorStyles anchor = AnchorStyles.Top | AnchorStyles.Left,
        Padding? margin = null
    )
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
        };
        CPHLogger.LogV(
            $"FlowLayoutPanel created: Direction={flowPanel.FlowDirection}, WrapContents={flowPanel.WrapContents}, AutoSize={flowPanel.AutoSize}"
        );
        return flowPanel;
    }

    /// <summary>
    /// Factory for creating and styling ListBox controls.
    /// </summary>
    public static ListBox CreateListBox(
        int? widthParam = null,
        int? heightParam = null,
        bool multiSelect = false,
        bool sorted = false,
        bool iHeight = false,
        AnchorStyles anchor = AnchorStyles.Left | AnchorStyles.Right
    )
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
        CPHLogger.LogV(
            $"ListBox created: Width={(widthParam.HasValue ? widthParam.Value.ToString() : "Auto")}, "
                + $"Height={(heightParam.HasValue ? heightParam.Value.ToString() : "Auto")}, "
                + $"MultiSelect={multiSelect}, Sorted={sorted}"
        );
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
    public static readonly Color FormColour = Color.WhiteSmoke;
    public static readonly string DataDir = Path.Combine(
        AppDomain.CurrentDomain.BaseDirectory,
        "data"
    );

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

    public static void LogE(string message) => CPH.LogError($"[ERROR] {message}");

    public static void LogI(string message) => CPH.LogInfo($"[INFO] {message}");

    public static void LogV(string message) => CPH.LogVerbose($"[VERBOSE] {message}");

    public static void LogW(string message) => CPH.LogWarn($"[WARN] {message}");
}

public static class LayoutLogger
{
    private static int controlCounter = 0;

    public static void LogAll(Control control, string context = "General")
    {
        controlCounter = 0;
        CPHLogger.LogI($"[LAYOUT] ===== BEGIN LAYOUT DEBUG LOG [{context}] =====");
        LogControlHierarchy(control);
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

    private static void LogControlHierarchy(Control control, int depth = 0)
    {
        string prefix = $"{depth + 1}.";
        string indent = new string(' ', depth * 2);
        controlCounter++;
        string controlDetails =
            $"{indent}[{controlCounter}] {prefix}Control: {control.GetType().Name}, Name: {control.Name ?? "Unnamed"}, "
            + $"Size: {control.Width}x{control.Height}, Location: {control.Location}, Dock: {control.Dock}, Anchor: {control.Anchor}, "
            + $"AutoSize: {control.AutoSize}, Margin: {control.Margin}, Padding: {control.Padding}";
        CPHLogger.LogI(controlDetails);
        foreach (Control child in control.Controls)
        {
            LogControlHierarchy(child, depth + 1);
        }
    }

    private static void LogPerformanceMetrics(string eventName, Action action)
    {
        var start = DateTime.Now;
        action();
        var end = DateTime.Now;
        CPHLogger.LogI(
            $"[PERFORMANCE] {eventName} completed in {(end - start).TotalMilliseconds} ms"
        );
    }

    private static void LogTableLayoutPanelDetails(TableLayoutPanel tableLayoutPanel)
    {
        CPHLogger.LogI(
            $"[TableLayoutPanel] {tableLayoutPanel.Name}, Rows: {tableLayoutPanel.RowCount}, Columns: {tableLayoutPanel.ColumnCount}"
        );
        for (int row = 0; row < tableLayoutPanel.RowCount; row++)
        {
            for (int col = 0; col < tableLayoutPanel.ColumnCount; col++)
            {
                Control cellControl = tableLayoutPanel.GetControlFromPosition(col, row);
                CPHLogger.LogI(
                    $"    [Row {row}, Col {col}] => {(cellControl != null ? cellControl.GetType().Name : "Empty")}"
                );
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
        CPHLogger.LogI(
            $"[Screen] Bounds: {screen.Bounds}, Working Area: {screen.WorkingArea}, Control Bounds: {control.Bounds}"
        );
    }

    private static void LogScrollableContent(Control control)
    {
        if (control is ScrollableControl scrollableControl)
        {
            CPHLogger.LogI(
                $"[ScrollableControl] {scrollableControl.Name}, Size: {scrollableControl.Width}x{scrollableControl.Height}"
            );
        }
    }

    private static void LogMarginPadding(Control control)
    {
        CPHLogger.LogI(
            $"[Margins & Padding] Control: {control.Name}, Margin: {control.Margin}, Padding: {control.Padding}"
        );
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
