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
        // Start Execution and create centralised SB instance. 
        CPH.LogDebug("SBSAM Loaded.");
        SB.CPH = CPH;
        SB.args = args;
        CPHLogger.LogDebug("Centralised CPH, enabling centralised methods.");
        // Attempt to get the handle of the currently active window
        CPHLogger.LogDebug("Getting Window Details");
        IntPtr activeWindowHandle = GetForegroundWindow();
        CPHLogger.LogInfo($"activeWindowHandle is {activeWindowHandle}.");
        // Check if the window was found
        if (activeWindowHandle == IntPtr.Zero)
        {
            CPHLogger.LogError("No active window found.");
            return false;
        }

        // Get the window title
        StringBuilder windowTitle = new StringBuilder(256);
        CPHLogger.LogInfo($"windowTitle is {windowTitle}.");
        GetWindowText(activeWindowHandle, windowTitle, windowTitle.Capacity);
        // Get the dimensions of the active window
        if (!GetWindowRect(activeWindowHandle, out Rectangle activeWindowRect))
        {
            CPHLogger.LogError("Failed to get window dimensions.");
            return false;
        }

        // Start new thread for the form.
        CPHLogger.LogDebug("Starting main form thread.");
        Thread staThread = new Thread(() =>
        {
            try
            {
                CPHLogger.LogDebug("Enabling application visual styles.");
                Application.EnableVisualStyles();
                CPHLogger.LogDebug("Populating list of actions.");
                List<ActionData> actionList = CPH.GetActions();
                if (mainFormInstance == null || mainFormInstance.IsDisposed)
                {
                    CPHLogger.LogDebug("Loading a new form.");
                    mainFormInstance = new LoadStartupConfigForm(activeWindowRect, actionList);
                    // Add a catch-all handler for unhandled exceptions in the form
                    Application.ThreadException += (sender, args) =>
                    {
                        CPHLogger.LogError($"Unhandled exception in STA thread: {args.Exception.Message}\n{args.Exception.StackTrace}");
                    };
                    Application.Run(mainFormInstance);
                }
                else
                {
                    CPHLogger.LogDebug("Bringing current form to front.");
                    mainFormInstance.BringToFront();
                }
            }
            catch (Exception ex)
            {
                CPHLogger.LogError($"Unhandled exception in STA thread: {ex.Message}\n{ex.StackTrace}");
            }
        });
        staThread.SetApartmentState(ApartmentState.STA);
        staThread.Start();
        return true;
    }
}

public class LoadStartupConfigForm : Form
{
    // Field to hold the CPH object
    private IInlineInvokeProxy CPH;
    // List of the actions available in streamerbot. 
    private List<ActionData> actionDataList;
    // Index holder for the list boxes. 
    private int indexOfListItem;
    //SB_SAM Startup Configuration Buttons.
    private Label lblStartupConfigDelay = new Label();
    private RadioButton radioStartupConfigYes = new RadioButton();
    private RadioButton radioStartupConfigNo = new RadioButton();
    private RadioButton radioStartupConfigPrompt = new RadioButton();
    private NumericUpDown numupdwnStartupConfigDelay = new NumericUpDown();
    // Application Start-up IO's.
    private ListBox lstApplications = new ListBox();
    private Button btnAddApplication = new Button();
    private Button btnAddApplicationPath = new Button();
    private Button btnRemoveApplication = new Button();
    private Button btnMoveUp = new Button();
    private Button btnMoveDown = new Button();
    // Actions Startup Permitted IO's
    private ListBox lstActionsPermitted = new ListBox();
    private Button btnAddActionPermitted = new Button();
    private Button btnRemoveActionPermitted = new Button();
    private ListBox lstActionsBlocked = new ListBox();
    private Button btnAddActionBlocked = new Button();
    private Button btnRemoveActionBlocked = new Button();
    //User Settings Controls
    private Button btnResetAllSettings = new Button();
    private Button btnImportSettings = new Button();
    private Button btnExportSettings = new Button();
    // Main Form Controls.
    private Button btnSaveForm = new Button();
    private Button btnCloseForm = new Button();
    private Button btnShowAbout = new Button();
    private Button btnTestConfig = new Button();
    // Tooltips.
    private ToolTip toolTip = new ToolTip();
    public LoadStartupConfigForm(Rectangle activeWindowRect, List<ActionData> actions)
    {
        // Locally store the list of actions
        actionDataList = actions;
        // Build the core form layout
        CPHLogger.LogDebug("Building base form structure.");
        var coreLayoutPanelForForm = CreateBaseLevelTablePanel(activeWindowRect, rowCount: 6, columnCount: 1);

        var coreLayoutPanelForForm = CreateTableLayoutPanel(rowCount: 6, columnCount: 1);



        // Add controls to the layout panel
        CPHLogger.LogDebug("Adding the required controls to the form.");
        AddConfigurationControls(coreLayoutPanelForForm);
        AddApplicationControls(coreLayoutPanelForForm);
        AddSeparateActionGroups(coreLayoutPanelForForm);
        AddStartupConfigurationControls(coreLayoutPanelForForm);
        AddApplicationControlButtons(coreLayoutPanelForForm);


        this.Text = Constants.FormName;
        CPHLogger.LogInfo($"Form Name: {this.Text}");

        //this.Width = 600;
        //this.Height = 800;
        CPHLogger.LogInfo($"Form Base Size. W:{this.Width} H:{this.Height}");

        this.AutoSize = true;
        this.AutoSizeMode = AutoSizeMode.GrowAndShrink;
        CPHLogger.LogDebug("[BuildCoreForm] Setting Auto Size Properties");

        this.MinimumSize = new Size(200, 200);
        CPHLogger.LogInfo($"Form MinimumSize Set. W:{this.Width} H:{this.Height}");
        
        CPHLogger.LogDebug("[BuildCoreForm] Setting base form styling.");        
        this.BackColor = Color.WhiteSmoke;
        this.FormBorderStyle = FormBorderStyle.FixedDialog;
        this.Font = new Font("Segoe UI", 10, FontStyle.Regular);
        


        InitialiseControls();

        this.PerformLayout();

        // Add the layout panel directly to the form
        CPHLogger.LogDebug("Adding layout panel directly to the form.");
        this.Controls.Add(coreLayoutPanelForForm);

        // Perform layout on the layout panel
        coreLayoutPanelForForm.PerformLayout();
        UIStyling.StylePanel(coreLayoutPanelForForm);

        // Log height after layout (for debugging purposes)
        CPHLogger.LogInfo($"Main Layout Panel Height: {coreLayoutPanelForForm.Height}");
        CPHLogger.LogInfo($"Form Height: {this.Height}");
        
        // Optionally log the height of the form after layout
        CPHLogger.LogInfo($"Form Size: {this.ClientSize}");

        LogAllControlSizes();

    }

