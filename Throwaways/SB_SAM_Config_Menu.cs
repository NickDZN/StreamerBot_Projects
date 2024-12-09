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
using System.Reflection;     // For BindingFlags

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
        CPHLogger.LogD("Centralised CPH, enabling centralised methods.");

        // Attempt to get the handle of the currently active window
        CPHLogger.LogD("Getting Window Details");
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
    private void AddTabWithControls(TabControl tabControl, string title, Action<TabPage> addControls)
    {
        var tabPage = CreateTabPage(title);
        addControls(tabPage);

        // Ensure tabPage takes up the full space and the controls within it are properly sized
        tabPage.Dock = DockStyle.Fill;

        tabControl.TabPages.Add(tabPage);
    }

    private void InitialiseControls()
    {
        // Apply consistent styling for other controls
        CPHLogger.LogDebug("Calling: StyleForm");
        StyleForm();

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

    // Refactored BuildCoreForm to make it cleaner
    private TabControl BuildCoreForm(Rectangle activeWindowRect)
    {
        CPHLogger.LogDebug("[BuildCoreForm][S]");

        this.Text = Constants.FormName;
        CPHLogger.LogInfo($"Form Name: {this.Text}");

        //this.Width = 600;
        //this.Height = 800;
        CPHLogger.LogInfo($"Form Base Size. W:{this.Width} H:{this.Height}");

        this.AutoSize = true;
        this.AutoSizeMode = AutoSizeMode.GrowAndShrink;
        CPHLogger.LogDebug("[BuildCoreForm] Setting Auto Size Properties");

        this.MinimumSize = new Size(600, 600);
        CPHLogger.LogInfo($"Form MinimumSize Set. W:{this.Width} H:{this.Height}");

        CPHLogger.LogDebug("[BuildCoreForm] Setting base form styling.");
        this.BackColor = Color.WhiteSmoke;
        this.FormBorderStyle = FormBorderStyle.FixedDialog;
        this.Font = new Font("Segoe UI", 10, FontStyle.Regular);

        CPHLogger.LogDebug("[BuildCoreForm] Calling CenterForm.");
        CenterForm(activeWindowRect);

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
        var tabPage = new TabPage(title)
        {
            Padding = new Padding(5) // Added padding for clarity
        };

        // Ensure the controls within the TabPage are properly aligned
        tabPage.Controls.Add(new TableLayoutPanel()
        {
            Dock = DockStyle.Fill,
            AutoSize = true,
        });

        return tabPage;
    }

    // General method to create a layout panel for any tab
    private TableLayoutPanel CreateBaseLevelTablePanel(int rowCount = 6, int columnCount = 1)
    {
        CPHLogger.LogInfo($"[TableLayoutPanel][S] CreateBaseLevelTablePanel. Cols: {columnCount} Rows: {rowCount}");
        var BasePanelForTab = new TableLayoutPanel();

        CPHLogger.LogDebug("[TableLayoutPanel] BasePanelForTab created. Applying styling.");
        UIStyling.StyleTableLayoutPanel(BasePanelForTab, rowCount: rowCount, columnCount: columnCount);

        CPHLogger.LogVerbose("[TableLayoutPanel] Returning Table Panel");
        return BasePanelForTab;
    }

    // Adding specific controls to the "Startup" tab
    private void AddStartupTabControls(TabPage startupTab)
    {
        CPHLogger.LogDebug("[AddStartupTabControls][S] Creating Tab base level scroll panel");
        var baseScrollablePanelForTab = new Panel();


        CPHLogger.LogDebug("[AddStartupTabControls] Calling Create Layout Panel.");
        var coreLayoutPanelForTab = CreateBaseLevelTablePanel(rowCount: 6, columnCount: 1);

        // Add controls to the layout panel
        CPHLogger.LogVerbose("[AddStartupTabControls] Calling AddConfigurationControls.");
        AddConfigurationControls(coreLayoutPanelForTab);
        CPHLogger.LogVerbose("[AddStartupTabControls] Calling AddApplicationControls.");
        AddApplicationControls(coreLayoutPanelForTab);
        CPHLogger.LogVerbose("[AddStartupTabControls] Calling AddSeparateActionGroups.");
        AddSeparateActionGroups(coreLayoutPanelForTab);
        CPHLogger.LogVerbose("[AddStartupTabControls] Calling AddStartupConfigurationControls.");
        AddStartupConfigurationControls(coreLayoutPanelForTab);
        CPHLogger.LogVerbose("[AddStartupTabControls] Calling AddApplicationControlButtons.");
        AddApplicationControlButtons(coreLayoutPanelForTab);

        // Add the layout panel to the scrollable panel
        CPHLogger.LogDebug($"[AddStartupTabControls] Adding Layout Panel to the Scrollable Panel. {coreLayoutPanelForTab.Size}");
        baseScrollablePanelForTab.Controls.Add(coreLayoutPanelForTab);

        // Dynamically calculate the minimum size for the scrollable panel
        //CPHLogger.LogDebug("[AddStartupTabControls] SetMinimumSizeBasedOnChildControls.");
        //SetMinimumSizeBasedOnChildControls(coreLayoutPanelForTab, baseScrollablePanelForTab);

        // Add the scrollable panel to the tab
        CPHLogger.LogInfo($"[AddStartupTabControls] Adding the scrollable panel to the tab page. Size: {baseScrollablePanelForTab.Size}");
        startupTab.Controls.Add(baseScrollablePanelForTab);

        coreLayoutPanelForTab.PerformLayout();
        baseScrollablePanelForTab.PerformLayout();

        // Log the layout panel height after forcing layout
        CPHLogger.LogInfo($"[AddStartupTabControls] Main Layout Panel Height (After Layout): {coreLayoutPanelForTab.Height}");
        CPHLogger.LogInfo($"[AddStartupTabControls] Scrollable Panel Height (After Layout): {baseScrollablePanelForTab.Height}");

        // Add the scrollable panel to the tab
        startupTab.Controls.Add(baseScrollablePanelForTab);
        UIStyling.StylePanel(baseScrollablePanelForTab);

        // Log the height of the tab page containing the layout panel
        CPHLogger.LogInfo($"[AddStartupTabControls] Tab Height (After Layout): {startupTab.Height}");

        // Optionally, log the TabControl height after layout if needed
        TabControl tabControl = startupTab.Parent as TabControl;
        if (tabControl != null)
        {
            CPHLogger.LogInfo($"[AddStartupTabControls] TabControl Height (After Layout): {tabControl.Height}");
        }
    }


    /* STARTUP TAB
    **
    **
    **
    **
    */
    private void AddConfigurationControls(TableLayoutPanel coreLayoutPanelForTab)
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
            customRowStyles: rowStyling,
            customColumnStyles: columnStyling
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
        coreLayoutPanelForTab.Controls.Add(configurationGroupBox);
    }

    // Flow control. Save and exit buttons.
    //ToDo: Centralise buttons to the bottom.
    private void AddApplicationControlButtons(TableLayoutPanel coreLayoutPanelForTab)
    {
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

        // Add the button panel to the main layout panel
        coreLayoutPanelForTab.Controls.Add(buttonPanel);
    }

    private void AddApplicationControls(TableLayoutPanel coreLayoutPanelForTab)
    {
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

        UIStyling.StyleTableLayoutPanel(
            tpanelApplications,
            rowCount: 2,
            customRowStyles: rowStyling,
            customColumnStyles: columnStyling
        );

        // Add list box
        tpanelApplications.Controls.Add(lstApplications, 0, 0);

        // Create panel for Add/Remove buttons
        FlowLayoutPanel buttonPanel = new FlowLayoutPanel();
        UIStyling.StyleFlowBox(flowBox: buttonPanel,
            fBoxDirection: FlowDirection.TopDown,
            anchorStyle: AnchorStyles.Top
        );

        buttonPanel.Controls.Add(btnAddApplication);
        buttonPanel.Controls.Add(btnRemoveApplication);
        buttonPanel.Controls.Add(btnAddApplicationPath);

        // Add button panel
        tpanelApplications.Controls.Add(buttonPanel, 1, 0);

        // Add arrow buttons
        FlowLayoutPanel fpanelApplicationArrows = new FlowLayoutPanel();
        UIStyling.StyleFlowBox(flowBox: fpanelApplicationArrows,
            customPadding: new Padding(1, 1, 5, 1),
            anchorStyle: AnchorStyles.Right
        );

        // Create the arrow buttons.
        fpanelApplicationArrows.Controls.Add(btnMoveUp);
        fpanelApplicationArrows.Controls.Add(btnMoveDown);

        // Add arrowButtonsPanel below the ListBox, centered

        // Attach event handlers.
        lstApplications.SelectedIndexChanged += ApplicationListBox_SelectedIndexChanged;
        btnAddApplication.Click += AddApplication_Click;
        btnAddApplicationPath.Click += AddApplicationPath_Click;
        btnRemoveApplication.Click += RemoveApplication_Click;
        btnMoveUp.Click += btnApplicationsUp_Click;
        btnMoveDown.Click += btnApplicationsDown_Click;

        applicationsToStartGroupBox.Controls.Add(tpanelApplications);

        coreLayoutPanelForTab.Controls.Add(applicationsToStartGroupBox);
    }

    private void AddSeparateActionGroups(TableLayoutPanel coreLayoutPanelForTab)
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
        coreLayoutPanelForTab.Controls.Add(allowedActionsGroupBox);
        coreLayoutPanelForTab.Controls.Add(blockedActionsGroupBox);
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
            customRowStyles: rowStyling,
            customColumnStyles: columnStyling
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
        //FormResizer.ResizeFormToFitContent(this);
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

        UIStyling.StyleTableLayoutPanel(
            startupOptionsPanel,
            columnCount: 6,
            customColumnStyles: columnStyling
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
        coreLayoutPanelForTab.Controls.Add(startupOptionsGroup);
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
    public static void StyleNumberUpDown(NumericUpDown numericUpDown)
    {
        numericUpDown.Width = 40;
        numericUpDown.Minimum = 0;
        numericUpDown.Maximum = 30;
        numericUpDown.Value = 2;
        numericUpDown.Anchor = AnchorStyles.Left;
        numericUpDown.Margin = new Padding(2, 0, 0, 0);
    }

    public static void StyleRadioButton(RadioButton radioButton, string prompt)
    {
        radioButton.Text = prompt;
        radioButton.AutoSize = true;
        radioButton.Dock = DockStyle.Fill;
        radioButton.TextAlign = ContentAlignment.MiddleLeft;
    }

    public static void StyleLabel(Label label, string labelText)
    {
        label.Text = labelText;
        label.AutoSize = true;
        label.Dock = DockStyle.Fill;
        label.TextAlign = ContentAlignment.MiddleLeft;
    }


    // Style for primary/main buttons
    public static void StyleBtn(Button btn, string btnText, int btnType = 1, bool btnEnabled = true,
                        Padding? btnMargin = null, Padding? btnPadding = null)
    {
        // Set button properties
        btn.Text = btnText;
        btn.Height = 24;
        btn.Enabled = btnEnabled;

        // Set common button styles
        btn.Font = new Font("Microsoft Sans Serif", 8.5f);
        btn.BackColor = Color.White;
        btn.ForeColor = SystemColors.ControlText;
        btn.FlatAppearance.BorderSize = 1;
        btn.FlatAppearance.BorderColor = Color.DarkGray;

        // Switch on button type to customize further
        switch (btnType)
        {
            case 1:
                btn.Width = 90;
                // Specific margin for button type 1 (if not already provided)
                btn.Margin = btnMargin ?? new Padding(0, 0, 0, 0);
                btn.Margin = btnPadding ?? new Padding(2, 2, 2, 2);
                break;

            case 2:
                btn.Width = 120;
                // Specific margin for button type 2 (if not already provided)
                btn.Margin = btnMargin ?? new Padding(1, 3, 1, 1);
                btn.Margin = btnPadding ?? new Padding(2, 2, 2, 2);
                break;

            default:
                btn.Width = 90;
                // Default margin for unspecified types (if not already provided)
                btn.Margin = btnMargin ?? new Padding(0, 0, 0, 0);
                btn.Margin = btnPadding ?? new Padding(2, 2, 2, 2);
                break;
        }

        // Attach hover effects (assuming this is a method you have)
        AttachHoverEffects(btn);
    }


    // Style for arrow buttons (up/down buttons)
    public static void StyleArrowBtn(Button btn, string btnArrow)
    {
        btn.Text = btnArrow;
        btn.Width = 20;
        btn.Height = 20;
        btn.Margin = new Padding(1, 0, 1, 0);
        btn.Padding = new Padding(0, 0, 0, 0);
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

    public static void StylePanel(Panel panel, Padding? panelPadding = null)
    {
        panel.Dock = DockStyle.Fill;
        panel.AutoSize = true;
        panel.AutoScroll = true;
        panel.Padding = panelPadding ?? new Padding(0);
        panel.BackColor = Color.WhiteSmoke;
        panel.BackColor = Color.WhiteSmoke;
        panel.BorderStyle = BorderStyle.FixedSingle;
    }


    public static void StyleFlowBox(
        FlowLayoutPanel flowBox,
        FlowDirection fBoxDirection = FlowDirection.LeftToRight, // Default to LeftToRight
        bool autoWrap = true,
        Padding? customPadding = null, // Allow optional padding
        AnchorStyles anchorStyle = AnchorStyles.Top | AnchorStyles.Left | AnchorStyles.Right | AnchorStyles.Bottom // Default anchor
    )
    {
        flowBox.FlowDirection = fBoxDirection; // Assign the FlowDirection enum value directly
        flowBox.WrapContents = autoWrap; // Enable or disable wrapping
        flowBox.Anchor = anchorStyle; // Apply anchor styles
        flowBox.AutoSize = true; // Automatically resize based on contents
        flowBox.AutoSizeMode = AutoSizeMode.GrowAndShrink; // Allow resizing as content grows or shrinks
        flowBox.Padding = customPadding ?? new Padding(0); // Default margin

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
        int columnCount = 2,
        int rowCount = 1,
        List<RowStyle> customRowStyles = null,
        List<ColumnStyle> customColumnStyles = null,
        bool autoSizeTable = true
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
    // Set the general properties for the TabControl
    tabControl.Dock = DockStyle.Fill; // Make the TabControl fill the parent container
    tabControl.Font = new Font("Segoe UI", 10, FontStyle.Regular); // Set the font of the tabs

    // Enable auto-sizing for the TabControl
    tabControl.AutoSize = true;
    //tabControl.AutoSizeMode = AutoSizeMode.GrowAndShrink; // TabControl will resize based on its contents

    // Set the TabSizeMode to control how the tabs are sized
    tabControl.SizeMode = TabSizeMode.FillToRight; // Tab pages fill the width, maintaining consistent appearance

    // Set custom height for the tabs (e.g., 40px) while allowing width to adjust dynamically
    tabControl.ItemSize = new Size(100, 40); // ItemSize controls both width and height of tabs (e.g., 100px width, 40px height)
    
    // Optionally, handle custom tab drawing if needed for more customization (e.g., custom background, borders, etc.)
    tabControl.DrawMode = TabDrawMode.OwnerDrawFixed; // Enable custom drawing

    // Make sure the control has the proper flow and scroll handling:
    foreach (TabPage tabPage in tabControl.TabPages)
    {
        // Ensure each tab page inside the TabControl is appropriately resized with its contents
        tabPage.AutoScroll = true;  // Enable auto-scrolling if content overflows

        // Optional: Customize the layout and resizing behavior of any controls within the tab page
        foreach (Control control in tabPage.Controls)
        {
            control.Dock = DockStyle.Fill; // Ensure controls within the tab fill the available space
            // Additional control-specific styling can be added here if needed
        }
    }
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

            // Count visible and invisible controls
            if (control.Visible)
            {
                visibleControlsCount++;
            }
            else
            {
                invisibleControlsCount++;
            }

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





public static class Constants
{
    public const string ExecutableFilter = "Executable Files (*.exe)|*.exe|All Files (*.*)|*.*";
    public const string SettingsFileName = "settings.json";
    public const string FormName = "SBZen Config Manager";
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