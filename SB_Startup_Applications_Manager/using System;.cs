Sourcecode: 

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
using System.ComponentModel;
using System.Reflection;     

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
	private IInlineInvokeProxy CPH; // Field to hold the CPH object
    private List<ActionData> actionDataList;

    //SB_SAM Startup Configuration Buttons.
    private RadioButton radioStartupConfigYes = new RadioButton();
    private RadioButton radioStartupConfigNo = new RadioButton();
    private RadioButton radioStartupConfigPrompt = new RadioButton();

    private Label lblStartupConfigDelay = new Label
    {
        Text = "Delay (In seconds)",
        AutoSize = true,
        Dock = DockStyle.Fill,
        TextAlign = ContentAlignment.MiddleLeft,
    };

    private NumericUpDown numupdwnStartupConfigDelay = new NumericUpDown
    {
        Width = 40,
        Minimum = 0,
        Maximum = 30,
        Value = 2,
        Anchor = AnchorStyles.Left,
        Margin = new Padding(2, 0, 0, 0),
    };

    private int indexOfListItem;

    // Application Start-up IO's.
    private ListBox lstApplications = new ListBox();
    private Button btnAddApplication = new Button { Text = "Add Application" };
    private Button btnAddApplicationPath = new Button { Text = "Add Path" };
    private Button btnRemoveApplication = new Button
    {
        Text = "Remove Application",
        Enabled = false,
    };
    private Button btnMoveUp = new Button { Text = "▲" };
    private Button btnMoveDown = new Button { Text = "▼" };

    // Actions Startup Permitted IO's
    private ListBox lstActionsPermitted = new ListBox();
    private Button btnAddActionPermitted = new Button { Text = "Add Action" };
    private Button btnRemoveActionPermitted = new Button
    {
        Text = "Remove Action",
        Enabled = false,
    };

    private ListBox lstActionsBlocked = new ListBox();
    private Button btnAddActionBlocked = new Button { Text = "Add Action" };
    private Button btnRemoveActionBlocked = new Button { Text = "Remove Action", Enabled = false };

    //User Settings Controls
    private Button btnResetAllSettings = new Button { Text = "Remove All" };
    private Button btnImportSettings = new Button { Text = "Import" };
    private Button btnExportSettings = new Button { Text = "Export" };

    // Main Form Controls.
    private Button btnSaveForm = new Button { Text = "Save", Enabled = false };
    private Button btnCloseForm = new Button { Text = "Close" };
    private Button btnShowAbout = new Button { Text = "About" };
    private Button btnTestConfig = new Button { Text = "Test" };

    // Tooltips.
    private ToolTip toolTip = new ToolTip();

    public LoadStartupConfigForm(Rectangle activeWindowRect, List<ActionData> actions)
    {
        // Locally store the list of actions
        actionDataList = actions;

        // Build the core form layout
        CPHLogger.LogDebug("Building base form structure.");
        var tabControl = BuildCoreForm(activeWindowRect);

        // Add tabs with specific configurations
        CPHLogger.LogDebug("Calling AddTabWithControls for the Streamer Bot Started tab");
        AddTabWithControls(tabControl, "Startup", AddStartupTabControls);
        CPHLogger.LogDebug("Calling AddTabWithControls for the Stream Ending tab");
        //AddTabWithControls(tabControl, "Stream Ending", AddStreamEndingTabControls);
        CPHLogger.LogDebug("Calling AddTabWithControls for the Support Me tab");
        //AddTabWithControls(tabControl, "Support", AddSupportTabControls);

        // Initialize controls with styles
        CPHLogger.LogDebug("Calling InitialiseControls.");
        InitialiseControls();

        // Add TabControl to the form
        CPHLogger.LogDebug("Adding TabControl to the base form.");
        this.Controls.Add(tabControl);
    }

    // Method to create and add a tab with controls
    private void AddTabWithControls(
        TabControl tabControl,
        string title,
        Action<TabPage> addControls
    )
    {
        CPHLogger.LogDebug($"Creating tab page: {title}");
        var tabPage = CreateTabPage(title);
        CPHLogger.LogDebug($"Adding tab controls: {title}");
        addControls(tabPage); 
        CPHLogger.LogDebug($"Adding tab page to form: {title}");
        tabControl.TabPages.Add(tabPage);
    }

    private void InitialiseControls()
    {
        // Apply consistent styling for other controls
        CPHLogger.LogDebug("Calling: StyleFormUserActionControls");
        StyleFormUserActionControls();

        CPHLogger.LogDebug("Calling: StyleApplicationListControls");
        StyleApplicationListControls();

        CPHLogger.LogDebug("Calling: StyleActionListsControls");
        StyleActionListsControls();

        CPHLogger.LogDebug("Calling: StyleStartupConfigControls");
        StyleStartupConfigControls();

        CPHLogger.LogDebug("Calling: StyleFormFlowControls");
        StyleFormFlowControls();
    }

    private void StyleStartupConfigControls()
    {
        CPHLogger.LogDebug("Styling Start Up Config Controls.");
        UIStyling.StyleRadioButton(radioStartupConfigYes, "Yes");
        UIStyling.StyleRadioButton(radioStartupConfigNo, "No");
        UIStyling.StyleRadioButton(radioStartupConfigPrompt, "Prompt");
    }

    // Generic method to apply styling to application-related controls
    private void StyleApplicationListControls()
    {
        CPHLogger.LogDebug("Styling Application List Controls.");
        UIStyling.StyleListBox(lstApplications);
        UIStyling.StyleLongerButton(btnAddApplication);
        UIStyling.StyleLongerButton(btnAddApplicationPath);
        UIStyling.StyleLongerButton(btnRemoveApplication);
        UIStyling.StyleArrowButton(btnMoveUp);
        UIStyling.StyleArrowButton(btnMoveDown);
    }

    // Generic method to apply styling to action-related controls
    private void StyleActionListsControls()
    {
        CPHLogger.LogDebug("Styling Action List Controls.");
        UIStyling.StyleListBox(lstActionsPermitted);
        UIStyling.StyleLongerButton(btnAddActionPermitted);
        UIStyling.StyleLongerButton(btnRemoveActionPermitted);
        UIStyling.StyleListBox(lstActionsBlocked);
        UIStyling.StyleLongerButton(btnAddActionBlocked);
        UIStyling.StyleLongerButton(btnRemoveActionBlocked);
    }

    // Generic method to apply styling to form control buttons
    private void StyleFormUserActionControls()
    {
        // Top Controls.
        CPHLogger.LogDebug("Styling Form Interaction Controls.");
        UIStyling.StyleMainButton(btnResetAllSettings);
        UIStyling.StyleMainButton(btnImportSettings);
        UIStyling.StyleMainButton(btnExportSettings);
        UIStyling.StyleMainButton(btnShowAbout);
        UIStyling.StyleMainButton(btnTestConfig);
    }

    private void StyleFormFlowControls()
    {
        CPHLogger.LogDebug("Styling Form Flow Controls.");
        UIStyling.StyleMainButton(btnCloseForm);
        UIStyling.StyleMainButton(btnSaveForm);
    }

    // Refactored BuildCoreForm to make it cleaner
    private TabControl BuildCoreForm(Rectangle activeWindowRect)
    {
        // Configure form properties
        CPHLogger.LogDebug("[BuildCoreForm][S] Setting Form Name");
        this.Text = Constants.FormName;
        CPHLogger.LogInfo($"Form Name: {this.Text}");

        CPHLogger.LogDebug("[BuildCoreForm] Setting Form base Size");
        this.Width = 600;
        this.Height = 800;
        CPHLogger.LogInfo($"Form Size. W:{this.Width} H:{this.Height}");

        CPHLogger.LogDebug("[BuildCoreForm] Setting Auto Size Properties");
        this.AutoSize = true;
        this.AutoSizeMode = AutoSizeMode.GrowAndShrink;

        CPHLogger.LogDebug("[BuildCoreForm] Setting a minimum size.");
        this.MinimumSize = new Size(600, 600);
        CPHLogger.LogInfo($"Form Size. W:{this.Width} H:{this.Height}");
        
        CPHLogger.LogDebug("[BuildCoreForm] Setting base form styling.");
        this.BackColor = Color.WhiteSmoke;
        this.FormBorderStyle = FormBorderStyle.FixedDialog;
        this.Font = new Font("Segoe UI", 10, FontStyle.Regular);

        CPHLogger.LogDebug("[BuildCoreForm] Calling CenterForm.");
        CenterForm(activeWindowRect);

        // Create the TabControl with styling
        CPHLogger.LogDebug("[BuildCoreForm] Creating new TabControl.");
        var tabControl = new TabControl();
        CPHLogger.LogDebug("[BuildCoreForm] Calling UIStyling.StyleTabControl.");
        UIStyling.StyleTabControl(tabControl);

        CPHLogger.LogDebug("[BuildCoreForm] Return TabControl");
        return tabControl;
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

    // Helper method to create a new tab page with common padding
    private TabPage CreateTabPage(string title)
    {
        CPHLogger.LogInfo($"[CreateTabPage][S] Creating new Tab Page for: {title}");
        return new TabPage(title) { Padding = new Padding(10) };
    }

    // General method to create a layout panel for any tab
    private TableLayoutPanel CreateLayoutPanel(int columnCount = 1, int rowCount = 6)
    {
        CPHLogger.LogInfo($"[TableLayoutPanel][S] Starting Base Tab Table Creation. Cols: {columnCount} Rows: {rowCount}");
        var panel = new TableLayoutPanel
        {
            Dock = DockStyle.Top,
            AutoSize = true,
            Padding = new Padding(2, 2, 2, 2),
            Margin = new Padding(2, 2, 2, 2),
            ColumnCount = columnCount,
            RowCount = rowCount,
            CellBorderStyle = TableLayoutPanelCellBorderStyle.Single,
        };

        CPHLogger.LogDebug("[TableLayoutPanel] Returning Table Panel");
        return panel;
    }

    // Adding specific controls to the "Startup" tab
    private void AddStartupTabControls(TabPage startupTab)
    {
        CPHLogger.LogDebug("[AddStartupTabControls][S] Starting AddStartupTabControls");
        var scrollablePanel = new Panel
        {
            Dock = DockStyle.Fill,
            AutoScroll = true,
            BackColor = Color.WhiteSmoke,
        };

        CPHLogger.LogDebug("[AddStartupTabControls] Calling Create Layout Panel.");
        var mainLayoutPanel = CreateLayoutPanel();

        // Add controls to the layout panel
        CPHLogger.LogVerbose("[AddStartupTabControls] Calling AddConfigurationControls.");
        AddConfigurationControls(mainLayoutPanel);
        CPHLogger.LogVerbose("[AddStartupTabControls] Calling AddApplicationControls.");
        AddApplicationControls(mainLayoutPanel);
        CPHLogger.LogVerbose("[AddStartupTabControls] Calling AddSeparateActionGroups.");
        AddSeparateActionGroups(mainLayoutPanel);
        CPHLogger.LogVerbose("[AddStartupTabControls] Calling AddStartupConfigurationControls.");
        AddStartupConfigurationControls(mainLayoutPanel);
        CPHLogger.LogVerbose("[AddStartupTabControls] Calling AddApplicationControlButtons.");
        AddApplicationControlButtons(mainLayoutPanel);

        // Add the layout panel to the scrollable panel
        CPHLogger.LogDebug("[AddStartupTabControls] Adding Layout Panel to the Scrollable Panel.");
        scrollablePanel.Controls.Add(mainLayoutPanel);

        // Dynamically calculate the minimum size for the scrollable panel
        CPHLogger.LogDebug("[AddStartupTabControls] SetMinimumSizeBasedOnChildControls.");
        SetMinimumSizeBasedOnChildControls(mainLayoutPanel, scrollablePanel);

        // Add the scrollable panel to the tab
        CPHLogger.LogInfo($"[AddStartupTabControls] Adding the scrollable panel to the tab page. Size: {scrollablePanel.Size}");
        startupTab.Controls.Add(scrollablePanel);
    }

    private void SetMinimumSizeBasedOnChildControls(Control content, Panel container, int buffer = 10 )
    {
        CPHLogger.LogDebug("[SetMinimumSizeBasedOnChildControls][S] Starting SetMinimumSizeBasedOnChildControls");
        // Tracks the maximum width and height
        int maxWidth = 0;
        int maxHeight = 0;

        CPHLogger.LogDebug("[SetMinimumSizeBasedOnChildControls] Processing Controls.");
        // Method to recursively process all controls
        void ProcessControl(Control control)
        {
            CPHLogger.LogInfo($"[ProcessControl] Control Details: {control.ToString()}");
            // Calculate right and bottom edges for the control
            int controlRight = control.Right + control.Margin.Right;
            int controlBottom = control.Bottom + control.Margin.Bottom;
            CPHLogger.LogInfo($"[ProcessControl] Control Details. Right Control: {control.Right} Right Margin: {control.Margin.Right} Right Total: {controlRight}");
            CPHLogger.LogInfo($"[ProcessControl] Control Details. Bottom Control: {control.Bottom} Bottom Margin: {control.Margin.Bottom} Bottom Total: {controlBottom}");

            // Update the maximum dimensions
            maxWidth = Math.Max(maxWidth, controlRight);
            maxHeight = Math.Max(maxHeight, controlBottom);
            CPHLogger.LogInfo($"[ProcessControl] Max Dimensions. Width: {maxWidth} Height: {maxHeight}.");

            // Recursively process nested controls
            foreach (Control child in control.Controls)
            {
                CPHLogger.LogInfo($"[ProcessControl] Nested Child Processing. {child.ToString()}.");                                
                ProcessControl(child);
            }            
        }

        // Process each child control recursively
        foreach (Control child in content.Controls)
        {
            CPHLogger.LogInfo($"[ProcessControl] Unnested Child Processing. {child.ToString()}.");                                
            ProcessControl(child);
        }

        // Apply the buffer to the calculated size
        maxWidth += buffer;
        maxHeight += buffer;

		CPHLogger.LogInfo($"Max Height: {maxWidth}.");
        CPHLogger.LogInfo($"Max Height: {maxHeight}.");

        // Apply the calculated size
        CPHLogger.LogDebug($"Update content sizes: {maxHeight}.");
        content.MinimumSize = new Size(maxWidth, maxHeight);
        container.MinimumSize = new Size(maxWidth, maxHeight);
        container.AutoScrollMinSize = new Size(maxWidth, maxHeight);       

    }


    /* STARTUP TAB
    **
    **
    **
    **
    */
    private void AddConfigurationControls(TableLayoutPanel mainLayoutPanel)
    {
        // Create the group box.
        GroupBox configurationGroupBox = new GroupBox();
        UIStyling.StyleGroupBox(configurationGroupBox, "Manage your configuration");

        // Create the table for the configuration buttons.
        TableLayoutPanel buttonTable = new TableLayoutPanel();
        var numberOfCols = 5;

        var rowStyling = new List<RowStyle> { new RowStyle(SizeType.AutoSize) };
        var columnStyling = new List<ColumnStyle>();
        for (int i = 0; i < numberOfCols; i++)
        {
            buttonTable.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, (100 / numberOfCols)));
        }

        UIStyling.StyleTableLayoutPanel(
            buttonTable,
            columnCount: numberOfCols,
            rowCount: 1,
            customRowStyles: rowStyling,
            customColumnStyles: columnStyling,
            autoSizeTable: true
        );

        // Add buttons to the TableLayoutPanel
        buttonTable.Controls.Add(btnResetAllSettings, 0, 0);
        btnResetAllSettings.Anchor = AnchorStyles.None;
        btnResetAllSettings.Dock = DockStyle.None;

        buttonTable.Controls.Add(btnImportSettings, 1, 0);
        btnImportSettings.Anchor = AnchorStyles.None;
        btnImportSettings.Dock = DockStyle.None;

        buttonTable.Controls.Add(btnExportSettings, 2, 0);
        btnExportSettings.Anchor = AnchorStyles.None;
        btnExportSettings.Dock = DockStyle.None;

        buttonTable.Controls.Add(btnShowAbout, 3, 0);
        btnShowAbout.Anchor = AnchorStyles.None;
        btnShowAbout.Dock = DockStyle.None;

        buttonTable.Controls.Add(btnTestConfig, 4, 0);
        btnTestConfig.Anchor = AnchorStyles.None;
        btnTestConfig.Dock = DockStyle.None;

        // Add click event handlers for the buttons
        btnResetAllSettings.Click += MainCanvasCloseButton_Click;
        btnImportSettings.Click += MainCanvasCloseButton_Click;
        btnExportSettings.Click += MainCanvasCloseButton_Click;
        btnShowAbout.Click += MainCanvasCloseButton_Click;
        btnTestConfig.Click += MainCanvasCloseButton_Click;

        // Add the TableLayoutPanel to the GroupBox
        configurationGroupBox.Controls.Add(buttonTable);

        // Add the GroupBox to the main layout
        mainLayoutPanel.Controls.Add(configurationGroupBox);
    }

    // Flow control. Save and exit buttons.
    //ToDo: Centralise buttons to the bottom.
    private void AddApplicationControlButtons(TableLayoutPanel mainLayoutPanel)
    {
        FlowLayoutPanel buttonPanel = new FlowLayoutPanel();
        UIStyling.StyleFlowBox(buttonPanel, FlowDirection.LeftToRight, autoWrap: true);

        // Center-align the content within the FlowLayoutPanel
        buttonPanel.Anchor = AnchorStyles.None;
        buttonPanel.WrapContents = false;
        //buttonPanel.HorizontalAlign = ContentAlignment.MiddleCenter;

        // Add the "Save" and "Cancel" buttons to the FlowLayoutPanel with padding for spacing
        btnSaveForm.Margin = new Padding(10);
        btnCloseForm.Margin = new Padding(10);

        // Add buttons to the FlowLayoutPanel
        buttonPanel.Controls.Add(btnSaveForm);
        buttonPanel.Controls.Add(btnCloseForm);

        // Attach click event handlers
        btnSaveForm.Click += MainCanvasSaveButton_Click;
        btnCloseForm.Click += MainCanvasCloseButton_Click;

        // Add the button panel to the main layout panel
        mainLayoutPanel.Controls.Add(buttonPanel);
        mainLayoutPanel.SetCellPosition(
            buttonPanel,
            new TableLayoutPanelCellPosition(0, mainLayoutPanel.RowCount - 1)
        );
    }

    private void AddApplicationControls(TableLayoutPanel mainLayoutPanel)
    {
        // Create the Applications group box.
        GroupBox applicationsToStartGroupBox = new GroupBox();
        UIStyling.StyleGroupBox(applicationsToStartGroupBox, "Applications to run on bot startup");

        // Create the application table.
        TableLayoutPanel tpanelApplications = new TableLayoutPanel();

        var rowStyling = new List<RowStyle>
        {
            new RowStyle(SizeType.Percent, 100),
            new RowStyle(SizeType.AutoSize),
        };

        var columnStyling = new List<ColumnStyle>
        {
            new ColumnStyle(SizeType.Percent, 100),
            new ColumnStyle(SizeType.AutoSize),
        };

        UIStyling.StyleTableLayoutPanel(
            tpanelApplications,
            columnCount: 2,
            rowCount: 2,
            customRowStyles: rowStyling,
            customColumnStyles: columnStyling,
            autoSizeTable: true
        );

        // Add list box
        tpanelApplications.Controls.Add(lstApplications, 0, 0);

        // Create panel for Add/Remove buttons
        FlowLayoutPanel buttonPanel = new FlowLayoutPanel();
        UIStyling.StyleFlowBox(
            buttonPanel,
            FlowDirection.TopDown,
            autoWrap: true,
            anchorStyle: AnchorStyles.Top
        );

        buttonPanel.Controls.Add(btnAddApplication);
        buttonPanel.Controls.Add(btnRemoveApplication);
        buttonPanel.Controls.Add(btnAddApplicationPath);

        // Add button panel
        tpanelApplications.Controls.Add(buttonPanel, 1, 0);

        // Add arrow buttons
        FlowLayoutPanel fpanelApplicationArrows = new FlowLayoutPanel();
        UIStyling.StyleFlowBox(
            fpanelApplicationArrows,
            FlowDirection.LeftToRight,
            autoWrap: true,
            customPadding: new Padding(1, 1, 5, 1),
            anchorStyle: AnchorStyles.Right
        );

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

        mainLayoutPanel.Controls.Add(applicationsToStartGroupBox);
    }

    private void AddSeparateActionGroups(TableLayoutPanel mainLayoutPanel)
    {
        // Create a GroupBox for "Allowed Actions"
        GroupBox allowedActionsGroupBox = CreateActionsGroupBox(
            "Allowed Actions",
            lstActionsPermitted,
            btnAddActionPermitted,
            btnRemoveActionPermitted,
            AddActionPermitted_SelIndhanged,
            AddActionPermitted_Click,
            RemoveActionPermitted_Click
        );

        // Create a GroupBox for "Blocked Actions"
        GroupBox blockedActionsGroupBox = CreateActionsGroupBox(
            "Blocked Actions",
            lstActionsBlocked,
            btnAddActionBlocked,
            btnRemoveActionBlocked,
            AddActionBlocked_SelIndhanged,
            AddActionBlocked_Click,
            RemoveActionBlocked_Click
        );

        // Add both GroupBoxes to the main layout
        mainLayoutPanel.Controls.Add(allowedActionsGroupBox);
        mainLayoutPanel.Controls.Add(blockedActionsGroupBox);
    }

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
        GroupBox actionsGroupBox = new GroupBox();
        UIStyling.StyleGroupBox(actionsGroupBox, title);

        TableLayoutPanel actionsPanel = new TableLayoutPanel();

        var rowStyling = new List<RowStyle> { new RowStyle(SizeType.AutoSize) };
        var columnStyling = new List<ColumnStyle>
        {
            new ColumnStyle(SizeType.Percent, 100),
            new ColumnStyle(SizeType.AutoSize),
        };

        UIStyling.StyleTableLayoutPanel(
            actionsPanel,
            columnCount: 2,
            rowCount: 1,
            customRowStyles: rowStyling,
            customColumnStyles: columnStyling,
            autoSizeTable: true
        );

        // Add ListBox to the panel
        actionsPanel.Controls.Add(listBox, 0, 0);

        FlowLayoutPanel buttonPanel = new FlowLayoutPanel();
        UIStyling.StyleFlowBox(
            buttonPanel,
            FlowDirection.LeftToRight,
            autoWrap: true,
            anchorStyle: AnchorStyles.Top
        );

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

    protected override void OnLoad(EventArgs e)
    {
        base.OnLoad(e);
        FormResizer.ResizeFormToFitContent(this);
    }

    private void AddStartupConfigurationControls(TableLayoutPanel mainLayoutPanel)
    {
        GroupBox startupOptionsGroup = new GroupBox();
        UIStyling.StyleGroupBox(startupOptionsGroup, "Load Applications on Startup", 60);

        TableLayoutPanel startupOptionsPanel = new TableLayoutPanel();
        var rowStyling = new List<RowStyle> { new RowStyle(SizeType.AutoSize) };
        var columnStyling = new List<ColumnStyle>
        {
            new ColumnStyle(SizeType.Absolute, 55),
            new ColumnStyle(SizeType.Absolute, 55),
            new ColumnStyle(SizeType.Absolute, 70),
            new ColumnStyle(SizeType.Percent, 100),
            new ColumnStyle(SizeType.Absolute, 140),
            new ColumnStyle(SizeType.Absolute, 50),
        };

        UIStyling.StyleTableLayoutPanel(
            startupOptionsPanel,
            columnCount: 6,
            rowCount: 1,
            customRowStyles: rowStyling,
            customColumnStyles: columnStyling,
            autoSizeTable: true
        );

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
        mainLayoutPanel.Controls.Add(startupOptionsGroup);
    }

    private void AddApplication_Click(object sender, EventArgs e)
    {
        // Run the file dialog in a separate STA thread
        Thread fileDialogThread = new Thread(() =>
        {
            try
            {
                using (OpenFileDialog fileDialog = new OpenFileDialog())
                {
                    fileDialog.Filter = "Executable Files (*.exe)|*.exe|All Files (*.*)|*.*";
                    fileDialog.Title = "Select an Application File";

                    if (fileDialog.ShowDialog(this) == DialogResult.OK)
                    {
                        // Create an instance of ApplicationFileDetails to hold file name and path
                        // When adding a new application file
                        ApplicationFileDetails selectedFile = new ApplicationFileDetails(
                            fileDialog.FileName,
                            lstApplications.Items.Count
                        );

                        // Update the UI on the main thread using Invoke
                        this.Invoke(
                            new Action(() =>
                            {
                                // Check if the file (by full path) is already in the list
                                if (
                                    !lstApplications
                                        .Items.Cast<ApplicationFileDetails>()
                                        .Any(f => f.FullPath == selectedFile.FullPath)
                                )
                                {
                                    lstApplications.Items.Add(selectedFile);
                                    btnSaveForm.Enabled = true;
                                }
                                else
                                {
                                    MessageBox.Show(
                                        "This application file has already been added."
                                    );
                                }
                            })
                        );
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"An error occurred while selecting the file:\n{ex.Message}");
            }
        });

        // Set the apartment state to STA for compatibility with file dialogs
        fileDialogThread.SetApartmentState(ApartmentState.STA);
        fileDialogThread.Start();
    }

    private void AddApplicationPath_Click(object sender, EventArgs e)
    {
        using (PathInputDialog pathDialog = new PathInputDialog(this))
        {
            if (pathDialog.ShowDialog(this) == DialogResult.OK)
            {
                string pathToAdd = pathDialog.EnteredPath;

                if (!string.IsNullOrWhiteSpace(pathToAdd))
                {
                    if (File.Exists(pathToAdd) || Directory.Exists(pathToAdd))
                    {
                        if (!lstApplications.Items.Contains(pathToAdd))
                        {
                            ApplicationFileDetails selectedFile = new ApplicationFileDetails(
                                pathToAdd,
                                lstApplications.Items.Count
                            );

                            lstApplications.Items.Add(selectedFile);
                            btnSaveForm.Enabled = true;
                        }
                        else
                        {
                            MessageBox.Show("This application path has already been added.");
                        }
                    }
                    else
                    {
                        MessageBox.Show("The specified path does not exist.");
                    }
                }
                else
                {
                    MessageBox.Show("Please enter a valid application path.");
                }
            }
        }
    }

    private void RemoveApplication_Click(object sender, EventArgs e)
    {
        if (lstApplications.SelectedItem != null)
        {
            lstApplications.Items.Remove(lstApplications.SelectedItem);
            btnSaveForm.Enabled = true;
        }
    }

    private void ApplicationListBox_SelectedIndexChanged(object sender, EventArgs e)
    {
        btnRemoveApplication.Enabled = lstApplications.SelectedItem != null;
    }

    private void AddActionPermitted_SelIndhanged(object sender, EventArgs e)
    {
        btnRemoveActionPermitted.Enabled = lstActionsPermitted.SelectedItem != null;
    }

    private void AddActionPermitted_Click(object sender, EventArgs e)
    {
        using (ActionManagerForm actionManagerDialog = new ActionManagerForm(actionDataList))
        {
            if (actionManagerDialog.ShowDialog(this) == DialogResult.OK)
            {
                // Access the list of selected actions
                List<string> selectedActions = actionManagerDialog.SelectedActions;

                foreach (string action in selectedActions)
                {
                    lstActionsPermitted.Items.Add(action);
                }
                btnSaveForm.Enabled = true;
            }
        }
    }

    private void RemoveActionPermitted_Click(object sender, EventArgs e)
    {
        if (lstActionsPermitted.SelectedItem != null)
        {
            lstActionsPermitted.Items.Remove(lstActionsPermitted.SelectedItem);
            btnSaveForm.Enabled = true;
        }
    }

    private void AddActionBlocked_SelIndhanged(object sender, EventArgs e)
    {
        btnRemoveActionBlocked.Enabled = lstActionsBlocked.SelectedItem != null;
    }

    private void AddActionBlocked_Click(object sender, EventArgs e)
    {
        using (ActionManagerForm actionManagerDialog = new ActionManagerForm(actionDataList))
        {
            if (actionManagerDialog.ShowDialog(this) == DialogResult.OK)
            {
                // Access the list of selected actions
                List<string> selectedActions = actionManagerDialog.SelectedActions;

                foreach (string action in selectedActions)
                {
                    lstActionsBlocked.Items.Add(action);
                }
                btnSaveForm.Enabled = true;
            }
        }
    }

    private void RemoveActionBlocked_Click(object sender, EventArgs e)
    {
        if (lstActionsBlocked.SelectedItem != null)
        {
            lstActionsBlocked.Items.Remove(lstActionsBlocked.SelectedItem);
            btnSaveForm.Enabled = true;
        }
    }

    private void ResetConfig_Click(object sender, EventArgs e)
    {
        DialogResult result = MessageBox.Show(
            "Are you sure you want to reset the configuration?",
            "Confirm Reset",
            MessageBoxButtons.YesNo,
            MessageBoxIcon.Warning
        );

        if (result == DialogResult.Yes)
        {
            lstApplications.Items.Clear();
            lstActionsPermitted.Items.Clear();
            lstActionsBlocked.Items.Clear();

            radioStartupConfigYes.Checked = false;
            radioStartupConfigNo.Checked = false;
            radioStartupConfigPrompt.Checked = true;

            btnSaveForm.Enabled = false;
            btnRemoveApplication.Enabled = false;
            btnRemoveActionPermitted.Enabled = false;
            btnRemoveActionBlocked.Enabled = false;
            numupdwnStartupConfigDelay.Value = 2;
        }
    }

    private void EnableListBoxOrdering(ListBox listBox)
    {
        listBox.MouseDown += ListBox_MouseDown;
        listBox.MouseMove += ListBox_MouseMove;
        listBox.DragOver += ListBox_DragOver;
        listBox.DragDrop += ListBox_DragDrop;
        listBox.AllowDrop = true;
    }

    // Start dragging the item if the mouse is pressed down
    private void ListBox_MouseDown(object sender, MouseEventArgs mouseEventArgs)
    {
        ListBox listBox = (ListBox)sender;
        indexOfListItem = listBox.IndexFromPoint(mouseEventArgs.X, mouseEventArgs.Y);
    }

    // Handle moving the item if the mouse is dragged
    private void ListBox_MouseMove(object sender, MouseEventArgs mouseEventArgs)
    {
        ListBox listBox = (ListBox)sender;

        // Start dragging if the left button is held down
        if (mouseEventArgs.Button == MouseButtons.Left && indexOfListItem >= 0)
        {
            listBox.DoDragDrop(listBox.Items[indexOfListItem], DragDropEffects.Move);
        }
    }

    private void ListBox_DragOver(object sender, DragEventArgs dragEventArgs)
    {
        dragEventArgs.Effect = DragDropEffects.Move;
    }

    private void btnApplicationsUp_Click(object sender, EventArgs clickEventArgs)
    {
        ListBox listBox = lstApplications;

        if (listBox.SelectedIndex > 0)
        {
            int selectedIndex = listBox.SelectedIndex;
            var item = (ApplicationFileDetails)listBox.Items[selectedIndex];

            // Swap the item with the one above it in the ListBox
            listBox.Items.RemoveAt(selectedIndex);
            listBox.Items.Insert(selectedIndex - 1, item);
            listBox.SelectedIndex = selectedIndex - 1;

            // Update the Index property for both items involved in the swap
            item.Index = selectedIndex - 1;
            if (listBox.Items[selectedIndex] is ApplicationFileDetails itemAbove)
            {
                itemAbove.Index = selectedIndex;
            }
        }
    }

    private void btnApplicationsDown_Click(object sender, EventArgs clickEventArgs)
    {
        ListBox listBox = lstApplications;

        if (listBox.SelectedIndex < listBox.Items.Count - 1 && listBox.SelectedIndex != -1)
        {
            int selectedIndex = listBox.SelectedIndex;
            var item = (ApplicationFileDetails)listBox.Items[selectedIndex];

            // Swap the item with the one below it in the ListBox
            listBox.Items.RemoveAt(selectedIndex);
            listBox.Items.Insert(selectedIndex + 1, item);
            listBox.SelectedIndex = selectedIndex + 1;

            // Update the Index property for both items involved in the swap
            item.Index = selectedIndex + 1;
            if (listBox.Items[selectedIndex] is ApplicationFileDetails itemBelow)
            {
                itemBelow.Index = selectedIndex;
            }
        }
    }

    // Reorder the item when dropped in a new position
    private void ListBox_DragDrop(object sender, DragEventArgs dragEventArgs)
    {
        ListBox listBox = (ListBox)sender;

        // Get the index of the drop target
        int indexOfItemUnderMouseToDrop = listBox.IndexFromPoint(
            listBox.PointToClient(new Point(dragEventArgs.X, dragEventArgs.Y))
        );

        // Move the dragged item to the drop position if it's valid and different
        if (
            indexOfItemUnderMouseToDrop != ListBox.NoMatches
            && indexOfItemUnderMouseToDrop != indexOfListItem
        )
        {
            object draggedItem = listBox.Items[indexOfListItem];
            listBox.Items.RemoveAt(indexOfListItem);
            listBox.Items.Insert(indexOfItemUnderMouseToDrop, draggedItem);

            // Update selection to indicate new position
            listBox.SetSelected(indexOfItemUnderMouseToDrop, true);
        }
    }

    private void MainCanvasSaveButton_Click(object sender, EventArgs e)
    {
        SaveCurrentSettings();
        MessageBox.Show("Configuration saved!");
        btnSaveForm.Enabled = false;
    }

    private void MainCanvasCloseButton_Click(object sender, EventArgs e)
    {
        this.Close();
    }

    private StartupManagerSettings GetCurrentSettingsFromUI()
    {
        var settings = new StartupManagerSettings
        {
            // Load the current values for LoadOnStartupConfig
            LoadOnStartup = new LoadOnStartupConfig
            {
                Enabled = true, // Or bind this to a CheckBox or similar control
                Mode = GetStartupMode(), // Get selected mode from RadioButtons or ComboBox
                DelayInSeconds = (int)
                    numupdwnStartupConfigDelay.Value // Get delay from NumericUpDown control
                ,
            },

            // Populate Applications list from ListBox items
            Applications = lstApplications
                .Items.Cast<ApplicationFileDetails>()
                .Select(
                    (app, index) =>
                        new ApplicationConfig
                        {
                            Path = app.FullPath,
                            IsEnabled = true, // Or bind this to another control if needed
                            Order =
                                index // Use the list index as the order
                            ,
                        }
                )
                .ToList(),

            // Populate Actions from permitted and blocked actions ListBoxes
            Actions = new ActionConfigs
            {
                Permitted = lstActionsPermitted
                    .Items.Cast<ActionConfig>()
                    .Select(
                        (action, index) =>
                            new ActionConfig
                            {
                                Name = action.Name,
                                IsEnabled = action.IsEnabled,
                                Order = index,
                            }
                    )
                    .ToList(),

                Blocked = lstActionsBlocked
                    .Items.Cast<ActionConfig>()
                    .Select(
                        (action, index) =>
                            new ActionConfig
                            {
                                Name = action.Name,
                                IsEnabled = action.IsEnabled,
                                Order = index,
                            }
                    )
                    .ToList(),
            },

            // Populate UserSettings
            UserSettings = new UserSettingsConfig
            {
                ResetConfig = false, // Or bind to a control like a CheckBox
                ExportSettings = new ExportImportConfig { Path = "default_export_path" },
                ImportSettings = new ExportImportConfig { Path = "default_import_path" },
                LastSaveTime = DateTime.Now,
            },
        };

        return settings;
    }

    // Helper function to get the selected startup mode
    private string GetStartupMode()
    {
        if (radioStartupConfigYes.Checked)
            return "Yes";
        else if (radioStartupConfigNo.Checked)
            return "No";
        else if (radioStartupConfigPrompt.Checked)
            return "Prompt";

        return "No"; // Default if none are selected
    }

    public void SaveCurrentSettings()
    {
        // Define the path to the "data" directory within the current application directory
        string dataDir = Constants.DataDir;

        // Ensure the "data" directory exists
        if (!Directory.Exists(dataDir))
        {
            Directory.CreateDirectory(dataDir);
        }

        // Define the full path to the settings file within the "data" directory
        string filePath = Path.Combine(dataDir, Constants.SettingsFileName);

        // Retrieve current settings from the UI and save them
        var settings = GetCurrentSettingsFromUI();
        UserSettingsControl.SaveStartupManagerSettings(settings, filePath);
    }
}