    // Method to create and add a tab with controls
    private void InitialiseControls()
    {
        // Apply consistent styling for other controls
        CPHLogger.LogDebug("Calling Form Styling");
        StyleForm();
        // Apply consistent styling for other controls
        StyleFormUserActionControls();
        StyleApplicationListControls();
        StyleActionListsControls();
        StyleStartupConfigControls();
        StyleFormFlowControls();
    }

    private void StyleForm()
    {
        CPHLogger.LogDebug("Styling base level form elements..");
    }

    private void StyleStartupConfigControls()
    {
        CPHLogger.LogDebug("Styling Start Up Config Controls.");
        UIStyling.StyleRadioButton(radioStartupConfigYes, "Yes");
        UIStyling.StyleRadioButton(radioStartupConfigNo, "No");
        UIStyling.StyleRadioButton(radioStartupConfigPrompt, "Prompt");
        UIStyling.StyleNumberUpDown(numupdwnStartupConfigDelay);
    }

    // Generic method to apply styling to application-related controls
    private void StyleApplicationListControls()
    {
        CPHLogger.LogDebug("Styling Application List Controls.");
        UIStyling.StyleLabel(lblStartupConfigDelay, "Delay (In Seconds)");
        UIStyling.StyleListBox(lstApplications);
        UIStyling.StyleBtn(btn: btnAddApplication, btnText: "Add Application", btnType: 2);
        UIStyling.StyleBtn(btn: btnRemoveApplication, btnText: "Remove Application", btnType: 2, btnEnabled: false);
        UIStyling.StyleBtn(btn: btnAddApplicationPath, btnText: "Add Path", btnType: 2);
        UIStyling.StyleArrowBtn(btnMoveUp, btnArrow: "▲");
        UIStyling.StyleArrowBtn(btnMoveDown, btnArrow: "▼");
    }

    // Generic method to apply styling to action-related controls
    private void StyleActionListsControls()
    {
        CPHLogger.LogDebug("Styling Action List Controls.");
        UIStyling.StyleListBox(lstActionsPermitted);
        UIStyling.StyleBtn(btn: btnAddActionPermitted, btnText: "Add Action", btnType: 2);
        UIStyling.StyleBtn(btn: btnRemoveActionPermitted, btnText: "Remove Action", btnType: 2, btnEnabled: false);
        UIStyling.StyleListBox(lstActionsBlocked);
        UIStyling.StyleBtn(btn: btnAddActionBlocked, btnText: "Add Action", btnType: 2);
        UIStyling.StyleBtn(btn: btnRemoveActionBlocked, btnText: "Remove Action", btnType: 2, btnEnabled: false);
    }

    // Generic method to apply styling to form control buttons
    private void StyleFormUserActionControls()
    {
        // Top Controls.
        CPHLogger.LogDebug("Styling Form Interaction Controls.");
        UIStyling.StyleBtn(btnResetAllSettings, btnText: "Remove All");
        UIStyling.StyleBtn(btnImportSettings, btnText: "Import");
        UIStyling.StyleBtn(btnExportSettings, btnText: "Export");
        UIStyling.StyleBtn(btnShowAbout, btnText: "About");
        UIStyling.StyleBtn(btnTestConfig, btnText: "Test");
    }

    private void StyleFormFlowControls()
    {
        CPHLogger.LogDebug("Styling Form Flow Controls.");
        UIStyling.StyleBtn(btnCloseForm, btnText: "Close", btnMargin: new Padding(5, 2, 5, 2), btnPadding: new Padding(5, 0, 5, 0));
        UIStyling.StyleBtn(btnSaveForm, btnText: "Save", btnMargin: new Padding(5, 2, 5, 2), btnPadding: new Padding(5, 0, 5, 0));
    }



    private void CenterForm(Rectangle activeWindowRect)
    {
        // Center the form on the screen
        CPHLogger.LogInfo($"[CenterForm][S] Getting center coordinates. {activeWindowRect.ToString()}");
        int centerX = activeWindowRect.Left + (activeWindowRect.Width - this.Width) / 2;
        int centerY = activeWindowRect.Top + (activeWindowRect.Height - this.Height) / 2;
        CPHLogger.LogInfo($"[CenterForm] Coordinates: X:{centerX} / Y:{centerY}");
        CPHLogger.LogDebug("[BuildCoreForm] Placing form location, and ordering");
        this.Location = new Point(centerX, centerY);
        this.TopMost = true;
    }


    // General method to create a layout panel for any tab
private TableLayoutPanel CreateBaseLevelTablePanel(Rectangle activeWindowRect, int rowCount = 6, int columnCount = 1)
{
    CPHLogger.LogInfo($"[CreateBaseLevelTablePanel][S] Cols: {columnCount} Rows: {rowCount}");
    var basePanelForForm = new TableLayoutPanel();
    CPHLogger.LogDebug("[TableLayoutPanel] BasePanelForForm created. Applying styling.");

    // Apply styling to the TableLayoutPanel
    UIStyling.StyleTableLayoutPanel(basePanelForForm, rowCount: rowCount, columnCount: columnCount);

    // Log size after styling
    CPHLogger.LogVerbose("[TableLayoutPanel] Returning Table Panel");
    return basePanelForForm;
}