public class PathInputDialog : Form
{
    private TextBox pathTextBox;
    private Button btnPidOkay;
    private Button btnPidCancel;
    public string EnteredPath => pathTextBox.Text;
    private const string PlaceholderText = "Enter or paste the application path here";

    public PathInputDialog(Form ownerForm)
    {
        Text = "Enter Application Path";
        Width = 400;
        Height = 150;

        StartPosition = FormStartPosition.Manual;
        Location = new Point(
            ownerForm.Left + (ownerForm.Width - Width) / 2,
            ownerForm.Top + (ownerForm.Height - Height) / 2
        );

        Label promptLabel = new Label
        {
            Text = "Enter the path of the application:",
            Left = 10,
            Top = 10,
            Width = 360,
        };

        pathTextBox = new TextBox
        {
            Left = 10,
            Top = 40,
            Width = 360,
            ForeColor = Color.Gray,
            Text = PlaceholderText,
        };

        // Set up placeholder events
        pathTextBox.GotFocus += RemovePlaceholder;
        pathTextBox.LostFocus += SetPlaceholder;

        btnPidOkay = new Button
        {
            Text = "OK",
            Left = 220,
            Width = 75,
            Top = 70,
            DialogResult = DialogResult.OK,
        };
        btnPidCancel = new Button
        {
            Text = "Cancel",
            Left = 300,
            Width = 75,
            Top = 70,
            DialogResult = DialogResult.Cancel,
        };

        btnPidOkay.Click += (sender, e) =>
        {
            DialogResult = DialogResult.OK;
            Close();
        };

        btnPidCancel.Click += (sender, e) =>
        {
            DialogResult = DialogResult.Cancel;
            Close();
        };

        Controls.Add(promptLabel);
        Controls.Add(pathTextBox);
        Controls.Add(btnPidOkay);
        Controls.Add(btnPidCancel);
    }