    /* STARTUP TAB
    **
    **
    **
    **
    */
    private void AddConfigurationControls(TableLayoutPanel coreLayoutPanelForTab)
    {
        CPHLogger.LogInfo($"Table Size: {coreLayoutPanelForTab.Size}");
        // Create the group box.
        GroupBox configurationGroupBox = new GroupBox();
        UIStyling.StyleGroupBox(configurationGroupBox, "Manage your configuration");
        // Create the table for the configuration buttons.
        TableLayoutPanel buttonTable = new TableLayoutPanel();
        var numberOfCols = 5;
        var columnStyling = new List<ColumnStyle>();
        for (int i = 0; i < numberOfCols; i++)
        {
            buttonTable.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, (100 / numberOfCols)));
        }

        UIStyling.StyleTableLayoutPanel(buttonTable, columnCount: numberOfCols, customRowStyles: null, customColumnStyles: columnStyling);
        // Add buttons to the TableLayoutPanel
        buttonTable.Controls.Add(btnResetAllSettings, 0, 0);
        buttonTable.Controls.Add(btnImportSettings, 1, 0);
        buttonTable.Controls.Add(btnExportSettings, 2, 0);
        buttonTable.Controls.Add(btnShowAbout, 3, 0);
        buttonTable.Controls.Add(btnTestConfig, 4, 0);
        // Add click event handlers for the buttons
        btnResetAllSettings.Click += MainCanvasCloseButton_Click;
        btnImportSettings.Click += MainCanvasCloseButton_Click;
        btnExportSettings.Click += MainCanvasCloseButton_Click;
        btnShowAbout.Click += MainCanvasCloseButton_Click;
        btnTestConfig.Click += MainCanvasCloseButton_Click;
        // Add the TableLayoutPanel to the GroupBox
        configurationGroupBox.Controls.Add(buttonTable);
        //coreLayoutPanelForTab.PerformLayout();
        CPHLogger.LogInfo($"Table Size: {coreLayoutPanelForTab.Size}");
        // Add the GroupBox to the main layout
        coreLayoutPanelForTab.Controls.Add(configurationGroupBox);
    }

    // Flow control. Save and exit buttons.
    //ToDo: Centralise buttons to the bottom.
    private void AddApplicationControlButtons(TableLayoutPanel coreLayoutPanelForTab)
    {
        CPHLogger.LogInfo($"Table Size: {coreLayoutPanelForTab.Size}");
        FlowLayoutPanel buttonPanel = new FlowLayoutPanel();
        UIStyling.StyleFlowBox(flowBox: buttonPanel);
        // Center-align the content within the FlowLayoutPanel
        buttonPanel.Anchor = AnchorStyles.None;
        buttonPanel.WrapContents = false;
        //buttonPanel.HorizontalAlign = ContentAlignment.MiddleCenter;
        // Add buttons to the FlowLayoutPanel
        buttonPanel.Controls.Add(btnSaveForm);
        buttonPanel.Controls.Add(btnCloseForm);
        // Attach click event handlers
        btnSaveForm.Click += MainCanvasSaveButton_Click;
        btnCloseForm.Click += MainCanvasCloseButton_Click;
        coreLayoutPanelForTab.PerformLayout();
        CPHLogger.LogInfo($"Table Size: {coreLayoutPanelForTab.Size}");
        // Add the button panel to the main layout panel
        coreLayoutPanelForTab.Controls.Add(buttonPanel);
    }

    private void AddApplicationControls(TableLayoutPanel coreLayoutPanelForTab)
    {
        CPHLogger.LogInfo($"Table Size: {coreLayoutPanelForTab.Size}");
        // Create the Applications group box.
        GroupBox applicationsToStartGroupBox = new GroupBox();
        UIStyling.StyleGroupBox(applicationsToStartGroupBox, "Applications to run on bot startup");
        // Create the application table.
        TableLayoutPanel tpanelApplications = new TableLayoutPanel();
        var rowStyling = new List<RowStyle>
        {
            new RowStyle(SizeType.AutoSize),
            new RowStyle(SizeType.AutoSize),
        };
        var columnStyling = new List<ColumnStyle>
        {
            new ColumnStyle(SizeType.Percent, 100),
            new ColumnStyle(SizeType.AutoSize),
        };
        UIStyling.StyleTableLayoutPanel(tpanelApplications, rowCount: 2, customRowStyles: rowStyling, customColumnStyles: columnStyling);
        // Add list box
        tpanelApplications.Controls.Add(lstApplications, 0, 0);
        // Create panel for Add/Remove buttons
        FlowLayoutPanel buttonPanel = new FlowLayoutPanel();
        UIStyling.StyleFlowBox(flowBox: buttonPanel, fBoxDirection: FlowDirection.TopDown, anchorStyle: AnchorStyles.Top);
        buttonPanel.Controls.Add(btnAddApplication);
        buttonPanel.Controls.Add(btnRemoveApplication);
        buttonPanel.Controls.Add(btnAddApplicationPath);
        // Add button panel
        tpanelApplications.Controls.Add(buttonPanel, 1, 0);
        // Add arrow buttons
        FlowLayoutPanel fpanelApplicationArrows = new FlowLayoutPanel();
        UIStyling.StyleFlowBox(flowBox: fpanelApplicationArrows, customPadding: new Padding(1, 1, 5, 1), anchorStyle: AnchorStyles.Right);
        // Create the arrow buttons.
        fpanelApplicationArrows.Controls.Add(btnMoveUp);
        fpanelApplicationArrows.Controls.Add(btnMoveDown);
        // Add arrowButtonsPanel below the ListBox, centered
        tpanelApplications.Controls.Add(fpanelApplicationArrows, 0, 1);
        // Attach event handlers.
        lstApplications.SelectedIndexChanged += ApplicationListBox_SelectedIndexChanged;
        btnAddApplication.Click += AddApplication_Click;
        btnAddApplicationPath.Click += AddApplicationPath_Click;
        btnRemoveApplication.Click += RemoveApplication_Click;
        btnMoveUp.Click += btnApplicationsUp_Click;
        btnMoveDown.Click += btnApplicationsDown_Click;
        applicationsToStartGroupBox.Controls.Add(tpanelApplications);
        coreLayoutPanelForTab.PerformLayout();
        CPHLogger.LogInfo($"Table Size: {coreLayoutPanelForTab.Size}");
        coreLayoutPanelForTab.Controls.Add(applicationsToStartGroupBox);
    }

    private void AddSeparateActionGroups(TableLayoutPanel coreLayoutPanelForTab)
    {
        CPHLogger.LogInfo($"Table Size: {coreLayoutPanelForTab.Size}");
        // Create a GroupBox for "Allowed Actions"
        GroupBox allowedActionsGroupBox = CreateActionsGroupBox("Allowed Actions", lstActionsPermitted, btnAddActionPermitted, btnRemoveActionPermitted, AddActionPermitted_SelIndhanged, AddActionPermitted_Click, RemoveActionPermitted_Click);
        // Create a GroupBox for "Blocked Actions"
        GroupBox blockedActionsGroupBox = CreateActionsGroupBox("Blocked Actions", lstActionsBlocked, btnAddActionBlocked, btnRemoveActionBlocked, AddActionBlocked_SelIndhanged, AddActionBlocked_Click, RemoveActionBlocked_Click);
        // Add both GroupBoxes to the main layout
        coreLayoutPanelForTab.Controls.Add(allowedActionsGroupBox);
        coreLayoutPanelForTab.Controls.Add(blockedActionsGroupBox);
        coreLayoutPanelForTab.PerformLayout();
        CPHLogger.LogInfo($"Table Size: {coreLayoutPanelForTab.Size}");
    }

    private GroupBox CreateActionsGroupBox(string title, ListBox listBox, Button addButton, Button removeButton, EventHandler listBoxSelected, EventHandler addButtonClick, EventHandler removeButtonClick)
    {
        GroupBox actionsGroupBox = new GroupBox();
        UIStyling.StyleGroupBox(actionsGroupBox, title);
        TableLayoutPanel actionsPanel = new TableLayoutPanel();
        var rowStyling = new List<RowStyle>
        {
            new RowStyle(SizeType.AutoSize)
        };
        var columnStyling = new List<ColumnStyle>
        {
            new ColumnStyle(SizeType.Percent, 100),
            new ColumnStyle(SizeType.AutoSize),
        };
        UIStyling.StyleTableLayoutPanel(actionsPanel, customRowStyles: rowStyling, customColumnStyles: columnStyling);
        // Add ListBox to the panel
        actionsPanel.Controls.Add(listBox, 0, 0);
        FlowLayoutPanel buttonPanel = new FlowLayoutPanel();
        UIStyling.StyleFlowBox(buttonPanel, FlowDirection.LeftToRight, autoWrap: true, anchorStyle: AnchorStyles.Top);
        // Add buttons to the button panel
        buttonPanel.Controls.Add(addButton);
        buttonPanel.Controls.Add(removeButton);
        // Add button panel to the layout
        actionsPanel.Controls.Add(buttonPanel, 1, 0);
        // Attach event handlers
        listBox.SelectedIndexChanged += listBoxSelected;
        addButton.Click += addButtonClick;
        removeButton.Click += removeButtonClick;
        // Add the layout to the GroupBox
        actionsGroupBox.Controls.Add(actionsPanel);
        return actionsGroupBox;
    }

    private void AddStartupConfigurationControls(TableLayoutPanel coreLayoutPanelForTab)
    {
        GroupBox startupOptionsGroup = new GroupBox();
        UIStyling.StyleGroupBox(startupOptionsGroup, "Load Applications on Startup", 60);
        TableLayoutPanel startupOptionsPanel = new TableLayoutPanel();
        var columnStyling = new List<ColumnStyle>
        {
            new ColumnStyle(SizeType.Absolute, 55),
            new ColumnStyle(SizeType.Absolute, 55),
            new ColumnStyle(SizeType.Absolute, 70),
            new ColumnStyle(SizeType.Percent, 100),
            new ColumnStyle(SizeType.Absolute, 140),
            new ColumnStyle(SizeType.Absolute, 50),
        };
        UIStyling.StyleTableLayoutPanel(startupOptionsPanel, columnCount: 6, customColumnStyles: columnStyling);
        // Styled radio buttons
        radioStartupConfigYes.Font = new Font("Segoe UI", 9);
        radioStartupConfigNo.Font = new Font("Segoe UI", 9);
        radioStartupConfigPrompt.Font = new Font("Segoe UI", 9);
        // Styled delay controls
        lblStartupConfigDelay.ForeColor = Color.DimGray;
        numupdwnStartupConfigDelay.BackColor = Color.White;
        // Add controls to the layout panel
        startupOptionsPanel.Controls.Add(radioStartupConfigYes, 0, 0);
        startupOptionsPanel.Controls.Add(radioStartupConfigNo, 1, 0);
        startupOptionsPanel.Controls.Add(radioStartupConfigPrompt, 2, 0);
        startupOptionsPanel.Controls.Add(lblStartupConfigDelay, 4, 0);
        startupOptionsPanel.Controls.Add(numupdwnStartupConfigDelay, 5, 0);
        startupOptionsGroup.Controls.Add(startupOptionsPanel);
        coreLayoutPanelForTab.Controls.Add(startupOptionsGroup);
    }

    private void AddApplication_Click(object sender, EventArgs e)
    {
        int a = 1;
    }

    private void AddApplicationPath_Click(object sender, EventArgs e)
    {
        int a = 1;
    }

    private void RemoveApplication_Click(object sender, EventArgs e)
    {
        int a = 1;
    }

    private void ApplicationListBox_SelectedIndexChanged(object sender, EventArgs e)
    {
        int a = 1;
    }

    private void AddActionPermitted_SelIndhanged(object sender, EventArgs e)
    {
        int a = 1;
    }

    private void AddActionPermitted_Click(object sender, EventArgs e)
    {
        int a = 1;
    }

    private void RemoveActionPermitted_Click(object sender, EventArgs e)
    {
        int a = 1;
    }

    private void AddActionBlocked_SelIndhanged(object sender, EventArgs e)
    {
        int a = 1;
    }

    private void AddActionBlocked_Click(object sender, EventArgs e)
    {
        int a = 1;
    }

    private void RemoveActionBlocked_Click(object sender, EventArgs e)
    {
        int a = 1;
    }

    // Start dragging the item if the mouse is pressed down
    private void ListBox_MouseDown(object sender, MouseEventArgs mouseEventArgs)
    {
        int a = 1;
    }

    // Handle moving the item if the mouse is dragged
    private void ListBox_MouseMove(object sender, MouseEventArgs mouseEventArgs)
    {
        int a = 1;
    }

    private void ListBox_DragOver(object sender, DragEventArgs dragEventArgs)
    {
        int a = 1;
    }

    private void btnApplicationsUp_Click(object sender, EventArgs clickEventArgs)
    {
        int a = 1;
    }

    private void btnApplicationsDown_Click(object sender, EventArgs clickEventArgs)
    {
        int a = 1;
    }

    // Reorder the item when dropped in a new position    
    private void MainCanvasSaveButton_Click(object sender, EventArgs e)
    {
        int a = 1;
    }

    private void MainCanvasCloseButton_Click(object sender, EventArgs e)
    {
        this.Close();
    }



    public void LogAllControlSizes()
    {
        CPHLogger.LogInfo("Logging sizes of all controls in the form...");
        LogControlDetails(this); // Start logging from the form itself
    }

    private void LogControlDetails(Control parent, int depth = 0)
    {
        // Indentation for nested controls
        string indent = new string (' ', depth * 4);
        // Log the current control's basic details
        CPHLogger.LogInfo($"{indent}Control: {parent.Name ?? parent.GetType().Name}, " + $"Type: {parent.GetType().Name}, " + $"Size: {parent.Size.Width}x{parent.Size.Height}, " + $"Location: {parent.Location.X},{parent.Location.Y}, " + $"Dock: {parent.Dock}, " + $"Anchor: {parent.Anchor}, " + $"AutoSize: {parent.AutoSize}, " + $"AutoSizeMode: {(parent is TableLayoutPanel tlp ? tlp.AutoSizeMode.ToString() : "N/A")}, " + $"MinimumSize: {parent.MinimumSize.Width}x{parent.MinimumSize.Height}, " + $"MaximumSize: {parent.MaximumSize.Width}x{parent.MaximumSize.Height}, " + $"Margin: {parent.Margin.Left},{parent.Margin.Top},{parent.Margin.Right},{parent.Margin.Bottom}, " + $"Padding: {parent.Padding.Left},{parent.Padding.Top},{parent.Padding.Right},{parent.Padding.Bottom}, " + $"Text: \"{parent.Text}\"");
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
                CPHLogger.LogDebug($"{indent}  Difference in Dock: Current={control.Dock}, Default={defaultInstance.Dock}");
            if (control.Anchor != defaultInstance.Anchor)
                CPHLogger.LogDebug($"{indent}  Difference in Anchor: Current={control.Anchor}, Default={defaultInstance.Anchor}");
            if (control.AutoSize != defaultInstance.AutoSize)
                CPHLogger.LogDebug($"{indent}  Difference in AutoSize: Current={control.AutoSize}, Default={defaultInstance.AutoSize}");
            if (control.Font != defaultInstance.Font)
                CPHLogger.LogDebug($"{indent}  Difference in Font: Current={control.Font}, Default={defaultInstance.Font}");
            if (control.Margin != defaultInstance.Margin)
                CPHLogger.LogDebug($"{indent}  Difference in Margin: Current={control.Margin}, Default={defaultInstance.Margin}");
            if (control.Padding != defaultInstance.Padding)
                CPHLogger.LogDebug($"{indent}  Difference in Padding: Current={control.Padding}, Default={defaultInstance.Padding}");
            // Dispose the default instance to free resources
            defaultInstance.Dispose();
        }
        catch (Exception ex)
        {
            CPHLogger.LogError($"{indent}  Failed to compare default values: {ex.Message}");
        }
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

public static class UIStyling
{
    public static void StyleNumberUpDown(NumericUpDown numericUpDown)
    {
        numericUpDown.Width = 40;
        numericUpDown.Minimum = 0;
        numericUpDown.Maximum = 30;
        numericUpDown.Value = 2;
        numericUpDown.Anchor = AnchorStyles.Left;
        numericUpDown.Margin = new Padding(2, 0, 0, 0);
        // Verbose logging with all properties and object name
        CPHLogger.LogDebug($"Styled NumericUpDown (Name={numericUpDown.Name}): Width={numericUpDown.Width}, Height={numericUpDown.Height}, " + $"Min={numericUpDown.Minimum}, Max={numericUpDown.Maximum}, Value={numericUpDown.Value}, " + $"Anchor={numericUpDown.Anchor}, Margin={numericUpDown.Margin}, Padding={numericUpDown.Padding}, " + $"TextAlign={numericUpDown.TextAlign}");
    }

    public static void StyleRadioButton(RadioButton radioButton, string prompt)
    {
        radioButton.Text = prompt;
        radioButton.AutoSize = true;
        radioButton.Dock = DockStyle.Fill;
        radioButton.TextAlign = ContentAlignment.MiddleLeft;
        // Verbose logging with all properties and object name
        CPHLogger.LogDebug($"Styled RadioButton (Name={radioButton.Name}): Width={radioButton.Width}, Height={radioButton.Height}, " + $"Text={radioButton.Text}, AutoSize={radioButton.AutoSize}, Dock={radioButton.Dock}, " + $"TextAlign={radioButton.TextAlign}, Checked={radioButton.Checked}, Margin={radioButton.Margin}, " + $"Padding={radioButton.Padding}, Font={radioButton.Font.Name}");
    }