    private void RemovePlaceholder(object sender, EventArgs e)
    {
        if (pathTextBox.Text == PlaceholderText)
        {
            pathTextBox.Text = "";
            pathTextBox.ForeColor = Color.Black;
        }
    }

    private void SetPlaceholder(object sender, EventArgs e)
    {
        if (string.IsNullOrWhiteSpace(pathTextBox.Text))
        {
            pathTextBox.Text = PlaceholderText;
            pathTextBox.ForeColor = Color.Gray;
        }
    }
}

public class ActionManagerForm : Form
{
    private ListView lstAMFListView = new ListView
    {
        Left = 20,
        Top = 20,
        Width = 400,
        Height = 300,
        View = View.Details,
        FullRowSelect = true,
        GridLines = true,
        MultiSelect =
            true // Allow multiple selections
        ,
    };

    private Button btnAMFAddItems = new Button
    {
        Left = 430,
        Top = 20,
        Width = 120,
        Text = "Add Selected",
    };
    private Button btnAMFCancelButton = new Button
    {
        Left = 430,
        Top = 60,
        Width = 120,
        Text = "Cancel",
    };
    private List<ActionData> actionDataList;

    public List<string> SelectedActions { get; private set; } = new List<string>();

    public ActionManagerForm(List<ActionData> actionData)
    {
        this.Text = "Actions To Manage";
        this.Width = 600;
        this.Height = 400;
        this.Controls.Add(lstAMFListView);
        this.Controls.Add(btnAMFAddItems);
        this.Controls.Add(btnAMFCancelButton);

        // Initialize actionDataList with the passed-in actionData
        actionDataList = actionData;

        // Set up columns for Action Name and Action Status
        lstAMFListView.Columns.Add("Action Name", 250, HorizontalAlignment.Left);
        lstAMFListView.Columns.Add("Action Status", 100, HorizontalAlignment.Left);

        // Load actions into the ListView
        LoadActions();

        // Event handlers
        btnAMFAddItems.Click += AddActionsToListButton_Click;
        btnAMFCancelButton.Click += CancelButton_Click;
    }

    private void LoadActions()
    {
        // Clear the list view and populate it with actions
        lstAMFListView.Items.Clear();

        foreach (var action in actionDataList)
        {
            // Create a ListViewItem with the action name and status as sub-items
            ListViewItem actionItem = new ListViewItem(action.Name);
            actionItem.SubItems.Add(action.Enabled ? "Enabled" : "Disabled");
            lstAMFListView.Items.Add(actionItem);
        }
    }

    private void AddActionsToListButton_Click(object sender, EventArgs e)
    {
        // Ensure at least one action is selected
        if (lstAMFListView.SelectedItems.Count > 0)
        {
            // Retrieve the names of all selected actions
            SelectedActions = lstAMFListView
                .SelectedItems.Cast<ListViewItem>()
                .Select(item => item.Text)
                .ToList();

            // Close the form and set DialogResult to OK
            DialogResult = DialogResult.OK;
            Close();
        }
        else
        {
            MessageBox.Show(
                "Please select one or more actions to add.",
                "Selection Required",
                MessageBoxButtons.OK,
                MessageBoxIcon.Warning
            );
        }
    }

    private void CancelButton_Click(object sender, EventArgs e)
    {
        // Close the form without selecting actions
        Close();
    }

    // Optional helper methods for enabling/disabling actions
    private void EnableAction(string actionName)
    {
        var action = actionDataList.FirstOrDefault(a => a.Name == actionName);
        if (action != null)
            action.Enabled = true;
    }

    private void DisableAction(string actionName)
    {
        var action = actionDataList.FirstOrDefault(a => a.Name == actionName);
        if (action != null)
            action.Enabled = false;
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

public static class UserSettingsControl
{
    public static void SaveStartupManagerSettings(StartupManagerSettings settings, string filePath)
    {
        try
        {
            // Serialize the settings object to JSON format
            string json = JsonSerializer.Serialize(
                settings,
                new JsonSerializerOptions { WriteIndented = true }
            );

            // Write the JSON to the specified file path
            File.WriteAllText(filePath, json);

            Console.WriteLine("Settings saved successfully.");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"An error occurred while saving settings: {ex.Message}");
        }
    }
}

public static class UIStyling
{
    public static void StyleRadioButton(RadioButton radioButton, string prompt)
    {
        radioButton.Text = prompt;
        radioButton.AutoSize = true;
        radioButton.Dock = DockStyle.Fill;
        radioButton.TextAlign = ContentAlignment.MiddleLeft;
    }

    // Style for primary/main buttons
    public static void StyleMainButton(Button button)
    {
        button.Font = new Font("Microsoft Sans Serif", 8.5f);
        button.Width = 90;
        button.Height = 24;
        button.Margin = new Padding(0, 0, 0, 0);
        button.Padding = new Padding(3, 3, 3, 3);
        button.BackColor = Color.White; // Distinct button color
        button.ForeColor = SystemColors.ControlText; // Text color for contrast
        button.FlatAppearance.BorderSize = 1; // Add a subtle border
        button.FlatAppearance.BorderColor = Color.DarkGray; // Border color

        AttachHoverEffects(button);
    }

    // Style for secondary buttons (less prominent)
    public static void StyleLongerButton(Button button)
    {
        button.Font = new Font("Microsoft Sans Serif", 8.5f);
        button.Width = 120;
        button.Height = 24;
        button.Margin = new Padding(1, 3, 1, 1);
        button.Padding = new Padding(2, 2, 2, 2);
        button.BackColor = Color.White; // Distinct button color
        button.ForeColor = SystemColors.ControlText; // Text color for contrast
        button.FlatAppearance.BorderSize = 1; // Add a subtle border
        button.FlatAppearance.BorderColor = Color.DarkGray; // Border color

        AttachHoverEffects(button);
    }

    // Style for arrow buttons (up/down buttons)
    public static void StyleArrowButton(Button button)
    {
        button.Width = 20;
        button.Height = 20;
        button.Margin = new Padding(1, 0, 1, 0);
        button.Padding = new Padding(0, 0, 0, 0);
    }

    // Style for list boxes
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
    }

    public static void StyleFlowBox(
        FlowLayoutPanel flowBox,
        FlowDirection direction = FlowDirection.TopDown,
        bool autoWrap = false,
        Padding? customPadding = null, // Allow optional padding
        AnchorStyles anchorStyle =
            AnchorStyles.Top | AnchorStyles.Left | AnchorStyles.Right | AnchorStyles.Bottom // Default anchor
    )
    {
        flowBox.FlowDirection = direction; // Set the flow direction
        flowBox.WrapContents = autoWrap; // Enable or disable wrapping
        flowBox.Anchor = anchorStyle; // Apply anchor styles
        flowBox.AutoSize = true; // Automatically resize based on contents
        flowBox.AutoSizeMode = AutoSizeMode.GrowAndShrink; // Allow resizing as content grows or shrinks
        flowBox.Padding = new Padding(0); // Default margin

        // Use custom padding if provided, otherwise default to no padding
        flowBox.Margin = customPadding ?? new Padding(0);

        flowBox.BackColor = Color.WhiteSmoke; // Set the background color
        flowBox.BorderStyle = BorderStyle.FixedSingle; // Add a subtle border for visual clarity
    }

    private static void AttachHoverEffects(Button button)
    {
        // Change to light blue on hover
        button.MouseEnter += (sender, e) =>
        {
            button.BackColor = ColorTranslator.FromHtml("#D6EBFF"); // Light blue hover color
        };

        // Revert to original color on leave
        button.MouseLeave += (sender, e) =>
        {
            button.BackColor = Color.White;
        };
    }

    public static void StyleTableLayoutPanel(
        TableLayoutPanel tableLayoutPanel,
        int columnCount,
        int rowCount,
        List<RowStyle> customRowStyles = null,
        List<ColumnStyle> customColumnStyles = null,
        bool autoSizeTable = false
    )
    {
        // Set common properties
        tableLayoutPanel.ColumnCount = columnCount;
        tableLayoutPanel.RowCount = rowCount;
        tableLayoutPanel.Dock = DockStyle.Fill;
        tableLayoutPanel.Padding = new Padding(0);
        tableLayoutPanel.Margin = new Padding(0);
        tableLayoutPanel.CellBorderStyle = TableLayoutPanelCellBorderStyle.Single;

        // Allow the table to auto-resize if requested
        tableLayoutPanel.AutoSize = autoSizeTable;

        // Apply row styles
        for (int i = 0; i < rowCount; i++)
        {
            tableLayoutPanel.RowStyles.Add(
                i < customRowStyles?.Count ? customRowStyles[i] : new RowStyle(SizeType.AutoSize)
            );
        }

        // Apply column styles
        for (int i = 0; i < columnCount; i++)
        {
            tableLayoutPanel.ColumnStyles.Add(
                i < customColumnStyles?.Count
                    ? customColumnStyles[i]
                    : new ColumnStyle(SizeType.Percent, 100f / columnCount)
            );
        }
    }

    public static void StyleGroupBox(GroupBox groupBox, string text = null, int? height = null)
    {
        groupBox.Font = new Font("Segoe UI", 10, FontStyle.Bold);
        groupBox.ForeColor = Color.DimGray;
        groupBox.BackColor = Color.WhiteSmoke;
        groupBox.Dock = DockStyle.Fill;
        groupBox.Padding = new Padding(2, 2, 2, 2);
        groupBox.Margin = new Padding(2, 2, 2, 2);

        // Adjust AutoSize based on height
        groupBox.AutoSize = !height.HasValue;
        if (height.HasValue)
            groupBox.Height = height.Value;

        // Set text if provided
        if (!string.IsNullOrEmpty(text))
            groupBox.Text = text;
    }