    public static void StyleLabel(Label label, string labelText)
    {
        label.Text = labelText;
        label.AutoSize = true;
        label.Dock = DockStyle.Fill;
        label.TextAlign = ContentAlignment.MiddleLeft;
        // Verbose logging with all properties and object name
        CPHLogger.LogDebug($"Styled Label (Name={label.Name}): Width={label.Width}, Height={label.Height}, Text={label.Text}, " + $"AutoSize={label.AutoSize}, Dock={label.Dock}, TextAlign={label.TextAlign}, " + $"Margin={label.Margin}, Padding={label.Padding}, Font={label.Font.Name}");
    }

    public static void StyleBtn(Button btn, string btnText, int btnType = 1, bool btnEnabled = true, Padding? btnMargin = null, Padding? btnPadding = null)
    {
        // Set button properties
        btn.Text = btnText;
        btn.Height = 24;
        btn.Enabled = btnEnabled;
        btn.Font = new Font("Microsoft Sans Serif", 8.5f);
        btn.BackColor = Color.White;
        btn.ForeColor = SystemColors.ControlText;
        btn.FlatAppearance.BorderSize = 1;
        btn.FlatAppearance.BorderColor = Color.DarkGray;
        // Button type specific properties
        switch (btnType)
        {
            case 1:
                btn.Width = 90;
                btn.Margin = btnMargin ?? new Padding(0, 0, 0, 0);
                btn.Padding = btnPadding ?? new Padding(2, 2, 2, 2);
                break;
            case 2:
                btn.Width = 120;
                btn.Margin = btnMargin ?? new Padding(1, 3, 1, 1);
                btn.Padding = btnPadding ?? new Padding(2, 2, 2, 2);
                break;
            default:
                btn.Width = 90;
                btn.Margin = btnMargin ?? new Padding(0, 0, 0, 0);
                btn.Padding = btnPadding ?? new Padding(2, 2, 2, 2);
                break;
        }

        // Verbose logging with all properties and object name
        CPHLogger.LogDebug($"Styled Button (Name={btn.Name}): Width={btn.Width}, Height={btn.Height}, Text={btn.Text}, " + $"Enabled={btn.Enabled}, Margin={btn.Margin}, Padding={btn.Padding}, Font={btn.Font.Name}, " + $"BackColor={btn.BackColor}, ForeColor={btn.ForeColor}, BorderSize={btn.FlatAppearance.BorderSize}, " + $"BorderColor={btn.FlatAppearance.BorderColor}");
    }