    public static void StyleTabControl(TabControl tabControl)
    {
        tabControl.Dock = DockStyle.Fill;
        tabControl.Font = new Font("Segoe UI", 10, FontStyle.Regular);
        tabControl.Padding = new Point(5, 5);
        tabControl.Appearance = TabAppearance.FlatButtons; // Set tabs to flat style
        tabControl.ItemSize = new Size(120, 20); // Custom size for each tab
        tabControl.DrawMode = TabDrawMode.OwnerDrawFixed; // Enable custom drawing
        tabControl.DrawItem += (s, e) => // Define custom drawing behavior
        {
            // Fill tab background with custom color
            e.Graphics.FillRectangle(new SolidBrush(Color.WhiteSmoke), e.Bounds);

            // Draw the tab text with custom color
            TextRenderer.DrawText(
                e.Graphics,
                tabControl.TabPages[e.Index].Text,
                e.Font,
                e.Bounds,
                Color.Black
            );
        };
    }
}


public static class FormResizer
{
    private static int totalControls = 0;
    private static int visibleControlsCount = 0;
    private static int invisibleControlsCount = 0;
    private static int maxNestingDepth = 0;

    public static void ResizeFormToFitContent(Form form)
    {
        CPHLogger.LogInfo($"[ResizeFormToFitContent] Initial Form Size: Width={form.Width}, Height={form.Height}");
        LogEnvironmentInfo();

        // Log the form's AutoSizeMode
        CPHLogger.LogInfo($"[ResizeFormToFitContent] Form AutoSizeMode: {form.AutoSizeMode}");

        int requiredHeight = CalculateDynamicHeight(form.Controls, out int requiredWidth);
        CPHLogger.LogInfo($"[ResizeFormToFitContent] Calculated Required Dimensions: Height={requiredHeight}, Width={requiredWidth}");

        // Adjust size based on requirements
        if (requiredHeight > form.Height || requiredWidth > form.Width)
        {
            form.Height = Math.Min(requiredHeight + 50, Screen.PrimaryScreen.WorkingArea.Height);
            form.Width = Math.Min(requiredWidth + 50, Screen.PrimaryScreen.WorkingArea.Width);
            CPHLogger.LogInfo($"[ResizeFormToFitContent] Resized Form Size: Width={form.Width}, Height={form.Height}");
        }
        else
        {
            CPHLogger.LogInfo("[ResizeFormToFitContent] Current size is sufficient. No adjustment needed.");
        }

        // Log final dimensions
        CPHLogger.LogInfo($"[ResizeFormToFitContent] Final Form Size: Width={form.Width}, Height={form.Height}");
        LogSummary();
    }

public static int CalculateDynamicHeight(Control.ControlCollection controls, out int totalWidth, int buffer = 10, int nestingLevel = 0)
{
    int totalHeight = 0;
    int maxWidth = 0;

    string indent = new string(' ', nestingLevel * 4);
    CPHLogger.LogInfo($"{indent}[CalculateDynamicHeight] Processing controls at Nesting Level {nestingLevel}");

    foreach (Control control in controls)
    {
        totalControls++;
        CPHLogger.LogInfo($"{indent}[Control] Name={control.Name ?? "Unnamed"}, Type={control.GetType().Name}, Text={control.Text ?? "N/A"}");
        CPHLogger.LogInfo($"{indent}    Location: X={control.Left}, Y={control.Top}, Size: Width={control.Width}, Height={control.Height}");
        CPHLogger.LogInfo($"{indent}    Margins: {control.Margin}, Padding: {control.Padding}");
        CPHLogger.LogInfo($"{indent}    Visibility: Visible={control.Visible}, Enabled={control.Enabled}, TabStop={control.TabStop}");
        CPHLogger.LogInfo($"{indent}    Anchor: {control.Anchor}, Dock: {control.Dock}");
        CPHLogger.LogInfo($"{indent}    AutoSize: {control.AutoSize}");

        // AutoSizeMode logging
        if (control is Form formControl)
        {
            CPHLogger.LogInfo($"{indent}    AutoSizeMode (Form): {formControl.AutoSizeMode}");
        }
        else if (control is TableLayoutPanel)
        {
            CPHLogger.LogInfo($"{indent}    AutoSizeMode (TableLayoutPanel): GrowAndShrink is implicitly supported");
        }
        else
        {
            CPHLogger.LogInfo($"{indent}    AutoSizeMode: Not Applicable");
        }

        // Check for overlapping controls
        foreach (Control otherControl in controls)
        {
            if (control != otherControl && control.Bounds.IntersectsWith(otherControl.Bounds))
            {
                CPHLogger.LogInfo($"{indent}    Overlap Detected: {control.Name} overlaps with {otherControl.Name}");
            }
        }

        // Check for event handlers
        var events = TypeDescriptor.GetEvents(control);
        foreach (EventDescriptor eventDescriptor in events)
        {
            var handlers = control.GetType().GetField("Event" + eventDescriptor.Name,
                BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.FlattenHierarchy);
            if (handlers?.GetValue(control) != null)
            {
                CPHLogger.LogInfo($"{indent}    Event: {eventDescriptor.Name} has attached handlers.");
            }
        }

        // Preferred size vs calculated size
        int controlHeight = control.PreferredSize.Height + control.Margin.Vertical;
        int controlWidth = control.PreferredSize.Width + control.Margin.Horizontal;
        CPHLogger.LogInfo($"{indent}    Preferred Size: Height={control.PreferredSize.Height}, Width={control.PreferredSize.Width}");
        CPHLogger.LogInfo($"{indent}    Calculated Size (with Margins): Height={controlHeight}, Width={controlWidth}");

        // Update totals
        totalHeight += controlHeight;
        maxWidth = Math.Max(maxWidth, control.Right);

        // Recursive call for children
        if (control.HasChildren)
        {
            CPHLogger.LogInfo($"{indent}    Processing child controls of {control.Name}...");
            int childTotalWidth;
            totalHeight += CalculateDynamicHeight(control.Controls, out childTotalWidth, buffer, nestingLevel + 1);
            maxWidth = Math.Max(maxWidth, childTotalWidth);
        }
    }

    totalHeight += buffer;
    maxWidth += buffer;
    maxNestingDepth = Math.Max(maxNestingDepth, nestingLevel);

    CPHLogger.LogInfo($"{indent}[CalculateDynamicHeight] Total Calculated Dimensions at Nesting Level {nestingLevel}: Height={totalHeight}, Width={maxWidth}");
    totalWidth = maxWidth;
    return totalHeight;
}

    

    private static void LogEnvironmentInfo()
    {
        CPHLogger.LogInfo($"[Environment] Screen Resolution: {Screen.PrimaryScreen.Bounds.Width}x{Screen.PrimaryScreen.Bounds.Height}");
        CPHLogger.LogInfo($"[Environment] Working Area: {Screen.PrimaryScreen.WorkingArea.Width}x{Screen.PrimaryScreen.WorkingArea.Height}");
        CPHLogger.LogInfo($"[Environment] DPI Scaling: {Graphics.FromHwnd(IntPtr.Zero).DpiX} DPI");
        CPHLogger.LogInfo($"[Environment] OS Version: {Environment.OSVersion}");
        CPHLogger.LogInfo($"[Environment] .NET Runtime Version: {Environment.Version}");
    }

    private static void LogSummary()
    {
        CPHLogger.LogInfo($"[Summary] Total Controls Processed: {totalControls}");
        CPHLogger.LogInfo($"[Summary] Visible Controls: {visibleControlsCount}, Invisible Controls: {invisibleControlsCount}");
        CPHLogger.LogInfo($"[Summary] Maximum Nesting Depth Reached: {maxNestingDepth}");
    }
}