    public static void StyleArrowBtn(Button btn, string btnArrow)
    {
        btn.Text = btnArrow;
        btn.Width = 20;
        btn.Height = 20;
        btn.Margin = new Padding(1, 0, 1, 0);
        btn.Padding = new Padding(0, 0, 0, 0);
        // Verbose logging with all properties and object name
        CPHLogger.LogDebug($"Styled ArrowButton (Name={btn.Name}): Width={btn.Width}, Height={btn.Height}, Text={btn.Text}, " + $"Margin={btn.Margin}, Padding={btn.Padding}, BackColor={btn.BackColor}, ForeColor={btn.ForeColor}, " + $"Font={btn.Font.Name}");
    }

    public static void StyleListBox(ListBox listBox)
    {
        listBox.Font = new Font("Segoe UI", 10, FontStyle.Regular);
        listBox.BackColor = Color.White;
        listBox.ForeColor = Color.Black;
        listBox.BorderStyle = BorderStyle.FixedSingle;
        listBox.Dock = DockStyle.Fill;
        listBox.Height = 140;
        listBox.Width = 250;
        listBox.Padding = new Padding(5, 5, 5, 0);
        listBox.Margin = new Padding(5, 5, 5, 0);
        // Verbose logging with all properties and object name
        CPHLogger.LogDebug($"Styled ListBox (Name={listBox.Name}): Width={listBox.Width}, Height={listBox.Height}, Font={listBox.Font.Name}, " + $"ForeColor={listBox.ForeColor}, Dock={listBox.Dock}, Padding={listBox.Padding}, Margin={listBox.Margin}, " + $"BorderStyle={listBox.BorderStyle}");
    }

    public static void StylePanel(Panel panel, Padding? panelPadding = null)
    {
        panel.Dock = DockStyle.Fill;
        panel.AutoScroll = true;
        panel.Padding = panelPadding ?? new Padding(0);
        panel.BackColor = Color.WhiteSmoke;
        panel.BorderStyle = BorderStyle.FixedSingle;
        // Verbose logging with all properties and object name
        CPHLogger.LogDebug($"Styled Panel (Name={panel.Name}): Width={panel.Width}, Height={panel.Height}, AutoScroll={panel.AutoScroll}, " + $"Padding={panel.Padding}, BorderStyle={panel.BorderStyle}, BackColor={panel.BackColor}, Dock={panel.Dock}");
    }

    public static void StyleFlowBox(FlowLayoutPanel flowBox, FlowDirection fBoxDirection = FlowDirection.LeftToRight, // Default to LeftToRight
 bool autoWrap = true, Padding? customPadding = null, // Allow optional padding
 AnchorStyles anchorStyle = AnchorStyles.Top | AnchorStyles.Left | AnchorStyles.Right | AnchorStyles.Bottom // Default anchor
    )
    {
        flowBox.FlowDirection = fBoxDirection;
        flowBox.WrapContents = autoWrap;
        flowBox.Anchor = anchorStyle;
        flowBox.AutoSize = true;
        flowBox.AutoSizeMode = AutoSizeMode.GrowAndShrink;
        flowBox.Padding = customPadding ?? new Padding(0);
        flowBox.Margin = customPadding ?? new Padding(0);
        flowBox.BackColor = Color.WhiteSmoke;
        flowBox.BorderStyle = BorderStyle.FixedSingle;
        // Verbose logging with all properties and object name
        CPHLogger.LogDebug($"Styled FlowLayoutPanel (Name={flowBox.Name}): Width={flowBox.Width}, Height={flowBox.Height}, " + $"FlowDirection={flowBox.FlowDirection}, WrapContents={flowBox.WrapContents}, Anchor={flowBox.Anchor}, " + $"AutoSize={flowBox.AutoSize}, Padding={flowBox.Padding}, Margin={flowBox.Margin}, " + $"BackColor={flowBox.BackColor}, BorderStyle={flowBox.BorderStyle}");
    }

    public static void StyleTableLayoutPanel(TableLayoutPanel tableLayoutPanel, int columnCount = 2, int rowCount = 1, List<RowStyle> customRowStyles = null, List<ColumnStyle> customColumnStyles = null, bool autoSizeTable = true)
    {
        tableLayoutPanel.ColumnCount = columnCount;
        tableLayoutPanel.RowCount = rowCount;
        tableLayoutPanel.Dock = DockStyle.Fill;
        tableLayoutPanel.AutoSizeMode = AutoSizeMode.GrowAndShrink;
        tableLayoutPanel.Padding = new Padding(0);
        tableLayoutPanel.Margin = new Padding(0);
        tableLayoutPanel.CellBorderStyle = TableLayoutPanelCellBorderStyle.Single;
        tableLayoutPanel.AutoSize = autoSizeTable;
        if (autoSizeTable)
        {
            tableLayoutPanel.AutoSizeMode = AutoSizeMode.GrowAndShrink;
        }
        else
        {
            tableLayoutPanel.AutoSizeMode = AutoSizeMode.GrowOnly;
        }

        // Apply row styles
        for (int i = 0; i < rowCount; i++)
        {
            RowStyle rowStyle = i < customRowStyles?.Count ? customRowStyles[i] : new RowStyle(SizeType.AutoSize);
            tableLayoutPanel.RowStyles.Add(rowStyle);
        }

        // Apply column styles
        for (int i = 0; i < columnCount; i++)
        {
            ColumnStyle columnStyle = i < customColumnStyles?.Count ? customColumnStyles[i] : new ColumnStyle(SizeType.Percent, 100f / columnCount);
            tableLayoutPanel.ColumnStyles.Add(columnStyle);
        }

        // Verbose logging with all properties and object name
        CPHLogger.LogDebug($"Styled TableLayoutPanel (Name={tableLayoutPanel.Name}): Width={tableLayoutPanel.Width}, Height={tableLayoutPanel.Height}, " + $"ColumnCount={tableLayoutPanel.ColumnCount}, RowCount={tableLayoutPanel.RowCount}, AutoSize={tableLayoutPanel.AutoSize}, " + $"Padding={tableLayoutPanel.Padding}, Margin={tableLayoutPanel.Margin}, CellBorderStyle={tableLayoutPanel.CellBorderStyle}, " + $"AutoSizeMode={tableLayoutPanel.AutoSizeMode}");
        CPHLogger.LogDebug($"ColumnStyle: {string.Join(", ", tableLayoutPanel.ColumnStyles.Cast<ColumnStyle>().Select(cs => cs.SizeType.ToString()))}");
        CPHLogger.LogDebug($"RowStyle: {string.Join(", ", tableLayoutPanel.RowStyles.Cast<RowStyle>().Select(rs => rs.SizeType.ToString()))}");
    }

    public static void StyleGroupBox(GroupBox groupBox, string text = null, int? height = null)
    {
        groupBox.Font = new Font("Segoe UI", 10, FontStyle.Bold);
        groupBox.ForeColor = Color.DimGray;
        groupBox.BackColor = Color.WhiteSmoke;
        groupBox.Dock = DockStyle.Fill;
        groupBox.Padding = new Padding(2, 2, 2, 2);
        groupBox.Margin = new Padding(2, 2, 2, 2);
        groupBox.AutoSize = !height.HasValue;
        if (height.HasValue)
            groupBox.Height = height.Value;
        if (!string.IsNullOrEmpty(text))
            groupBox.Text = text;
        // Verbose logging with all properties and object name
        CPHLogger.LogDebug($"Styled GroupBox (Name={groupBox.Name}): Width={groupBox.Width}, Height={groupBox.Height}, " + $"Text={groupBox.Text}, AutoSize={groupBox.AutoSize}, Padding={groupBox.Padding}, " + $"Margin={groupBox.Margin}, BackColor={groupBox.BackColor}, ForeColor={groupBox.ForeColor}, Dock={groupBox.Dock}");
    }

    public static void StyleTabControl(TabControl tabControl)
    {
        tabControl.Dock = DockStyle.Fill;
        tabControl.Font = new Font("Segoe UI", 10, FontStyle.Regular);
        tabControl.Padding = new Point(0, 0);
        tabControl.Appearance = TabAppearance.FlatButtons; // Set tabs to flat style
        tabControl.ItemSize = new Size(120, 20); // Custom size for each tab
        tabControl.DrawMode = TabDrawMode.OwnerDrawFixed; // Enable custom drawing
        tabControl.DrawItem += (s, e) => // Define custom drawing behavior
        {
            // Fill tab background with custom color
            e.Graphics.FillRectangle(new SolidBrush(Color.WhiteSmoke), e.Bounds);
            // Draw the tab text with custom color
            TextRenderer.DrawText(e.Graphics, tabControl.TabPages[e.Index].Text, e.Font, e.Bounds, Color.Black);
        };
        // Verbose logging with all properties and object name
        CPHLogger.LogDebug($"Styled TabControl (Name={tabControl.Name}): Width={tabControl.Width}, Height={tabControl.Height}, " + $"ItemSize={tabControl.ItemSize}, TabCount={tabControl.TabPages.Count}, Padding={tabControl.Padding}, " + $"Appearance={tabControl.Appearance}, DrawMode={tabControl.DrawMode}");
    }
}

public static class Constants
{
    public const string ExecutableFilter = "Executable Files (*.exe)|*.exe|All Files (*.*)|*.*";
    public const string SettingsFileName = "settings.json";
    public const string FormName = "SBZen Config Manager";
    public static readonly string DataDir = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "data");
    public enum StartupMode
    {
        Yes,
        No,
        Prompt,
    }
}

public class CPHLogger : SB
{
    // LogDebug: Logs a debug-level message.
    public static void LogDebug(string message)
    {
        CPH.LogDebug($"[DEBUG] {message}");
    }

    // LogError: Logs an error-level message.
    public static void LogError(string message)
    {
        CPH.LogError($"[ERROR] {message}");
    }

    // LogInfo: Logs an info-level message.
    public static void LogInfo(string message)
    {
        CPH.LogInfo($"[INFO] {message}");
    }

    // LogVerbose: Logs a verbose-level message.
    public static void LogVerbose(string message)
    {
        CPH.LogVerbose($"[VERBOSE] {message}");
    }

    // LogWarn: Logs a warning-level message.
    public static void LogWarn(string message)
    {
        CPH.LogWarn($"[WARN] {message}");
    }

    // Log: General logging method that dynamically adjusts log level.
    public static void Log(string message, string logLevel = "INFO")
    {
        switch (logLevel.ToUpper())
        {
            case "DEBUG":
                LogDebug(message);
                break;
            case "ERROR":
                LogError(message);
                break;
            case "VERBOSE":
                LogVerbose(message);
                break;
            case "WARN":
                LogWarn(message);
                break;
            default:
                LogInfo(message);
                break;
        }
    }
}

public class SB
{
    public static IInlineInvokeProxy CPH;
    public static Dictionary<string, object> args;
}