Log
[2024-11-25 19:51:07.331 DBG] SBSAM Loaded.
[2024-11-25 19:51:07.331 DBG] [DEBUG] Centralised CPH, enabling centralised methods.
[2024-11-25 19:51:07.331 DBG] [DEBUG] Getting Window Details
[2024-11-25 19:51:07.331 INF] [INFO] activeWindowHandle is 133622.
[2024-11-25 19:51:07.331 INF] [INFO] windowTitle is .
[2024-11-25 19:51:07.334 DBG] [DEBUG] Starting main form thread.
[2024-11-25 19:51:07.335 DBG] [DEBUG] Enabling application visual styles.
[2024-11-25 19:51:07.335 DBG] [DEBUG] Populating list of actions.
[2024-11-25 19:51:07.338 DBG] [DEBUG] Loading a new form.
[2024-11-25 19:51:07.339 DBG] [DEBUG] Building base form structure.
[2024-11-25 19:51:07.339 DBG] [DEBUG] [BuildCoreForm][S] Setting Form Name
[2024-11-25 19:51:07.339 INF] [INFO] Form Name: SBZen Config Manager
[2024-11-25 19:51:07.339 DBG] [DEBUG] [BuildCoreForm] Setting Form base Size
[2024-11-25 19:51:07.339 INF] [INFO] Form Size. W:600 H:800
[2024-11-25 19:51:07.339 DBG] [DEBUG] [BuildCoreForm] Setting Auto Size Properties
[2024-11-25 19:51:07.339 DBG] [DEBUG] [BuildCoreForm] Setting a minimum size.
[2024-11-25 19:51:07.339 INF] [INFO] Form Size. W:600 H:600
[2024-11-25 19:51:07.339 DBG] [DEBUG] [BuildCoreForm] Setting base form styling.
[2024-11-25 19:51:07.339 DBG] [DEBUG] [BuildCoreForm] Calling CenterForm.
[2024-11-25 19:51:07.339 INF] [INFO] [CenterForm][S] Getting center coordinates. {X=1060,Y=-1122,Width=2248,Height=-212}
[2024-11-25 19:51:07.339 INF] [INFO] [CenterForm] Coordinates: X:1884 / Y:-1528
[2024-11-25 19:51:07.339 DBG] [DEBUG] [BuildCoreForm] Placing form location, and ordering
[2024-11-25 19:51:07.339 DBG] [DEBUG] [BuildCoreForm] Creating new TabControl.
[2024-11-25 19:51:07.339 DBG] [DEBUG] [BuildCoreForm] Calling UIStyling.StyleTabControl.
[2024-11-25 19:51:07.339 DBG] [DEBUG] [BuildCoreForm] Return TabControl
[2024-11-25 19:51:07.339 DBG] [DEBUG] Calling AddTabWithControls for the Streamer Bot Started tab
[2024-11-25 19:51:07.339 DBG] [DEBUG] Creating tab page: Startup
[2024-11-25 19:51:07.339 INF] [INFO] [CreateTabPage][S] Creating new Tab Page for: Startup
[2024-11-25 19:51:07.339 DBG] [DEBUG] Adding tab controls: Startup
[2024-11-25 19:51:07.339 DBG] [DEBUG] [AddStartupTabControls][S] Starting AddStartupTabControls
[2024-11-25 19:51:07.339 DBG] [DEBUG] [AddStartupTabControls] Calling Create Layout Panel.
[2024-11-25 19:51:07.339 INF] [INFO] [TableLayoutPanel][S] Starting Base Tab Table Creation. Cols: 1 Rows: 6
[2024-11-25 19:51:07.339 DBG] [DEBUG] [TableLayoutPanel] Returning Table Panel
[2024-11-25 19:51:07.341 DBG] [DEBUG] [AddStartupTabControls] Adding Layout Panel to the Scrollable Panel.
[2024-11-25 19:51:07.341 DBG] [DEBUG] [AddStartupTabControls] SetMinimumSizeBasedOnChildControls.
[2024-11-25 19:51:07.341 DBG] [DEBUG] [SetMinimumSizeBasedOnChildControls][S] Starting SetMinimumSizeBasedOnChildControls
[2024-11-25 19:51:07.341 DBG] [DEBUG] [SetMinimumSizeBasedOnChildControls] Processing Controls.
[2024-11-25 19:51:07.341 INF] [INFO] [ProcessControl] Unnested Child Processing. System.Windows.Forms.GroupBox, Text: Manage your configuration.
[2024-11-25 19:51:07.341 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.GroupBox, Text: Manage your configuration
[2024-11-25 19:51:07.341 INF] [INFO] [ProcessControl] Control Details. Right Control: 420 Right Margin: 2 Right Total: 422
[2024-11-25 19:51:07.341 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 58 Bottom Margin: 2 Bottom Total: 60
[2024-11-25 19:51:07.341 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 60.
[2024-11-25 19:51:07.341 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.TableLayoutPanel, BorderStyle: System.Windows.Forms.BorderStyle.None.
[2024-11-25 19:51:07.341 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.TableLayoutPanel, BorderStyle: System.Windows.Forms.BorderStyle.None
[2024-11-25 19:51:07.341 INF] [INFO] [ProcessControl] Control Details. Right Control: 413 Right Margin: 0 Right Total: 413
[2024-11-25 19:51:07.341 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 51 Bottom Margin: 0 Bottom Total: 51
[2024-11-25 19:51:07.341 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 60.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.Button, Text: Remove All.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.Button, Text: Remove All
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 79 Right Margin: 3 Right Total: 82
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 27 Bottom Margin: 3 Bottom Total: 30
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 60.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.Button, Text: Import.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.Button, Text: Import
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 161 Right Margin: 3 Right Total: 164
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 27 Bottom Margin: 3 Bottom Total: 30
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 60.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.Button, Text: Export.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.Button, Text: Export
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 243 Right Margin: 3 Right Total: 246
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 27 Bottom Margin: 3 Bottom Total: 30
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 60.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.Button, Text: About.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.Button, Text: About
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 325 Right Margin: 3 Right Total: 328
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 27 Bottom Margin: 3 Bottom Total: 30
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 60.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.Button, Text: Test.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.Button, Text: Test
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 407 Right Margin: 3 Right Total: 410
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 27 Bottom Margin: 3 Bottom Total: 30
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 60.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Unnested Child Processing. System.Windows.Forms.GroupBox, Text: Applications to run on bot startup.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.GroupBox, Text: Applications to run on bot startup
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 420 Right Margin: 2 Right Total: 422
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 252 Bottom Margin: 2 Bottom Total: 254
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 254.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.TableLayoutPanel, BorderStyle: System.Windows.Forms.BorderStyle.None.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.TableLayoutPanel, BorderStyle: System.Windows.Forms.BorderStyle.None
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 413 Right Margin: 0 Right Total: 413
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 187 Bottom Margin: 0 Bottom Total: 187
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 254.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.ListBox.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.ListBox
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 124 Right Margin: 3 Right Total: 127
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 100 Bottom Margin: 3 Bottom Total: 103
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 254.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.FlowLayoutPanel, BorderStyle: System.Windows.Forms.BorderStyle.FixedSingle.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.FlowLayoutPanel, BorderStyle: System.Windows.Forms.BorderStyle.FixedSingle
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 410 Right Margin: 0 Right Total: 410
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 90 Bottom Margin: 0 Bottom Total: 90
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 254.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.Button, Text: Add Application.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.Button, Text: Add Application
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 78 Right Margin: 3 Right Total: 81
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 26 Bottom Margin: 3 Bottom Total: 29
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 254.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.Button, Text: Remove Application.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.Button, Text: Remove Application
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 78 Right Margin: 3 Right Total: 81
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 55 Bottom Margin: 3 Bottom Total: 58
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 254.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.Button, Text: Add Path.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.Button, Text: Add Path
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 78 Right Margin: 3 Right Total: 81
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 84 Bottom Margin: 3 Bottom Total: 87
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 254.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.FlowLayoutPanel, BorderStyle: System.Windows.Forms.BorderStyle.FixedSingle.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.FlowLayoutPanel, BorderStyle: System.Windows.Forms.BorderStyle.FixedSingle
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 321 Right Margin: 5 Right Total: 326
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 165 Bottom Margin: 1 Bottom Total: 166
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 254.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.Button, Text: â–².
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.Button, Text: â–²
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 78 Right Margin: 3 Right Total: 81
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 26 Bottom Margin: 3 Bottom Total: 29
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 254.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.Button, Text: â–¼.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.Button, Text: â–¼
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 159 Right Margin: 3 Right Total: 162
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 26 Bottom Margin: 3 Bottom Total: 29
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 254.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Unnested Child Processing. System.Windows.Forms.GroupBox, Text: Allowed Actions.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.GroupBox, Text: Allowed Actions
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 420 Right Margin: 2 Right Total: 422
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 383 Bottom Margin: 2 Bottom Total: 385
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 385.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.TableLayoutPanel, BorderStyle: System.Windows.Forms.BorderStyle.None.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.TableLayoutPanel, BorderStyle: System.Windows.Forms.BorderStyle.None
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 413 Right Margin: 0 Right Total: 413
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 124 Bottom Margin: 0 Bottom Total: 124
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 385.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.ListBox.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.ListBox
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 124 Right Margin: 3 Right Total: 127
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 100 Bottom Margin: 3 Bottom Total: 103
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 385.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.FlowLayoutPanel, BorderStyle: System.Windows.Forms.BorderStyle.FixedSingle.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.FlowLayoutPanel, BorderStyle: System.Windows.Forms.BorderStyle.FixedSingle
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 410 Right Margin: 0 Right Total: 410
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 61 Bottom Margin: 0 Bottom Total: 61
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 385.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.Button, Text: Add Action.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.Button, Text: Add Action
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 78 Right Margin: 3 Right Total: 81
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 26 Bottom Margin: 3 Bottom Total: 29
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 385.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.Button, Text: Remove Action.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.Button, Text: Remove Action
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 78 Right Margin: 3 Right Total: 81
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 55 Bottom Margin: 3 Bottom Total: 58
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 385.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Unnested Child Processing. System.Windows.Forms.GroupBox, Text: Blocked Actions.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.GroupBox, Text: Blocked Actions
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 420 Right Margin: 2 Right Total: 422
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 514 Bottom Margin: 2 Bottom Total: 516
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 516.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.TableLayoutPanel, BorderStyle: System.Windows.Forms.BorderStyle.None.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.TableLayoutPanel, BorderStyle: System.Windows.Forms.BorderStyle.None
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 413 Right Margin: 0 Right Total: 413
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 124 Bottom Margin: 0 Bottom Total: 124
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 516.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.ListBox.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.ListBox
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 124 Right Margin: 3 Right Total: 127
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 100 Bottom Margin: 3 Bottom Total: 103
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 516.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.FlowLayoutPanel, BorderStyle: System.Windows.Forms.BorderStyle.FixedSingle.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.FlowLayoutPanel, BorderStyle: System.Windows.Forms.BorderStyle.FixedSingle
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 410 Right Margin: 0 Right Total: 410
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 61 Bottom Margin: 0 Bottom Total: 61
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 516.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.Button, Text: Add Action.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.Button, Text: Add Action
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 78 Right Margin: 3 Right Total: 81
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 26 Bottom Margin: 3 Bottom Total: 29
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 516.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.Button, Text: Remove Action.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.Button, Text: Remove Action
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 78 Right Margin: 3 Right Total: 81
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 55 Bottom Margin: 3 Bottom Total: 58
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 516.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Unnested Child Processing. System.Windows.Forms.GroupBox, Text: Load Applications on Startup.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.GroupBox, Text: Load Applications on Startup
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 420 Right Margin: 2 Right Total: 422
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 579 Bottom Margin: 2 Bottom Total: 581
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 581.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.TableLayoutPanel, BorderStyle: System.Windows.Forms.BorderStyle.None.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.TableLayoutPanel, BorderStyle: System.Windows.Forms.BorderStyle.None
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 413 Right Margin: 0 Right Total: 413
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 58 Bottom Margin: 0 Bottom Total: 58
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 581.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.RadioButton, Checked: False.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.RadioButton, Checked: False
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 53 Right Margin: 3 Right Total: 56
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 28 Bottom Margin: 3 Bottom Total: 31
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 581.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.RadioButton, Checked: False.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.RadioButton, Checked: False
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 109 Right Margin: 3 Right Total: 112
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 28 Bottom Margin: 3 Bottom Total: 31
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 581.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.RadioButton, Checked: False.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.RadioButton, Checked: False
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 180 Right Margin: 3 Right Total: 183
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 28 Bottom Margin: 3 Bottom Total: 31
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 581.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.Label, Text: Delay (In seconds).
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.Label, Text: Delay (In seconds)
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 356 Right Margin: 3 Right Total: 359
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 37 Bottom Margin: 0 Bottom Total: 37
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 581.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.NumericUpDown, Minimum = 0, Maximum = 30.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.NumericUpDown, Minimum = 0, Maximum = 30
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 402 Right Margin: 0 Right Total: 402
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 31 Bottom Margin: 0 Bottom Total: 31
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 581.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.UpDownBase+UpDownButtons.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.UpDownBase+UpDownButtons
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 39 Right Margin: 3 Right Total: 42
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 24 Bottom Margin: 3 Bottom Total: 27
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 581.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.UpDownBase+UpDownEdit, Text: 2.
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.UpDownBase+UpDownEdit, Text: 2
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Right Control: 22 Right Margin: 3 Right Total: 25
[2024-11-25 19:51:07.342 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 23 Bottom Margin: 3 Bottom Total: 26
[2024-11-25 19:51:07.343 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 581.
[2024-11-25 19:51:07.343 INF] [INFO] [ProcessControl] Unnested Child Processing. System.Windows.Forms.FlowLayoutPanel, BorderStyle: System.Windows.Forms.BorderStyle.FixedSingle.
[2024-11-25 19:51:07.343 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.FlowLayoutPanel, BorderStyle: System.Windows.Forms.BorderStyle.FixedSingle
[2024-11-25 19:51:07.343 INF] [INFO] [ProcessControl] Control Details. Right Control: 308 Right Margin: 0 Right Total: 308
[2024-11-25 19:51:07.343 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 627 Bottom Margin: 0 Bottom Total: 627
[2024-11-25 19:51:07.343 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 627.
[2024-11-25 19:51:07.343 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.Button, Text: Save.
[2024-11-25 19:51:07.343 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.Button, Text: Save
[2024-11-25 19:51:07.343 INF] [INFO] [ProcessControl] Control Details. Right Control: 85 Right Margin: 10 Right Total: 95
[2024-11-25 19:51:07.343 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 33 Bottom Margin: 10 Bottom Total: 43
[2024-11-25 19:51:07.343 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 627.
[2024-11-25 19:51:07.343 INF] [INFO] [ProcessControl] Nested Child Processing. System.Windows.Forms.Button, Text: Close.
[2024-11-25 19:51:07.343 INF] [INFO] [ProcessControl] Control Details: System.Windows.Forms.Button, Text: Close
[2024-11-25 19:51:07.343 INF] [INFO] [ProcessControl] Control Details. Right Control: 180 Right Margin: 10 Right Total: 190
[2024-11-25 19:51:07.343 INF] [INFO] [ProcessControl] Control Details. Bottom Control: 33 Bottom Margin: 10 Bottom Total: 43
[2024-11-25 19:51:07.343 INF] [INFO] [ProcessControl] Max Dimensions. Width: 422 Height: 627.
[2024-11-25 19:51:07.343 INF] [INFO] Max Height: 432.
[2024-11-25 19:51:07.343 INF] [INFO] Max Height: 637.
[2024-11-25 19:51:07.343 DBG] [DEBUG] Update content sizes: 637.
[2024-11-25 19:51:07.343 INF] [INFO] [AddStartupTabControls] Adding the scrollable panel to the tab page. Size: {Width=432, Height=637}
[2024-11-25 19:51:07.343 DBG] [DEBUG] Adding tab page to form: Startup
[2024-11-25 19:51:07.343 DBG] [DEBUG] Calling AddTabWithControls for the Stream Ending tab
[2024-11-25 19:51:07.343 DBG] [DEBUG] Calling AddTabWithControls for the Support Me tab
[2024-11-25 19:51:07.343 DBG] [DEBUG] Calling InitialiseControls.
[2024-11-25 19:51:07.343 DBG] [DEBUG] Calling: StyleFormUserActionControls
[2024-11-25 19:51:07.343 DBG] [DEBUG] Styling Form Interaction Controls.
[2024-11-25 19:51:07.346 DBG] [DEBUG] Calling: StyleApplicationListControls
[2024-11-25 19:51:07.346 DBG] [DEBUG] Styling Application List Controls.
[2024-11-25 19:51:07.350 DBG] [DEBUG] Calling: StyleActionListsControls
[2024-11-25 19:51:07.350 DBG] [DEBUG] Styling Action List Controls.
[2024-11-25 19:51:07.356 DBG] [DEBUG] Calling: StyleStartupConfigControls
[2024-11-25 19:51:07.356 DBG] [DEBUG] Styling Start Up Config Controls.
[2024-11-25 19:51:07.358 DBG] [DEBUG] Calling: StyleFormFlowControls
[2024-11-25 19:51:07.358 DBG] [DEBUG] Styling Form Flow Controls.
[2024-11-25 19:51:07.359 DBG] [DEBUG] Adding TabControl to the base form.
[2024-11-25 19:51:07.398 INF] [INFO] [ResizeFormToFitContent] Initial Form Size: Width=600, Height=600
[2024-11-25 19:51:07.398 INF] [INFO] [Environment] Screen Resolution: 3840x1600
[2024-11-25 19:51:07.398 INF] [INFO] [Environment] Working Area: 3840x1552
[2024-11-25 19:51:07.398 INF] [INFO] [Environment] DPI Scaling: 96 DPI
[2024-11-25 19:51:07.398 INF] [INFO] [Environment] OS Version: Microsoft Windows NT 10.0.26100.0
[2024-11-25 19:51:07.398 INF] [INFO] [Environment] .NET Runtime Version: 4.0.30319.42000
[2024-11-25 19:51:07.398 INF] [INFO] [ResizeFormToFitContent] Form AutoSizeMode: GrowAndShrink
[2024-11-25 19:51:07.398 INF] [INFO] [CalculateDynamicHeight] Processing controls at Nesting Level 0
[2024-11-25 19:51:07.398 INF] [INFO] [Control] Name=, Type=TabControl, Text=
[2024-11-25 19:51:07.398 INF] [INFO]     Location: X=0, Y=0, Size: Width=584, Height=561
[2024-11-25 19:51:07.398 INF] [INFO]     Margins: {Left=3,Top=3,Right=3,Bottom=3}, Padding: {Left=0,Top=0,Right=0,Bottom=0}
[2024-11-25 19:51:07.398 INF] [INFO]     Visibility: Visible=True, Enabled=True, TabStop=True
[2024-11-25 19:51:07.398 INF] [INFO]     Anchor: Top, Left, Dock: Fill
[2024-11-25 19:51:07.398 INF] [INFO]     AutoSize: False
[2024-11-25 19:51:07.398 INF] [INFO]     AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.398 INF] [INFO]     Preferred Size: Height=100, Width=200
[2024-11-25 19:51:07.398 INF] [INFO]     Calculated Size (with Margins): Height=106, Width=206
[2024-11-25 19:51:07.398 INF] [INFO]     Processing child controls of ...
[2024-11-25 19:51:07.398 INF] [INFO]     [CalculateDynamicHeight] Processing controls at Nesting Level 1
[2024-11-25 19:51:07.398 INF] [INFO]     [Control] Name=, Type=TabPage, Text=Startup
[2024-11-25 19:51:07.398 INF] [INFO]         Location: X=4, Y=24, Size: Width=576, Height=533
[2024-11-25 19:51:07.398 INF] [INFO]         Margins: {Left=3,Top=3,Right=3,Bottom=3}, Padding: {Left=10,Top=10,Right=10,Bottom=10}
[2024-11-25 19:51:07.398 INF] [INFO]         Visibility: Visible=True, Enabled=True, TabStop=False
[2024-11-25 19:51:07.398 INF] [INFO]         Anchor: Top, Left, Dock: None
[2024-11-25 19:51:07.398 INF] [INFO]         AutoSize: False
[2024-11-25 19:51:07.398 INF] [INFO]         AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.398 INF] [INFO]         Preferred Size: Height=20, Width=20
[2024-11-25 19:51:07.398 INF] [INFO]         Calculated Size (with Margins): Height=26, Width=26
[2024-11-25 19:51:07.398 INF] [INFO]         Processing child controls of ...
[2024-11-25 19:51:07.398 INF] [INFO]         [CalculateDynamicHeight] Processing controls at Nesting Level 2
[2024-11-25 19:51:07.398 INF] [INFO]         [Control] Name=, Type=Panel, Text=
[2024-11-25 19:51:07.398 INF] [INFO]             Location: X=10, Y=10, Size: Width=556, Height=637
[2024-11-25 19:51:07.398 INF] [INFO]             Margins: {Left=3,Top=3,Right=3,Bottom=3}, Padding: {Left=0,Top=0,Right=0,Bottom=0}
[2024-11-25 19:51:07.398 INF] [INFO]             Visibility: Visible=True, Enabled=True, TabStop=False
[2024-11-25 19:51:07.398 INF] [INFO]             Anchor: Top, Left, Dock: Fill
[2024-11-25 19:51:07.398 INF] [INFO]             AutoSize: False
[2024-11-25 19:51:07.398 INF] [INFO]             AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.399 INF] [INFO]             Preferred Size: Height=697, Width=432
[2024-11-25 19:51:07.399 INF] [INFO]             Calculated Size (with Margins): Height=703, Width=438
[2024-11-25 19:51:07.399 INF] [INFO]             Processing child controls of ...
[2024-11-25 19:51:07.399 INF] [INFO]             [CalculateDynamicHeight] Processing controls at Nesting Level 3
[2024-11-25 19:51:07.399 INF] [INFO]             [Control] Name=, Type=TableLayoutPanel, Text=
[2024-11-25 19:51:07.399 INF] [INFO]                 Location: X=0, Y=0, Size: Width=539, Height=697
[2024-11-25 19:51:07.399 INF] [INFO]                 Margins: {Left=2,Top=2,Right=2,Bottom=2}, Padding: {Left=2,Top=2,Right=2,Bottom=2}
[2024-11-25 19:51:07.399 INF] [INFO]                 Visibility: Visible=True, Enabled=True, TabStop=False
[2024-11-25 19:51:07.399 INF] [INFO]                 Anchor: Top, Left, Dock: Top
[2024-11-25 19:51:07.399 INF] [INFO]                 AutoSize: True
[2024-11-25 19:51:07.399 INF] [INFO]                 AutoSizeMode (TableLayoutPanel): GrowAndShrink is implicitly supported
[2024-11-25 19:51:07.399 INF] [INFO]                 Preferred Size: Height=697, Width=523
[2024-11-25 19:51:07.399 INF] [INFO]                 Calculated Size (with Margins): Height=701, Width=527
[2024-11-25 19:51:07.399 INF] [INFO]                 Processing child controls of ...
[2024-11-25 19:51:07.399 INF] [INFO]                 [CalculateDynamicHeight] Processing controls at Nesting Level 4
[2024-11-25 19:51:07.399 INF] [INFO]                 [Control] Name=, Type=GroupBox, Text=Manage your configuration
[2024-11-25 19:51:07.399 INF] [INFO]                     Location: X=5, Y=5, Size: Width=529, Height=48
[2024-11-25 19:51:07.399 INF] [INFO]                     Margins: {Left=2,Top=2,Right=2,Bottom=2}, Padding: {Left=2,Top=2,Right=2,Bottom=2}
[2024-11-25 19:51:07.399 INF] [INFO]                     Visibility: Visible=True, Enabled=True, TabStop=False
[2024-11-25 19:51:07.399 INF] [INFO]                     Anchor: Top, Left, Dock: Fill
[2024-11-25 19:51:07.399 INF] [INFO]                     AutoSize: True
[2024-11-25 19:51:07.399 INF] [INFO]                     AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.399 INF] [INFO]                     Preferred Size: Height=48, Width=460
[2024-11-25 19:51:07.399 INF] [INFO]                     Calculated Size (with Margins): Height=52, Width=464
[2024-11-25 19:51:07.399 INF] [INFO]                     Processing child controls of ...
[2024-11-25 19:51:07.399 INF] [INFO]                     [CalculateDynamicHeight] Processing controls at Nesting Level 5
[2024-11-25 19:51:07.399 INF] [INFO]                     [Control] Name=, Type=TableLayoutPanel, Text=
[2024-11-25 19:51:07.399 INF] [INFO]                         Location: X=2, Y=20, Size: Width=525, Height=26
[2024-11-25 19:51:07.399 INF] [INFO]                         Margins: {Left=0,Top=0,Right=0,Bottom=0}, Padding: {Left=0,Top=0,Right=0,Bottom=0}
[2024-11-25 19:51:07.399 INF] [INFO]                         Visibility: Visible=True, Enabled=True, TabStop=False
[2024-11-25 19:51:07.399 INF] [INFO]                         Anchor: Top, Left, Dock: Fill
[2024-11-25 19:51:07.399 INF] [INFO]                         AutoSize: True
[2024-11-25 19:51:07.399 INF] [INFO]                         AutoSizeMode (TableLayoutPanel): GrowAndShrink is implicitly supported
[2024-11-25 19:51:07.399 INF] [INFO]                         Preferred Size: Height=26, Width=456
[2024-11-25 19:51:07.399 INF] [INFO]                         Calculated Size (with Margins): Height=26, Width=456
[2024-11-25 19:51:07.399 INF] [INFO]                         Processing child controls of ...
[2024-11-25 19:51:07.399 INF] [INFO]                         [CalculateDynamicHeight] Processing controls at Nesting Level 6
[2024-11-25 19:51:07.399 INF] [INFO]                         [Control] Name=, Type=Button, Text=Remove All
[2024-11-25 19:51:07.399 INF] [INFO]                             Location: X=7, Y=1, Size: Width=90, Height=24
[2024-11-25 19:51:07.399 INF] [INFO]                             Margins: {Left=0,Top=0,Right=0,Bottom=0}, Padding: {Left=3,Top=3,Right=3,Bottom=3}
[2024-11-25 19:51:07.399 INF] [INFO]                             Visibility: Visible=True, Enabled=True, TabStop=True
[2024-11-25 19:51:07.399 INF] [INFO]                             Anchor: None, Dock: None
[2024-11-25 19:51:07.399 INF] [INFO]                             AutoSize: False
[2024-11-25 19:51:07.399 INF] [INFO]                             AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.399 INF] [INFO]                             Preferred Size: Height=31, Width=90
[2024-11-25 19:51:07.399 INF] [INFO]                             Calculated Size (with Margins): Height=31, Width=90
[2024-11-25 19:51:07.399 INF] [INFO]                         [Control] Name=, Type=Button, Text=Import
[2024-11-25 19:51:07.399 INF] [INFO]                             Location: X=111, Y=1, Size: Width=90, Height=24
[2024-11-25 19:51:07.399 INF] [INFO]                             Margins: {Left=0,Top=0,Right=0,Bottom=0}, Padding: {Left=3,Top=3,Right=3,Bottom=3}
[2024-11-25 19:51:07.399 INF] [INFO]                             Visibility: Visible=True, Enabled=True, TabStop=True
[2024-11-25 19:51:07.399 INF] [INFO]                             Anchor: None, Dock: None
[2024-11-25 19:51:07.399 INF] [INFO]                             AutoSize: False
[2024-11-25 19:51:07.399 INF] [INFO]                             AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.399 INF] [INFO]                             Preferred Size: Height=31, Width=90
[2024-11-25 19:51:07.399 INF] [INFO]                             Calculated Size (with Margins): Height=31, Width=90
[2024-11-25 19:51:07.399 INF] [INFO]                         [Control] Name=, Type=Button, Text=Export
[2024-11-25 19:51:07.399 INF] [INFO]                             Location: X=215, Y=1, Size: Width=90, Height=24
[2024-11-25 19:51:07.399 INF] [INFO]                             Margins: {Left=0,Top=0,Right=0,Bottom=0}, Padding: {Left=3,Top=3,Right=3,Bottom=3}
[2024-11-25 19:51:07.399 INF] [INFO]                             Visibility: Visible=True, Enabled=True, TabStop=True
[2024-11-25 19:51:07.399 INF] [INFO]                             Anchor: None, Dock: None
[2024-11-25 19:51:07.399 INF] [INFO]                             AutoSize: False
[2024-11-25 19:51:07.399 INF] [INFO]                             AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.399 INF] [INFO]                             Preferred Size: Height=31, Width=90
[2024-11-25 19:51:07.399 INF] [INFO]                             Calculated Size (with Margins): Height=31, Width=90
[2024-11-25 19:51:07.399 INF] [INFO]                         [Control] Name=, Type=Button, Text=About
[2024-11-25 19:51:07.399 INF] [INFO]                             Location: X=319, Y=1, Size: Width=90, Height=24
[2024-11-25 19:51:07.399 INF] [INFO]                             Margins: {Left=0,Top=0,Right=0,Bottom=0}, Padding: {Left=3,Top=3,Right=3,Bottom=3}
[2024-11-25 19:51:07.399 INF] [INFO]                             Visibility: Visible=True, Enabled=True, TabStop=True
[2024-11-25 19:51:07.399 INF] [INFO]                             Anchor: None, Dock: None
[2024-11-25 19:51:07.399 INF] [INFO]                             AutoSize: False
[2024-11-25 19:51:07.399 INF] [INFO]                             AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.399 INF] [INFO]                             Preferred Size: Height=31, Width=90
[2024-11-25 19:51:07.399 INF] [INFO]                             Calculated Size (with Margins): Height=31, Width=90
[2024-11-25 19:51:07.399 INF] [INFO]                         [Control] Name=, Type=Button, Text=Test
[2024-11-25 19:51:07.399 INF] [INFO]                             Location: X=425, Y=1, Size: Width=90, Height=24
[2024-11-25 19:51:07.399 INF] [INFO]                             Margins: {Left=0,Top=0,Right=0,Bottom=0}, Padding: {Left=3,Top=3,Right=3,Bottom=3}
[2024-11-25 19:51:07.399 INF] [INFO]                             Visibility: Visible=True, Enabled=True, TabStop=True
[2024-11-25 19:51:07.399 INF] [INFO]                             Anchor: None, Dock: None
[2024-11-25 19:51:07.399 INF] [INFO]                             AutoSize: False
[2024-11-25 19:51:07.399 INF] [INFO]                             AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.399 INF] [INFO]                             Preferred Size: Height=31, Width=90
[2024-11-25 19:51:07.399 INF] [INFO]                             Calculated Size (with Margins): Height=31, Width=90
[2024-11-25 19:51:07.399 INF] [INFO]                         [CalculateDynamicHeight] Total Calculated Dimensions at Nesting Level 6: Height=165, Width=525
[2024-11-25 19:51:07.399 INF] [INFO]                     [CalculateDynamicHeight] Total Calculated Dimensions at Nesting Level 5: Height=201, Width=537
[2024-11-25 19:51:07.399 INF] [INFO]                 [Control] Name=, Type=GroupBox, Text=Applications to run on bot startup
[2024-11-25 19:51:07.399 INF] [INFO]                     Location: X=5, Y=58, Size: Width=529, Height=194
[2024-11-25 19:51:07.399 INF] [INFO]                     Margins: {Left=2,Top=2,Right=2,Bottom=2}, Padding: {Left=2,Top=2,Right=2,Bottom=2}
[2024-11-25 19:51:07.399 INF] [INFO]                     Visibility: Visible=True, Enabled=True, TabStop=False
[2024-11-25 19:51:07.399 INF] [INFO]                     Anchor: Top, Left, Dock: Fill
[2024-11-25 19:51:07.399 INF] [INFO]                     AutoSize: True
[2024-11-25 19:51:07.399 INF] [INFO]                     AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.399 INF] [INFO]                     Preferred Size: Height=194, Width=391
[2024-11-25 19:51:07.399 INF] [INFO]                     Calculated Size (with Margins): Height=198, Width=395
[2024-11-25 19:51:07.399 INF] [INFO]                     Processing child controls of ...
[2024-11-25 19:51:07.399 INF] [INFO]                     [CalculateDynamicHeight] Processing controls at Nesting Level 5
[2024-11-25 19:51:07.399 INF] [INFO]                     [Control] Name=, Type=TableLayoutPanel, Text=
[2024-11-25 19:51:07.399 INF] [INFO]                         Location: X=2, Y=20, Size: Width=525, Height=172
[2024-11-25 19:51:07.400 INF] [INFO]                         Margins: {Left=0,Top=0,Right=0,Bottom=0}, Padding: {Left=0,Top=0,Right=0,Bottom=0}
[2024-11-25 19:51:07.400 INF] [INFO]                         Visibility: Visible=True, Enabled=True, TabStop=False
[2024-11-25 19:51:07.400 INF] [INFO]                         Anchor: Top, Left, Dock: Fill
[2024-11-25 19:51:07.400 INF] [INFO]                         AutoSize: True
[2024-11-25 19:51:07.400 INF] [INFO]                         AutoSizeMode (TableLayoutPanel): GrowAndShrink is implicitly supported
[2024-11-25 19:51:07.400 INF] [INFO]                         Preferred Size: Height=172, Width=387
[2024-11-25 19:51:07.400 INF] [INFO]                         Calculated Size (with Margins): Height=172, Width=387
[2024-11-25 19:51:07.400 INF] [INFO]                         Processing child controls of ...
[2024-11-25 19:51:07.400 INF] [INFO]                         [CalculateDynamicHeight] Processing controls at Nesting Level 6
[2024-11-25 19:51:07.400 INF] [INFO]                         [Control] Name=, Type=ListBox, Text=
[2024-11-25 19:51:07.400 INF] [INFO]                             Location: X=6, Y=6, Size: Width=388, Height=138
[2024-11-25 19:51:07.400 INF] [INFO]                             Margins: {Left=5,Top=5,Right=5,Bottom=0}, Padding: {Left=5,Top=5,Right=5,Bottom=0}
[2024-11-25 19:51:07.400 INF] [INFO]                             Visibility: Visible=True, Enabled=True, TabStop=True
[2024-11-25 19:51:07.400 INF] [INFO]                             Anchor: Top, Left, Dock: Fill
[2024-11-25 19:51:07.400 INF] [INFO]                             AutoSize: False
[2024-11-25 19:51:07.400 INF] [INFO]                             AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.400 INF] [INFO]                             Preferred Size: Height=29, Width=33
[2024-11-25 19:51:07.400 INF] [INFO]                             Calculated Size (with Margins): Height=34, Width=43
[2024-11-25 19:51:07.400 INF] [INFO]                         [Control] Name=, Type=FlowLayoutPanel, Text=
[2024-11-25 19:51:07.400 INF] [INFO]                             Location: X=400, Y=1, Size: Width=124, Height=86
[2024-11-25 19:51:07.400 INF] [INFO]                             Margins: {Left=0,Top=0,Right=0,Bottom=0}, Padding: {Left=0,Top=0,Right=0,Bottom=0}
[2024-11-25 19:51:07.400 INF] [INFO]                             Visibility: Visible=True, Enabled=True, TabStop=False
[2024-11-25 19:51:07.400 INF] [INFO]                             Anchor: Top, Dock: None
[2024-11-25 19:51:07.400 INF] [INFO]                             AutoSize: True
[2024-11-25 19:51:07.400 INF] [INFO]                             AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.400 INF] [INFO]                             Preferred Size: Height=86, Width=124
[2024-11-25 19:51:07.400 INF] [INFO]                             Calculated Size (with Margins): Height=86, Width=124
[2024-11-25 19:51:07.400 INF] [INFO]                             Processing child controls of ...
[2024-11-25 19:51:07.400 INF] [INFO]                             [CalculateDynamicHeight] Processing controls at Nesting Level 7
[2024-11-25 19:51:07.400 INF] [INFO]                             [Control] Name=, Type=Button, Text=Add Application
[2024-11-25 19:51:07.400 INF] [INFO]                                 Location: X=1, Y=3, Size: Width=120, Height=24
[2024-11-25 19:51:07.400 INF] [INFO]                                 Margins: {Left=1,Top=3,Right=1,Bottom=1}, Padding: {Left=2,Top=2,Right=2,Bottom=2}
[2024-11-25 19:51:07.401 INF] [INFO]                                 Visibility: Visible=True, Enabled=True, TabStop=True
[2024-11-25 19:51:07.401 INF] [INFO]                                 Anchor: Top, Left, Dock: None
[2024-11-25 19:51:07.401 INF] [INFO]                                 AutoSize: False
[2024-11-25 19:51:07.401 INF] [INFO]                                 AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.401 INF] [INFO]                                 Preferred Size: Height=29, Width=120
[2024-11-25 19:51:07.401 INF] [INFO]                                 Calculated Size (with Margins): Height=33, Width=122
[2024-11-25 19:51:07.401 INF] [INFO]                             [Control] Name=, Type=Button, Text=Remove Application
[2024-11-25 19:51:07.401 INF] [INFO]                                 Location: X=1, Y=31, Size: Width=120, Height=24
[2024-11-25 19:51:07.401 INF] [INFO]                                 Margins: {Left=1,Top=3,Right=1,Bottom=1}, Padding: {Left=2,Top=2,Right=2,Bottom=2}
[2024-11-25 19:51:07.401 INF] [INFO]                                 Visibility: Visible=True, Enabled=False, TabStop=True
[2024-11-25 19:51:07.401 INF] [INFO]                                 Anchor: Top, Left, Dock: None
[2024-11-25 19:51:07.401 INF] [INFO]                                 AutoSize: False
[2024-11-25 19:51:07.401 INF] [INFO]                                 AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.401 INF] [INFO]                                 Preferred Size: Height=29, Width=122
[2024-11-25 19:51:07.401 INF] [INFO]                                 Calculated Size (with Margins): Height=33, Width=124
[2024-11-25 19:51:07.401 INF] [INFO]                             [Control] Name=, Type=Button, Text=Add Path
[2024-11-25 19:51:07.401 INF] [INFO]                                 Location: X=1, Y=59, Size: Width=120, Height=24
[2024-11-25 19:51:07.401 INF] [INFO]                                 Margins: {Left=1,Top=3,Right=1,Bottom=1}, Padding: {Left=2,Top=2,Right=2,Bottom=2}
[2024-11-25 19:51:07.401 INF] [INFO]                                 Visibility: Visible=True, Enabled=True, TabStop=True
[2024-11-25 19:51:07.401 INF] [INFO]                                 Anchor: Top, Left, Dock: None
[2024-11-25 19:51:07.401 INF] [INFO]                                 AutoSize: False
[2024-11-25 19:51:07.401 INF] [INFO]                                 AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.401 INF] [INFO]                                 Preferred Size: Height=29, Width=120
[2024-11-25 19:51:07.401 INF] [INFO]                                 Calculated Size (with Margins): Height=33, Width=122
[2024-11-25 19:51:07.401 INF] [INFO]                             [CalculateDynamicHeight] Total Calculated Dimensions at Nesting Level 7: Height=109, Width=131
[2024-11-25 19:51:07.401 INF] [INFO]                         [Control] Name=, Type=FlowLayoutPanel, Text=
[2024-11-25 19:51:07.401 INF] [INFO]                             Location: X=348, Y=148, Size: Width=46, Height=22
[2024-11-25 19:51:07.401 INF] [INFO]                             Margins: {Left=1,Top=1,Right=5,Bottom=1}, Padding: {Left=0,Top=0,Right=0,Bottom=0}
[2024-11-25 19:51:07.401 INF] [INFO]                             Visibility: Visible=True, Enabled=True, TabStop=False
[2024-11-25 19:51:07.401 INF] [INFO]                             Anchor: Right, Dock: None
[2024-11-25 19:51:07.401 INF] [INFO]                             AutoSize: True
[2024-11-25 19:51:07.401 INF] [INFO]                             AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.401 INF] [INFO]                             Preferred Size: Height=22, Width=46
[2024-11-25 19:51:07.401 INF] [INFO]                             Calculated Size (with Margins): Height=24, Width=52
[2024-11-25 19:51:07.401 INF] [INFO]                             Processing child controls of ...
[2024-11-25 19:51:07.401 INF] [INFO]                             [CalculateDynamicHeight] Processing controls at Nesting Level 7
[2024-11-25 19:51:07.401 INF] [INFO]                             [Control] Name=, Type=Button, Text=â–²
[2024-11-25 19:51:07.401 INF] [INFO]                                 Location: X=1, Y=0, Size: Width=20, Height=20
[2024-11-25 19:51:07.401 INF] [INFO]                                 Margins: {Left=1,Top=0,Right=1,Bottom=0}, Padding: {Left=0,Top=0,Right=0,Bottom=0}
[2024-11-25 19:51:07.401 INF] [INFO]                                 Visibility: Visible=True, Enabled=True, TabStop=True
[2024-11-25 19:51:07.401 INF] [INFO]                                 Anchor: Top, Left, Dock: None
[2024-11-25 19:51:07.401 INF] [INFO]                                 AutoSize: False
[2024-11-25 19:51:07.401 INF] [INFO]                                 AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.401 INF] [INFO]                                 Preferred Size: Height=30, Width=27
[2024-11-25 19:51:07.401 INF] [INFO]                                 Calculated Size (with Margins): Height=30, Width=29
[2024-11-25 19:51:07.401 INF] [INFO]                             [Control] Name=, Type=Button, Text=â–¼
[2024-11-25 19:51:07.401 INF] [INFO]                                 Location: X=23, Y=0, Size: Width=20, Height=20
[2024-11-25 19:51:07.401 INF] [INFO]                                 Margins: {Left=1,Top=0,Right=1,Bottom=0}, Padding: {Left=0,Top=0,Right=0,Bottom=0}
[2024-11-25 19:51:07.401 INF] [INFO]                                 Visibility: Visible=True, Enabled=True, TabStop=True
[2024-11-25 19:51:07.401 INF] [INFO]                                 Anchor: Top, Left, Dock: None
[2024-11-25 19:51:07.401 INF] [INFO]                                 AutoSize: False
[2024-11-25 19:51:07.401 INF] [INFO]                                 AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.401 INF] [INFO]                                 Preferred Size: Height=30, Width=27
[2024-11-25 19:51:07.401 INF] [INFO]                                 Calculated Size (with Margins): Height=30, Width=29
[2024-11-25 19:51:07.401 INF] [INFO]                             [CalculateDynamicHeight] Total Calculated Dimensions at Nesting Level 7: Height=70, Width=53
[2024-11-25 19:51:07.401 INF] [INFO]                         [CalculateDynamicHeight] Total Calculated Dimensions at Nesting Level 6: Height=333, Width=534
[2024-11-25 19:51:07.401 INF] [INFO]                     [CalculateDynamicHeight] Total Calculated Dimensions at Nesting Level 5: Height=515, Width=544
[2024-11-25 19:51:07.401 INF] [INFO]                 [Control] Name=, Type=GroupBox, Text=Allowed Actions
[2024-11-25 19:51:07.401 INF] [INFO]                     Location: X=5, Y=257, Size: Width=529, Height=169
[2024-11-25 19:51:07.401 INF] [INFO]                     Margins: {Left=2,Top=2,Right=2,Bottom=2}, Padding: {Left=2,Top=2,Right=2,Bottom=2}
[2024-11-25 19:51:07.401 INF] [INFO]                     Visibility: Visible=True, Enabled=True, TabStop=False
[2024-11-25 19:51:07.401 INF] [INFO]                     Anchor: Top, Left, Dock: Fill
[2024-11-25 19:51:07.401 INF] [INFO]                     AutoSize: True
[2024-11-25 19:51:07.401 INF] [INFO]                     AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.401 INF] [INFO]                     Preferred Size: Height=169, Width=513
[2024-11-25 19:51:07.401 INF] [INFO]                     Calculated Size (with Margins): Height=173, Width=517
[2024-11-25 19:51:07.401 INF] [INFO]                     Processing child controls of ...
[2024-11-25 19:51:07.402 INF] [INFO]                     [CalculateDynamicHeight] Processing controls at Nesting Level 5
[2024-11-25 19:51:07.402 INF] [INFO]                     [Control] Name=, Type=TableLayoutPanel, Text=
[2024-11-25 19:51:07.402 INF] [INFO]                         Location: X=2, Y=20, Size: Width=525, Height=147
[2024-11-25 19:51:07.402 INF] [INFO]                         Margins: {Left=0,Top=0,Right=0,Bottom=0}, Padding: {Left=0,Top=0,Right=0,Bottom=0}
[2024-11-25 19:51:07.402 INF] [INFO]                         Visibility: Visible=True, Enabled=True, TabStop=False
[2024-11-25 19:51:07.402 INF] [INFO]                         Anchor: Top, Left, Dock: Fill
[2024-11-25 19:51:07.402 INF] [INFO]                         AutoSize: True
[2024-11-25 19:51:07.402 INF] [INFO]                         AutoSizeMode (TableLayoutPanel): GrowAndShrink is implicitly supported
[2024-11-25 19:51:07.402 INF] [INFO]                         Preferred Size: Height=147, Width=509
[2024-11-25 19:51:07.402 INF] [INFO]                         Calculated Size (with Margins): Height=147, Width=509
[2024-11-25 19:51:07.402 INF] [INFO]                         Processing child controls of ...
[2024-11-25 19:51:07.402 INF] [INFO]                         [CalculateDynamicHeight] Processing controls at Nesting Level 6
[2024-11-25 19:51:07.402 INF] [INFO]                         [Control] Name=, Type=ListBox, Text=
[2024-11-25 19:51:07.402 INF] [INFO]                             Location: X=6, Y=6, Size: Width=388, Height=138
[2024-11-25 19:51:07.402 INF] [INFO]                             Margins: {Left=5,Top=5,Right=5,Bottom=0}, Padding: {Left=5,Top=5,Right=5,Bottom=0}
[2024-11-25 19:51:07.402 INF] [INFO]                             Visibility: Visible=True, Enabled=True, TabStop=True
[2024-11-25 19:51:07.402 INF] [INFO]                             Anchor: Top, Left, Dock: Fill
[2024-11-25 19:51:07.402 INF] [INFO]                             AutoSize: False
[2024-11-25 19:51:07.402 INF] [INFO]                             AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.402 INF] [INFO]                             Preferred Size: Height=29, Width=33
[2024-11-25 19:51:07.402 INF] [INFO]                             Calculated Size (with Margins): Height=34, Width=43
[2024-11-25 19:51:07.402 INF] [INFO]                         [Control] Name=, Type=FlowLayoutPanel, Text=
[2024-11-25 19:51:07.402 INF] [INFO]                             Location: X=400, Y=1, Size: Width=124, Height=58
[2024-11-25 19:51:07.402 INF] [INFO]                             Margins: {Left=0,Top=0,Right=0,Bottom=0}, Padding: {Left=0,Top=0,Right=0,Bottom=0}
[2024-11-25 19:51:07.402 INF] [INFO]                             Visibility: Visible=True, Enabled=True, TabStop=False
[2024-11-25 19:51:07.402 INF] [INFO]                             Anchor: Top, Dock: None
[2024-11-25 19:51:07.402 INF] [INFO]                             AutoSize: True
[2024-11-25 19:51:07.402 INF] [INFO]                             AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.402 INF] [INFO]                             Preferred Size: Height=30, Width=246
[2024-11-25 19:51:07.402 INF] [INFO]                             Calculated Size (with Margins): Height=30, Width=246
[2024-11-25 19:51:07.402 INF] [INFO]                             Processing child controls of ...
[2024-11-25 19:51:07.402 INF] [INFO]                             [CalculateDynamicHeight] Processing controls at Nesting Level 7
[2024-11-25 19:51:07.402 INF] [INFO]                             [Control] Name=, Type=Button, Text=Add Action
[2024-11-25 19:51:07.402 INF] [INFO]                                 Location: X=1, Y=3, Size: Width=120, Height=24
[2024-11-25 19:51:07.402 INF] [INFO]                                 Margins: {Left=1,Top=3,Right=1,Bottom=1}, Padding: {Left=2,Top=2,Right=2,Bottom=2}
[2024-11-25 19:51:07.402 INF] [INFO]                                 Visibility: Visible=True, Enabled=True, TabStop=True
[2024-11-25 19:51:07.402 INF] [INFO]                                 Anchor: Top, Left, Dock: None
[2024-11-25 19:51:07.402 INF] [INFO]                                 AutoSize: False
[2024-11-25 19:51:07.402 INF] [INFO]                                 AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.402 INF] [INFO]                                 Preferred Size: Height=29, Width=120
[2024-11-25 19:51:07.402 INF] [INFO]                                 Calculated Size (with Margins): Height=33, Width=122
[2024-11-25 19:51:07.402 INF] [INFO]                             [Control] Name=, Type=Button, Text=Remove Action
[2024-11-25 19:51:07.402 INF] [INFO]                                 Location: X=1, Y=31, Size: Width=120, Height=24
[2024-11-25 19:51:07.402 INF] [INFO]                                 Margins: {Left=1,Top=3,Right=1,Bottom=1}, Padding: {Left=2,Top=2,Right=2,Bottom=2}
[2024-11-25 19:51:07.402 INF] [INFO]                                 Visibility: Visible=True, Enabled=False, TabStop=True
[2024-11-25 19:51:07.402 INF] [INFO]                                 Anchor: Top, Left, Dock: None
[2024-11-25 19:51:07.402 INF] [INFO]                                 AutoSize: False
[2024-11-25 19:51:07.402 INF] [INFO]                                 AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.402 INF] [INFO]                                 Preferred Size: Height=29, Width=120
[2024-11-25 19:51:07.402 INF] [INFO]                                 Calculated Size (with Margins): Height=33, Width=122
[2024-11-25 19:51:07.402 INF] [INFO]                             [CalculateDynamicHeight] Total Calculated Dimensions at Nesting Level 7: Height=76, Width=131
[2024-11-25 19:51:07.402 INF] [INFO]                         [CalculateDynamicHeight] Total Calculated Dimensions at Nesting Level 6: Height=150, Width=534
[2024-11-25 19:51:07.402 INF] [INFO]                     [CalculateDynamicHeight] Total Calculated Dimensions at Nesting Level 5: Height=307, Width=544
[2024-11-25 19:51:07.402 INF] [INFO]                 [Control] Name=, Type=GroupBox, Text=Blocked Actions
[2024-11-25 19:51:07.402 INF] [INFO]                     Location: X=5, Y=431, Size: Width=529, Height=169
[2024-11-25 19:51:07.402 INF] [INFO]                     Margins: {Left=2,Top=2,Right=2,Bottom=2}, Padding: {Left=2,Top=2,Right=2,Bottom=2}
[2024-11-25 19:51:07.402 INF] [INFO]                     Visibility: Visible=True, Enabled=True, TabStop=False
[2024-11-25 19:51:07.402 INF] [INFO]                     Anchor: Top, Left, Dock: Fill
[2024-11-25 19:51:07.402 INF] [INFO]                     AutoSize: True
[2024-11-25 19:51:07.402 INF] [INFO]                     AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.402 INF] [INFO]                     Preferred Size: Height=169, Width=513
[2024-11-25 19:51:07.402 INF] [INFO]                     Calculated Size (with Margins): Height=173, Width=517
[2024-11-25 19:51:07.402 INF] [INFO]                     Processing child controls of ...
[2024-11-25 19:51:07.402 INF] [INFO]                     [CalculateDynamicHeight] Processing controls at Nesting Level 5
[2024-11-25 19:51:07.402 INF] [INFO]                     [Control] Name=, Type=TableLayoutPanel, Text=
[2024-11-25 19:51:07.402 INF] [INFO]                         Location: X=2, Y=20, Size: Width=525, Height=147
[2024-11-25 19:51:07.402 INF] [INFO]                         Margins: {Left=0,Top=0,Right=0,Bottom=0}, Padding: {Left=0,Top=0,Right=0,Bottom=0}
[2024-11-25 19:51:07.402 INF] [INFO]                         Visibility: Visible=True, Enabled=True, TabStop=False
[2024-11-25 19:51:07.402 INF] [INFO]                         Anchor: Top, Left, Dock: Fill
[2024-11-25 19:51:07.402 INF] [INFO]                         AutoSize: True
[2024-11-25 19:51:07.402 INF] [INFO]                         AutoSizeMode (TableLayoutPanel): GrowAndShrink is implicitly supported
[2024-11-25 19:51:07.402 INF] [INFO]                         Preferred Size: Height=147, Width=509
[2024-11-25 19:51:07.402 INF] [INFO]                         Calculated Size (with Margins): Height=147, Width=509
[2024-11-25 19:51:07.402 INF] [INFO]                         Processing child controls of ...
[2024-11-25 19:51:07.402 INF] [INFO]                         [CalculateDynamicHeight] Processing controls at Nesting Level 6
[2024-11-25 19:51:07.402 INF] [INFO]                         [Control] Name=, Type=ListBox, Text=
[2024-11-25 19:51:07.402 INF] [INFO]                             Location: X=6, Y=6, Size: Width=388, Height=138
[2024-11-25 19:51:07.402 INF] [INFO]                             Margins: {Left=5,Top=5,Right=5,Bottom=0}, Padding: {Left=5,Top=5,Right=5,Bottom=0}
[2024-11-25 19:51:07.402 INF] [INFO]                             Visibility: Visible=True, Enabled=True, TabStop=True
[2024-11-25 19:51:07.402 INF] [INFO]                             Anchor: Top, Left, Dock: Fill
[2024-11-25 19:51:07.402 INF] [INFO]                             AutoSize: False
[2024-11-25 19:51:07.402 INF] [INFO]                             AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.402 INF] [INFO]                             Preferred Size: Height=29, Width=33
[2024-11-25 19:51:07.402 INF] [INFO]                             Calculated Size (with Margins): Height=34, Width=43
[2024-11-25 19:51:07.402 INF] [INFO]                         [Control] Name=, Type=FlowLayoutPanel, Text=
[2024-11-25 19:51:07.402 INF] [INFO]                             Location: X=400, Y=1, Size: Width=124, Height=58
[2024-11-25 19:51:07.402 INF] [INFO]                             Margins: {Left=0,Top=0,Right=0,Bottom=0}, Padding: {Left=0,Top=0,Right=0,Bottom=0}
[2024-11-25 19:51:07.402 INF] [INFO]                             Visibility: Visible=True, Enabled=True, TabStop=False
[2024-11-25 19:51:07.402 INF] [INFO]                             Anchor: Top, Dock: None
[2024-11-25 19:51:07.402 INF] [INFO]                             AutoSize: True
[2024-11-25 19:51:07.402 INF] [INFO]                             AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.402 INF] [INFO]                             Preferred Size: Height=30, Width=246
[2024-11-25 19:51:07.402 INF] [INFO]                             Calculated Size (with Margins): Height=30, Width=246
[2024-11-25 19:51:07.402 INF] [INFO]                             Processing child controls of ...
[2024-11-25 19:51:07.402 INF] [INFO]                             [CalculateDynamicHeight] Processing controls at Nesting Level 7
[2024-11-25 19:51:07.402 INF] [INFO]                             [Control] Name=, Type=Button, Text=Add Action
[2024-11-25 19:51:07.402 INF] [INFO]                                 Location: X=1, Y=3, Size: Width=120, Height=24
[2024-11-25 19:51:07.402 INF] [INFO]                                 Margins: {Left=1,Top=3,Right=1,Bottom=1}, Padding: {Left=2,Top=2,Right=2,Bottom=2}
[2024-11-25 19:51:07.402 INF] [INFO]                                 Visibility: Visible=True, Enabled=True, TabStop=True
[2024-11-25 19:51:07.402 INF] [INFO]                                 Anchor: Top, Left, Dock: None
[2024-11-25 19:51:07.402 INF] [INFO]                                 AutoSize: False
[2024-11-25 19:51:07.402 INF] [INFO]                                 AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.402 INF] [INFO]                                 Preferred Size: Height=29, Width=120
[2024-11-25 19:51:07.402 INF] [INFO]                                 Calculated Size (with Margins): Height=33, Width=122
[2024-11-25 19:51:07.402 INF] [INFO]                             [Control] Name=, Type=Button, Text=Remove Action
[2024-11-25 19:51:07.402 INF] [INFO]                                 Location: X=1, Y=31, Size: Width=120, Height=24
[2024-11-25 19:51:07.402 INF] [INFO]                                 Margins: {Left=1,Top=3,Right=1,Bottom=1}, Padding: {Left=2,Top=2,Right=2,Bottom=2}
[2024-11-25 19:51:07.402 INF] [INFO]                                 Visibility: Visible=True, Enabled=False, TabStop=True
[2024-11-25 19:51:07.403 INF] [INFO]                                 Anchor: Top, Left, Dock: None
[2024-11-25 19:51:07.403 INF] [INFO]                                 AutoSize: False
[2024-11-25 19:51:07.403 INF] [INFO]                                 AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.403 INF] [INFO]                                 Preferred Size: Height=29, Width=120
[2024-11-25 19:51:07.403 INF] [INFO]                                 Calculated Size (with Margins): Height=33, Width=122
[2024-11-25 19:51:07.403 INF] [INFO]                             [CalculateDynamicHeight] Total Calculated Dimensions at Nesting Level 7: Height=76, Width=131
[2024-11-25 19:51:07.403 INF] [INFO]                         [CalculateDynamicHeight] Total Calculated Dimensions at Nesting Level 6: Height=150, Width=534
[2024-11-25 19:51:07.403 INF] [INFO]                     [CalculateDynamicHeight] Total Calculated Dimensions at Nesting Level 5: Height=307, Width=544
[2024-11-25 19:51:07.403 INF] [INFO]                 [Control] Name=, Type=GroupBox, Text=Load Applications on Startup
[2024-11-25 19:51:07.403 INF] [INFO]                     Location: X=5, Y=605, Size: Width=529, Height=60
[2024-11-25 19:51:07.403 INF] [INFO]                     Margins: {Left=2,Top=2,Right=2,Bottom=2}, Padding: {Left=2,Top=2,Right=2,Bottom=2}
[2024-11-25 19:51:07.403 INF] [INFO]                     Visibility: Visible=True, Enabled=True, TabStop=False
[2024-11-25 19:51:07.403 INF] [INFO]                     Anchor: Top, Left, Dock: Fill
[2024-11-25 19:51:07.403 INF] [INFO]                     AutoSize: False
[2024-11-25 19:51:07.403 INF] [INFO]                     AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.403 INF] [INFO]                     Preferred Size: Height=52, Width=381
[2024-11-25 19:51:07.403 INF] [INFO]                     Calculated Size (with Margins): Height=56, Width=385
[2024-11-25 19:51:07.403 INF] [INFO]                     Processing child controls of ...
[2024-11-25 19:51:07.403 INF] [INFO]                     [CalculateDynamicHeight] Processing controls at Nesting Level 5
[2024-11-25 19:51:07.403 INF] [INFO]                     [Control] Name=, Type=TableLayoutPanel, Text=
[2024-11-25 19:51:07.403 INF] [INFO]                         Location: X=2, Y=20, Size: Width=525, Height=38
[2024-11-25 19:51:07.403 INF] [INFO]                         Margins: {Left=0,Top=0,Right=0,Bottom=0}, Padding: {Left=0,Top=0,Right=0,Bottom=0}
[2024-11-25 19:51:07.403 INF] [INFO]                         Visibility: Visible=True, Enabled=True, TabStop=False
[2024-11-25 19:51:07.403 INF] [INFO]                         Anchor: Top, Left, Dock: Fill
[2024-11-25 19:51:07.403 INF] [INFO]                         AutoSize: True
[2024-11-25 19:51:07.403 INF] [INFO]                         AutoSizeMode (TableLayoutPanel): GrowAndShrink is implicitly supported
[2024-11-25 19:51:07.403 INF] [INFO]                         Preferred Size: Height=30, Width=377
[2024-11-25 19:51:07.403 INF] [INFO]                         Calculated Size (with Margins): Height=30, Width=377
[2024-11-25 19:51:07.403 INF] [INFO]                         Processing child controls of ...
[2024-11-25 19:51:07.403 INF] [INFO]                         [CalculateDynamicHeight] Processing controls at Nesting Level 6
[2024-11-25 19:51:07.403 INF] [INFO]                         [Control] Name=, Type=RadioButton, Text=Yes
[2024-11-25 19:51:07.403 INF] [INFO]                             Location: X=4, Y=4, Size: Width=49, Height=30
[2024-11-25 19:51:07.403 INF] [INFO]                             Margins: {Left=3,Top=3,Right=3,Bottom=3}, Padding: {Left=0,Top=0,Right=0,Bottom=0}
[2024-11-25 19:51:07.403 INF] [INFO]                             Visibility: Visible=True, Enabled=True, TabStop=False
[2024-11-25 19:51:07.403 INF] [INFO]                             Anchor: Top, Left, Dock: Fill
[2024-11-25 19:51:07.403 INF] [INFO]                             AutoSize: True
[2024-11-25 19:51:07.403 INF] [INFO]                             AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.403 INF] [INFO]                             Preferred Size: Height=22, Width=41
[2024-11-25 19:51:07.403 INF] [INFO]                             Calculated Size (with Margins): Height=28, Width=47
[2024-11-25 19:51:07.403 INF] [INFO]                         [Control] Name=, Type=RadioButton, Text=No
[2024-11-25 19:51:07.403 INF] [INFO]                             Location: X=60, Y=4, Size: Width=49, Height=30
[2024-11-25 19:51:07.403 INF] [INFO]                             Margins: {Left=3,Top=3,Right=3,Bottom=3}, Padding: {Left=0,Top=0,Right=0,Bottom=0}
[2024-11-25 19:51:07.403 INF] [INFO]                             Visibility: Visible=True, Enabled=True, TabStop=False
[2024-11-25 19:51:07.403 INF] [INFO]                             Anchor: Top, Left, Dock: Fill
[2024-11-25 19:51:07.403 INF] [INFO]                             AutoSize: True
[2024-11-25 19:51:07.403 INF] [INFO]                             AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.403 INF] [INFO]                             Preferred Size: Height=22, Width=39
[2024-11-25 19:51:07.403 INF] [INFO]                             Calculated Size (with Margins): Height=28, Width=45
[2024-11-25 19:51:07.403 INF] [INFO]                         [Control] Name=, Type=RadioButton, Text=Prompt
[2024-11-25 19:51:07.403 INF] [INFO]                             Location: X=116, Y=4, Size: Width=64, Height=30
[2024-11-25 19:51:07.403 INF] [INFO]                             Margins: {Left=3,Top=3,Right=3,Bottom=3}, Padding: {Left=0,Top=0,Right=0,Bottom=0}
[2024-11-25 19:51:07.403 INF] [INFO]                             Visibility: Visible=True, Enabled=True, TabStop=False
[2024-11-25 19:51:07.403 INF] [INFO]                             Anchor: Top, Left, Dock: Fill
[2024-11-25 19:51:07.403 INF] [INFO]                             AutoSize: True
[2024-11-25 19:51:07.403 INF] [INFO]                             AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.404 INF] [INFO]                             Preferred Size: Height=22, Width=63
[2024-11-25 19:51:07.404 INF] [INFO]                             Calculated Size (with Margins): Height=28, Width=69
[2024-11-25 19:51:07.404 INF] [INFO]                         [Control] Name=, Type=Label, Text=Delay (In seconds)
[2024-11-25 19:51:07.404 INF] [INFO]                             Location: X=336, Y=1, Size: Width=134, Height=36
[2024-11-25 19:51:07.404 INF] [INFO]                             Margins: {Left=3,Top=0,Right=3,Bottom=0}, Padding: {Left=0,Top=0,Right=0,Bottom=0}
[2024-11-25 19:51:07.404 INF] [INFO]                             Visibility: Visible=True, Enabled=True, TabStop=False
[2024-11-25 19:51:07.404 INF] [INFO]                             Anchor: Top, Left, Dock: Fill
[2024-11-25 19:51:07.404 INF] [INFO]                             AutoSize: True
[2024-11-25 19:51:07.404 INF] [INFO]                             AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.404 INF] [INFO]                             Preferred Size: Height=23, Width=123
[2024-11-25 19:51:07.404 INF] [INFO]                             Calculated Size (with Margins): Height=23, Width=129
[2024-11-25 19:51:07.404 INF] [INFO]                         [Control] Name=, Type=NumericUpDown, Text=2
[2024-11-25 19:51:07.404 INF] [INFO]                             Location: X=476, Y=6, Size: Width=40, Height=25
[2024-11-25 19:51:07.404 INF] [INFO]                             Margins: {Left=2,Top=0,Right=0,Bottom=0}, Padding: {Left=0,Top=0,Right=0,Bottom=0}
[2024-11-25 19:51:07.404 INF] [INFO]                             Visibility: Visible=True, Enabled=True, TabStop=True
[2024-11-25 19:51:07.404 INF] [INFO]                             Anchor: Left, Dock: None
[2024-11-25 19:51:07.404 INF] [INFO]                             AutoSize: False
[2024-11-25 19:51:07.404 INF] [INFO]                             AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.404 INF] [INFO]                             Preferred Size: Height=25, Width=41
[2024-11-25 19:51:07.404 INF] [INFO]                             Calculated Size (with Margins): Height=25, Width=43
[2024-11-25 19:51:07.404 INF] [INFO]                             Processing child controls of ...
[2024-11-25 19:51:07.404 INF] [INFO]                             [CalculateDynamicHeight] Processing controls at Nesting Level 7
[2024-11-25 19:51:07.404 INF] [INFO]                             [Control] Name=, Type=UpDownButtons, Text=
[2024-11-25 19:51:07.404 INF] [INFO]                                 Location: X=23, Y=1, Size: Width=16, Height=23
[2024-11-25 19:51:07.405 INF] [INFO]                                 Margins: {Left=3,Top=3,Right=3,Bottom=3}, Padding: {Left=0,Top=0,Right=0,Bottom=0}
[2024-11-25 19:51:07.405 INF] [INFO]                                 Visibility: Visible=True, Enabled=True, TabStop=False
[2024-11-25 19:51:07.405 INF] [INFO]                                 Anchor: Top, Left, Dock: None
[2024-11-25 19:51:07.405 INF] [INFO]                                 AutoSize: False
[2024-11-25 19:51:07.405 INF] [INFO]                                 AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.405 INF] [INFO]                                 Preferred Size: Height=23, Width=16
[2024-11-25 19:51:07.405 INF] [INFO]                                 Calculated Size (with Margins): Height=29, Width=22
[2024-11-25 19:51:07.405 INF] [INFO]                             [Control] Name=, Type=UpDownEdit, Text=2
[2024-11-25 19:51:07.405 INF] [INFO]                                 Location: X=2, Y=2, Size: Width=20, Height=21
[2024-11-25 19:51:07.405 INF] [INFO]                                 Margins: {Left=3,Top=3,Right=3,Bottom=3}, Padding: {Left=0,Top=0,Right=0,Bottom=0}
[2024-11-25 19:51:07.405 INF] [INFO]                                 Visibility: Visible=True, Enabled=True, TabStop=True
[2024-11-25 19:51:07.405 INF] [INFO]                                 Anchor: Top, Left, Dock: None
[2024-11-25 19:51:07.405 INF] [INFO]                                 AutoSize: False
[2024-11-25 19:51:07.405 INF] [INFO]                                 AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.406 INF] [INFO]                                 Preferred Size: Height=19, Width=17
[2024-11-25 19:51:07.406 INF] [INFO]                                 Calculated Size (with Margins): Height=25, Width=23
[2024-11-25 19:51:07.406 INF] [INFO]                             [CalculateDynamicHeight] Total Calculated Dimensions at Nesting Level 7: Height=64, Width=49
[2024-11-25 19:51:07.406 INF] [INFO]                         [CalculateDynamicHeight] Total Calculated Dimensions at Nesting Level 6: Height=206, Width=526
[2024-11-25 19:51:07.406 INF] [INFO]                     [CalculateDynamicHeight] Total Calculated Dimensions at Nesting Level 5: Height=246, Width=537
[2024-11-25 19:51:07.406 INF] [INFO]                 [Control] Name=, Type=FlowLayoutPanel, Text=
[2024-11-25 19:51:07.406 INF] [INFO]                     Location: X=178, Y=668, Size: Width=182, Height=26
[2024-11-25 19:51:07.406 INF] [INFO]                     Margins: {Left=0,Top=0,Right=0,Bottom=0}, Padding: {Left=0,Top=0,Right=0,Bottom=0}
[2024-11-25 19:51:07.406 INF] [INFO]                     Visibility: Visible=True, Enabled=True, TabStop=False
[2024-11-25 19:51:07.406 INF] [INFO]                     Anchor: None, Dock: None
[2024-11-25 19:51:07.406 INF] [INFO]                     AutoSize: True
[2024-11-25 19:51:07.406 INF] [INFO]                     AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.406 INF] [INFO]                     Preferred Size: Height=26, Width=182
[2024-11-25 19:51:07.406 INF] [INFO]                     Calculated Size (with Margins): Height=26, Width=182
[2024-11-25 19:51:07.406 INF] [INFO]                     Processing child controls of ...
[2024-11-25 19:51:07.406 INF] [INFO]                     [CalculateDynamicHeight] Processing controls at Nesting Level 5
[2024-11-25 19:51:07.406 INF] [INFO]                     [Control] Name=, Type=Button, Text=Save
[2024-11-25 19:51:07.406 INF] [INFO]                         Location: X=0, Y=0, Size: Width=90, Height=24
[2024-11-25 19:51:07.406 INF] [INFO]                         Margins: {Left=0,Top=0,Right=0,Bottom=0}, Padding: {Left=3,Top=3,Right=3,Bottom=3}
[2024-11-25 19:51:07.406 INF] [INFO]                         Visibility: Visible=True, Enabled=False, TabStop=True
[2024-11-25 19:51:07.406 INF] [INFO]                         Anchor: Top, Left, Dock: None
[2024-11-25 19:51:07.406 INF] [INFO]                         AutoSize: False
[2024-11-25 19:51:07.406 INF] [INFO]                         AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.406 INF] [INFO]                         Preferred Size: Height=31, Width=90
[2024-11-25 19:51:07.406 INF] [INFO]                         Calculated Size (with Margins): Height=31, Width=90
[2024-11-25 19:51:07.406 INF] [INFO]                     [Control] Name=, Type=Button, Text=Close
[2024-11-25 19:51:07.406 INF] [INFO]                         Location: X=90, Y=0, Size: Width=90, Height=24
[2024-11-25 19:51:07.406 INF] [INFO]                         Margins: {Left=0,Top=0,Right=0,Bottom=0}, Padding: {Left=3,Top=3,Right=3,Bottom=3}
[2024-11-25 19:51:07.406 INF] [INFO]                         Visibility: Visible=True, Enabled=True, TabStop=True
[2024-11-25 19:51:07.406 INF] [INFO]                         Anchor: Top, Left, Dock: None
[2024-11-25 19:51:07.406 INF] [INFO]                         AutoSize: False
[2024-11-25 19:51:07.406 INF] [INFO]                         AutoSizeMode: Not Applicable
[2024-11-25 19:51:07.406 INF] [INFO]                         Preferred Size: Height=31, Width=90
[2024-11-25 19:51:07.406 INF] [INFO]                         Calculated Size (with Margins): Height=31, Width=90
[2024-11-25 19:51:07.406 INF] [INFO]                     [CalculateDynamicHeight] Total Calculated Dimensions at Nesting Level 5: Height=72, Width=190
[2024-11-25 19:51:07.406 INF] [INFO]                 [CalculateDynamicHeight] Total Calculated Dimensions at Nesting Level 4: Height=2336, Width=554
[2024-11-25 19:51:07.406 INF] [INFO]             [CalculateDynamicHeight] Total Calculated Dimensions at Nesting Level 3: Height=3047, Width=564
[2024-11-25 19:51:07.406 INF] [INFO]         [CalculateDynamicHeight] Total Calculated Dimensions at Nesting Level 2: Height=3760, Width=576
[2024-11-25 19:51:07.406 INF] [INFO]     [CalculateDynamicHeight] Total Calculated Dimensions at Nesting Level 1: Height=3796, Width=590
[2024-11-25 19:51:07.406 INF] [INFO] [CalculateDynamicHeight] Total Calculated Dimensions at Nesting Level 0: Height=3912, Width=600
[2024-11-25 19:51:07.406 INF] [INFO] [ResizeFormToFitContent] Calculated Required Dimensions: Height=3912, Width=600
[2024-11-25 19:51:07.408 INF] [INFO] [ResizeFormToFitContent] Resized Form Size: Width=600, Height=600
[2024-11-25 19:51:07.408 INF] [INFO] [ResizeFormToFitContent] Final Form Size: Width=600, Height=600
[2024-11-25 19:51:07.408 INF] [INFO] [Summary] Total Controls Processed: 180
[2024-11-25 19:51:07.408 INF] [INFO] [Summary] Visible Controls: 0, Invisible Controls: 0
[2024-11-25 19:51:07.408 INF] [INFO] [Summary] Maximum Nesting Depth Reached: 7

Issue: 
The form size is wrong. As we can see in the image it should be around 800 height, but is finishing at 600. Why? 