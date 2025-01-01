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
                        mainFormInstance = new LoadStartupConfigForm(normalizedWindowRect);
                        // Apply normalized position
                        CPHLogger.LogI($"Applying normalized rectangle: {normalizedWindowRect}");
                        mainFormInstance.StartPosition = FormStartPosition.Manual;
                        mainFormInstance.Location = new Point(targetMonitor.Bounds.Left + normalizedWindowRect.X + 15, targetMonitor.Bounds.Top + normalizedWindowRect.Y + 15);
                        // Handle unhandled exceptions in the STA thread
                        Application.ThreadException += (sender, args) =>
                        {
                            CPHLogger.LogE($"Unhandled exception in STA thread: {args.Exception.Message}\n{args.Exception.StackTrace}");
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

        Rectangle normalizedRect = new Rectangle(normalizedX, normalizedY, windowRect.Width, windowRect.Height);
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
    private readonly UserConfigurationPanel _userConfigurationControls;
    private readonly SelectApplicationsPanel _startupApplicationsSection;
    private readonly StartupBehaviorControlPanel _startupConfigurationApplications;
    private readonly SelectActionsPanel _permittedActionsSection;
    private readonly SelectActionsPanel _blockedActionsSection;
    private readonly StartupBehaviorControlPanel _startupBehaviorControlActions;
    private readonly FormsControlPanel _formFlowControls;


    /// <summary>
    /// Initializes the configuration form with active window dimensions and action data.
    /// </summary>
    /// <param name = "activeWindowRect">Screen rectangle for positioning the form.</param>
    public LoadStartupConfigForm(Rectangle activeWindowRect)
    {
        CPHLogger.LogC("[S]LoadStartupConfigForm.");
        SetFormProperties(this);
        
        // Core layout panel for organizing all sections
        CPHLogger.LogC("Creating Table Layout");
        var coreLayoutPanelForForm = UIComponentFactory.CreateTableLayoutPanel(rows: 7, columns: 1);
        coreLayoutPanelForForm.Margin = new Padding(2, 2, 2, 10);

        //  User Configuration Panel
        CPHLogger.LogC("Creating _userConfigurationControls");
        _userConfigurationControls = new UserConfigurationPanel();
        coreLayoutPanelForForm.Controls.Add(_userConfigurationControls, 0, 0);
        
        // Startup Applications Panel
        CPHLogger.LogC("Creating _permittedStartupApplicationsSection");
        _startupApplicationsSection = new SelectApplicationsPanel("Permitted Applications", new List<ApplicationDetails>());
        coreLayoutPanelForForm.Controls.Add(_startupApplicationsSection, 0, 1);

        // Startup Behavior Control Panel
        CPHLogger.LogC("Creating _startupBehaviorControl");
        _startupConfigurationApplications = new StartupBehaviorControlPanel(StartupBehaviorControlPanel.StartupBehaviorType.Application);
        coreLayoutPanelForForm.Controls.Add(_startupConfigurationApplications, 0, 2);

        // Permitted Actions Panel
        CPHLogger.LogC("Creating _permittedActionsSection");
        _permittedActionsSection = new SelectActionsPanel("Permitted Actions", new List<ActionConfig>());
        coreLayoutPanelForForm.Controls.Add(_permittedActionsSection, 0, 3);
        
        // Blocked Actions Panel
        CPHLogger.LogC("Creating _blockedActionsSection");
        _blockedActionsSection = new SelectActionsPanel("Blocked Actions", new List<ActionConfig>());
        coreLayoutPanelForForm.Controls.Add(_blockedActionsSection, 0, 4);
        
        // Startup Behavior Control Panel
        CPHLogger.LogC("Creating _startupBehaviorControl");
        _startupBehaviorControlActions = new StartupBehaviorControlPanel(StartupBehaviorControlPanel.StartupBehaviorType.Action);
        coreLayoutPanelForForm.Controls.Add(_startupBehaviorControlActions, 0, 5);
        
        // 🧩 Form Flow Controls Panel
        CPHLogger.LogC("Creating _formFlowControls");
        _formFlowControls = new FormsControlPanel();
        coreLayoutPanelForForm.Controls.Add(_formFlowControls, 0, 6);
        
        // Add the core layout panel to the form
        CPHLogger.LogC("Adding coreLayoutPanelForForm to Controls.");
        Controls.Add(coreLayoutPanelForForm);

        SuspendLayout();
        ResumeLayout();
        CPHLogger.LogAll(this);
    }


    /// <summary>
    /// Sets the default properties for the form.
    /// </summary>
    /// <param name = "form">The target form object.</param>
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
        _resetSettings = UIComponentFactory.CreateButton("Reset All", Constants.ButtonStyle.Default, OnResetAll);
        _importConfig = UIComponentFactory.CreateButton("Import", Constants.ButtonStyle.Default, OnImport);
        _exportConfig = UIComponentFactory.CreateButton("Export", Constants.ButtonStyle.Default, OnExport);
        _testConfig = UIComponentFactory.CreateButton("Test Config", Constants.ButtonStyle.Default, OnTestConfig);
        _aboutApplication = UIComponentFactory.CreateButton("About", Constants.ButtonStyle.Default, OnAbout);
        
        CPHLogger.LogV("[UserConfigurationPanel] Placing Buttons.");
        buttonTable.Controls.Add(_resetSettings, 0, 0);
        buttonTable.Controls.Add(_importConfig, 1, 0);
        buttonTable.Controls.Add(_exportConfig, 2, 0);
        buttonTable.Controls.Add(_testConfig, 3, 0);
        buttonTable.Controls.Add(_aboutApplication, 4, 0);
        
        // Add TableLayoutPanel to GroupBox
        CPHLogger.LogV("[UserConfigurationPanel] Building Layout.");
        configurationGroupBox.Controls.Add(buttonTable);        
        Controls.Add(configurationGroupBox);
        CPHLogger.LogC("[E]UserConfigurationPanel.");
    }

    protected virtual void OnResetAll(object sender, EventArgs e)
    {
        DialogResult result = MessageBox.Show("Are you sure you want to reset the configuration?", "Confirm Reset", MessageBoxButtons.YesNo, MessageBoxIcon.Warning);
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

/*
** CLASS NAME: SelectApplicationsPanel [Last Updated: V2]
** Description: 
** A specialized panel for managing a list of applications.
** Supports adding, removing, and navigating application entries with buttons.
**
** Parameters: 
** sectionTitle:  [IN][string] Title of the panel displayed in the GroupBox.
** applications:  [IN][List<ApplicationDetails>] List of applications to display and manage.
**
** Layout: 
** - Row 1 (1 Column): ListBox spans entire row.
** - Row 2 (2 Columns): 
**     - Column 1: Add, Add Path, Remove buttons.
**     - Column 2: Navigation (Move Up/Down buttons).
**
** Methods:
** OnAddPathAction: Handles adding an application via folder selection.
** OnAddAction: Handles adding an application via user input.
** AddCustomButtons: Adds "Add Path" button.
**
** Returns: [void]
*/
public class SelectApplicationsPanel : SelectItemsPanel
{
    private readonly Button _addPathBtn; // Button to add application paths
    /// <summary>
    /// Initializes the SelectApplicationsPanel with a section title and a list of applications.
    /// </summary>
    /// <param name = "sectionTitle">Title of the panel.</param>
    /// <param name = "applications">List of applications to populate the panel.</param>
    public SelectApplicationsPanel(string sectionTitle, List<ApplicationDetails> applications) : base(sectionTitle, applications?.Select(app => $"{app.FileName} ({app.Index})").ToList() ?? new List<string>(), rows: 2, cols: 2)
    {
        if (applications == null) 
        {
            applications = new List<ApplicationDetails>();
            CPHLogger.LogW("Applications list was null. Initialized with an empty list.");
        }

        CPHLogger.LogC("[S]SelectApplicationsPanel: Setting Layout");
        ConfigureButtonPanel(flowDirection: FlowDirection.LeftToRight, wrapContents: false, autoSize: true, anchor: AnchorStyles.Top | AnchorStyles.Left);
        // Update TableLayoutPanel row/column styles
        _layoutTable.RowStyles.Clear();
        _layoutTable.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        _layoutTable.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        _layoutTable.ColumnStyles.Clear();
        _layoutTable.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        _layoutTable.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));

        // Adjust ListBox to span across the top row
        _layoutTable.SetColumnSpan(_itemsListBox, 2);
        _layoutTable.SetRowSpan(_itemsListBox, 1);
        
        // Initialize Add Path button
        CPHLogger.LogC("[S]SelectApplicationsPanel - Creating Add Path button");
        _addPathBtn = UIComponentFactory.CreateButton("Add Path", Constants.ButtonStyle.Longer, OnAddPathAction);
        
        // Clear default button panel and re-add buttons
        _buttonPanel.Controls.Clear();
        _buttonPanel.Controls.Add(_addBtn);
        _buttonPanel.Controls.Add(_addPathBtn);
        _buttonPanel.Controls.Add(_removeBtn);
        
        // Add the button panel to the second row, first column
        _layoutTable.Controls.Add(_buttonPanel, 0, 1);
        
        // Add navigation panel to the second row, second column
        _layoutTable.Controls.Add(_navigationPanel, 1, 1);
        CPHLogger.LogC("[E]SelectApplicationsPanel: Layout updated successfully");
    }

    /*
    ** Method: OnAddPathAction
    ** Description:
    ** Handles the "Add Path" button event, allowing users to add an application via folder selection.
    **
    ** Parameters:
    ** sender: [IN][object] Event source.
    ** e:      [IN][EventArgs] Event arguments.
    */
    private void OnAddPathAction(object sender, EventArgs e)
    {
        using (var dialog = new PathInputDialog(FindForm()))
        {
            if (dialog.ShowDialog(this) == DialogResult.OK)
            {
                string actionName = dialog.EnteredPath;
                if (!string.IsNullOrWhiteSpace(actionName))
                {
                    _itemsListBox.Items.Add(actionName);
                    MessageBox.Show($"Action added: {actionName}");
                }
            }
        }
    }


    protected override void OnAddAction(object sender, EventArgs e)
    {
        // Run the file dialog in a separate thread
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
                        string selectedFile = fileDialog.FileName;
                        this.Invoke(
                            new Action(() =>
                            {
                                if (!_itemsListBox.Items.Contains(selectedFile))
                                {
                                    _itemsListBox.Items.Add(selectedFile);
                                }
                                else
                                {
                                    MessageBox.Show("This application file has already been added.");
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

        fileDialogThread.SetApartmentState(ApartmentState.STA);
        fileDialogThread.Start();
    }


    /*
    ** Method: AddCustomButtons
    ** Description:
    ** Adds the "Add Path" button to the button panel explicitly.
    **
    ** Returns: [void]
    */
    protected override void AddCustomButtons()
    {
        if (!_buttonPanel.Controls.Contains(_addPathBtn))
        {
            _buttonPanel.Controls.Add(_addPathBtn);
            CPHLogger.LogV("Added Add Path button to button panel");
        }
    }
}


/// <summary>
/// Panels which contain a list of actions from the bot. 
/// Inherits from SelectItemsPanel handling shared functionality for other list panels..
/// </summary>
public class SelectActionsPanel : SelectItemsPanel
{
    /// <summary>
    /// Initializes a new instance of the SelectActionsPanel class.
    /// </summary>
    /// <param name = "sectionTitle">The title displayed on the panel (e.g., "Permitted Actions").</param>
    /// <param name = "actions">A list of actions to populate the ListBox with.</param>
    public SelectActionsPanel(string sectionTitle, List<ActionConfig> actions) // Calls the base class constructor (SelectItemsPanel) to initialize shared components.
    // Converts the list of ActionData objects to a list of their names (strings) for display.
    : base(sectionTitle, actions?.Select(actions => $"{actions.Name} ({actions.Order})").ToList() ?? new List<string>(), rows: 2, cols: 2)
    {
        if (actions == null)
        {
            actions = new List<ActionConfig>();
            CPHLogger.LogW($"{sectionTitle} Actions list was null. Initialized with an empty list.");
        }                 

        // Update TableLayoutPanel row/column styles
        _layoutTable.RowStyles.Clear();
        _layoutTable.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        _layoutTable.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        _layoutTable.ColumnStyles.Clear();
        _layoutTable.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        _layoutTable.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));

        // Adjust ListBox to span across the top row
        _layoutTable.SetColumnSpan(_itemsListBox, 2);
        _layoutTable.SetRowSpan(_itemsListBox, 1);

        // Add the button panel to the second row, first column
        _layoutTable.Controls.Add(_buttonPanel, 0, 1);
        // Add navigation panel to the second row, second column
        _layoutTable.Controls.Add(_navigationPanel, 1, 1);
        CPHLogger.LogC("[E]SelectApplicationsPanel: Layout updated successfully");
    }





    protected override void OnAddAction(object sender, EventArgs e)
    {
        
        var actionDataList = SB.GetActions(); 
        // Open the action manager form and pass the global action list
        using (ActionManagerForm actionManagerDialog = new ActionManagerForm(actionDataList)) // Pass the actions
        {
            if (actionManagerDialog.ShowDialog(this) == DialogResult.OK)
            {
                string selectedAction = actionManagerDialog.SelectedAction; // Get the selected action
                if (!string.IsNullOrWhiteSpace(selectedAction))
                {
                    _itemsListBox.Items.Add(selectedAction); // Add action to the list box
                }
            }
        }
    }
}


/// <summary>
/// A unified panel for configuring startup behavior, supporting both Applications and Actions.
/// </summary>
public class StartupBehaviorControlPanel : BaseConfigurationPanel
{
    private readonly ComboBox _startupOptionComboBox; // Dropdown for Yes/No/Prompt
    private readonly NumericUpDown _delayNumericUpDown; // Numeric selector for delay
    private readonly ComboBox _blockingOptionComboBox; // Dropdown for Blocking Yes/No
    private readonly Label _startupLabel; // Label for startup dropdown
    private readonly Label _delayLabel; // Label for delay
    private readonly Label _blockingLabel; // Label for blocking dropdown

    private readonly string _sectionTitle;

    public enum StartupBehaviorType
    {
        Application,
        Action
    }


    /// <summary>
    /// Initializes the Startup Behavior Control Panel.
    /// </summary>
    /// <param name="type">Specifies whether this panel is for Applications or Actions.</param>
    public StartupBehaviorControlPanel(StartupBehaviorType type)
    {
        _sectionTitle = type == StartupBehaviorType.Application ? "Application Startup Behavior" : "Action Startup Behavior";

        CPHLogger.LogC($"[S]StartupBehaviorControlPanel: Initializing {_sectionTitle}");

        var startupGroupBox = UIComponentFactory.CreateGroupBox(_sectionTitle);

        var layout = UIComponentFactory.CreateTableLayoutPanel(
            rows: 1,
            columns: 6,
            columnStyling: Constants.ColumnStyling.Default
        );

        // Startup Option
        _startupLabel = UIComponentFactory.CreateLabel("Auto Launch:");
        _startupOptionComboBox = UIComponentFactory.CreateComboBox(
            new List<string> { "On", "Off", "Prompt" },
            defaultSelectedIndex: 0,
            widthParam: 75
        );
        _startupOptionComboBox.SelectedIndexChanged += OnStartupOptionChanged;

        // Delay Option
        _delayLabel = UIComponentFactory.CreateLabel("Delay (seconds):");
        _delayNumericUpDown = UIComponentFactory.CreateNumericUpDown(
            width: 40,
            minimum: 0,
            maximum: 15,
            defaultValue: 2
        );
        _delayNumericUpDown.ValueChanged += OnDelayValueChanged;

        // Blocking Option
        _blockingLabel = UIComponentFactory.CreateLabel("Blocking:");
        _blockingOptionComboBox = UIComponentFactory.CreateComboBox(
            new List<string> { "Yes", "No" },
            defaultSelectedIndex: 1,
            widthParam: 50
        );
        _blockingOptionComboBox.SelectedIndexChanged += OnBlockingOptionChanged;

        // Add controls to the layout
        layout.Controls.Add(_startupLabel, 0, 0);
        layout.Controls.Add(_startupOptionComboBox, 1, 0);
        layout.Controls.Add(_delayLabel, 2, 0);
        layout.Controls.Add(_delayNumericUpDown, 3, 0);
        layout.Controls.Add(_blockingLabel, 4, 0);
        layout.Controls.Add(_blockingOptionComboBox, 5, 0);

        startupGroupBox.Controls.Add(layout);
        Controls.Add(startupGroupBox);

        CPHLogger.LogC($"[E]StartupBehaviorControlPanel: {_sectionTitle} Initialized successfully");
    }

    /// <summary>
    /// Handles changes in the Startup dropdown.
    /// </summary>
    private void OnStartupOptionChanged(object sender, EventArgs e)
    {
        if (_startupOptionComboBox.SelectedItem != null)
        {
            string selectedOption = _startupOptionComboBox.SelectedItem.ToString();
            CPHLogger.LogI($"[{_sectionTitle}] Startup option changed to: {selectedOption}");
            MessageBox.Show($"[{_sectionTitle}] Startup option changed to: {selectedOption}", "Startup Behavior", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }
    }

    /// <summary>
    /// Handles changes in the Delay numeric control.
    /// </summary>
    private void OnDelayValueChanged(object sender, EventArgs e)
    {
        int delay = (int)_delayNumericUpDown.Value;
        CPHLogger.LogI($"[{_sectionTitle}] Startup delay set to: {delay} seconds");
        MessageBox.Show($"[{_sectionTitle}] Startup delay set to: {delay} seconds", "Startup Behavior", MessageBoxButtons.OK, MessageBoxIcon.Information);
    }

    /// <summary>
    /// Handles changes in the Blocking dropdown.
    /// </summary>
    private void OnBlockingOptionChanged(object sender, EventArgs e)
    {
        if (_blockingOptionComboBox.SelectedItem != null)
        {
            string selectedOption = _blockingOptionComboBox.SelectedItem.ToString();
            CPHLogger.LogI($"[{_sectionTitle}] Blocking option changed to: {selectedOption}");
            MessageBox.Show($"[{_sectionTitle}] Blocking option changed to: {selectedOption}", "Blocking Behavior", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }
    }
}


/// <summary>
/// Panel containing flow control buttons (e.g., Save, Close), centralized and resizable.
/// </summary>
public class FormsControlPanel : BaseConfigurationPanel
{
    private TableLayoutPanel _mainLayoutPanel; // Main layout to centralize the flow control panel
    private FlowLayoutPanel _flowControlButtonPanel; // Holds Save and Close buttons

    /// <summary>
    /// Initializes the FormsControlPanel with centralized Save and Close buttons.
    /// </summary>
    public FormsControlPanel()
    {
        CPHLogger.LogC("[S] FormsControlPanel: Initializing");

        // Create the main layout panel to centralize the flow control panel
        _mainLayoutPanel = new TableLayoutPanel
        {
            Dock = DockStyle.Fill, // Fill the parent control
            ColumnCount = 1, // Single column for central alignment
            RowCount = 1,    // Single row for flexibility
            AutoSize = true, // Adjust size based on content
            AutoSizeMode = AutoSizeMode.GrowAndShrink,
            BackColor = Constants.FormColour,
            Padding = new Padding(2), // Inner spacing
            Margin = new Padding(0)    // Outer spacing
        };

        // Create the FlowControl Panel for buttons
        _flowControlButtonPanel = new FlowLayoutPanel
        {
            FlowDirection = FlowDirection.LeftToRight, // Horizontal layout for buttons
            WrapContents = false,                     // Prevent wrapping
            AutoSize = true,                           // Adjust size dynamically
            AutoSizeMode = AutoSizeMode.GrowAndShrink, // Grow and shrink based on content
            Anchor = AnchorStyles.None,               // Centered explicitly
            Padding = new Padding(2),                 // Inner spacing between buttons
            BackColor = Constants.FormColour
        };

        // Add Save Button
        var saveButton = UIComponentFactory.CreateButton(
            "Save",
            Constants.ButtonStyle.FlowControl,
            (s, e) => MessageBox.Show("Configuration Saved!")
        );

        // Add Close Button
        var closeButton = UIComponentFactory.CreateButton(
            "Close",
            Constants.ButtonStyle.FlowControl,
            (s, e) => Application.Exit()
        );

        // Add buttons to the flow panel
        _flowControlButtonPanel.Controls.Add(saveButton);
        _flowControlButtonPanel.Controls.Add(closeButton);

        // Add the flow panel to the central cell of the main layout
        _mainLayoutPanel.Controls.Add(_flowControlButtonPanel, 0, 0);
        _mainLayoutPanel.SetCellPosition(_flowControlButtonPanel, new TableLayoutPanelCellPosition(0, 0));
        _mainLayoutPanel.SetColumnSpan(_flowControlButtonPanel, 1);
        _mainLayoutPanel.SetRowSpan(_flowControlButtonPanel, 1);

        // Add the main layout to the panel
        Controls.Add(_mainLayoutPanel);

        CPHLogger.LogC("[E] FormsControlPanel: Successfully Initialized with TableLayoutPanel & FlowLayoutPanel");
    }
}


/// <summary>
/// Centralized event handler for ListBox interactions.
/// </summary>
public static class ListBoxEventHandler
{
    /// <summary>
    /// Moves the selected item up by one position in the ListBox.
    /// </summary>
    public static void OnMoveItemUp(ListBox listBox)
    {
        if (listBox.SelectedItem == null || listBox.SelectedIndex <= 0)
        {
            CPHLogger.LogE("Cannot move item up. Invalid selection.");
            return;
        }

        int index = listBox.SelectedIndex;
        var item = listBox.SelectedItem;
        listBox.Items.RemoveAt(index);
        listBox.Items.Insert(index - 1, item);
        listBox.SelectedIndex = index - 1;
    }

    /// <summary>
    /// Moves the selected item down by one position in the ListBox.
    /// </summary>
    public static void OnMoveItemDown(ListBox listBox)
    {
        if (listBox.SelectedItem == null || listBox.SelectedIndex >= listBox.Items.Count - 1)
        {
            CPHLogger.LogE("Cannot move item down. Invalid selection.");
            return;
        }

        int index = listBox.SelectedIndex;
        var item = listBox.SelectedItem;
        listBox.Items.RemoveAt(index);
        listBox.Items.Insert(index + 1, item);
        listBox.SelectedIndex = index + 1;
    }

    public static void RemoveSelectedItem(ListBox listBox, string context)
    {
        if (listBox.SelectedItem == null)
        {
            CPHLogger.LogE("No item selected for removal.");
            return;
        }

        var removedItem = listBox.SelectedItem.ToString();
        listBox.Items.Remove(listBox.SelectedItem);
        MessageBox.Show($"Removed {context} item: {removedItem}");
    }
}

public class PathInputDialog : Form
{
    private TextBox pathTextBox;
    private Button okButton;
    private Button cancelButton;
    public string EnteredPath => pathTextBox.Text;

    private const string PlaceholderText = "Enter or paste the application path here";
    public PathInputDialog(Form ownerForm)
    {
        Text = "Enter Application Path";
        Width = 400;
        Height = 150;
        StartPosition = FormStartPosition.Manual;
        Location = new Point(ownerForm.Left + (ownerForm.Width - Width) / 2, ownerForm.Top + (ownerForm.Height - Height) / 2);
        Label promptLabel = new Label
        {
            Text = "Enter or paste the path of the application:",
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
        okButton = new Button
        {
            Text = "OK",
            Left = 220,
            Width = 75,
            Top = 70,
            DialogResult = DialogResult.OK,
        };
        cancelButton = new Button
        {
            Text = "Cancel",
            Left = 300,
            Width = 75,
            Top = 70,
            DialogResult = DialogResult.Cancel,
        };
        okButton.Click += (sender, e) =>
        {
            DialogResult = DialogResult.OK;
            Close();
        };
        cancelButton.Click += (sender, e) =>
        {
            DialogResult = DialogResult.Cancel;
            Close();
        };
        Controls.Add(promptLabel);
        Controls.Add(pathTextBox);
        Controls.Add(okButton);
        Controls.Add(cancelButton);
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

public class UIComponentFactory
{
    /// <summary>
    /// Creates and styles a NumericUpDown control.
    /// </summary>
    /// <param name = "width">The width of the NumericUpDown control.</param>
    /// <param name = "height">The height of the NumericUpDown control.</param>
    /// <param name = "minimum">The minimum value for the NumericUpDown control.</param>
    /// <param name = "maximum">The maximum value for the NumericUpDown control.</param>
    /// <param name = "defaultValue">The default value for the NumericUpDown control.</param>
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
    /// Creates a navigation panel with "Move Up" and "Move Down" buttons for a ListBox.
    /// </summary>
    /// <param name = "listBox">The target ListBox to apply navigation actions.</param>
    /// <param name = "target">The target the event will manipulate.</param>
    /// <returns>A FlowLayoutPanel with navigation buttons.</returns>
    public static FlowLayoutPanel CreateListBoxNavigation(ListBox listBox, string target)
    {
        // Log the creation of the navigation panel
        CPHLogger.LogV($"[CreateListBoxNavigation] Creating FlowLayoutPanel for: {target}");
        // Create the navigation panel
        var arrowPanel = UIComponentFactory.CreateFlowLayoutPanel(FlowDirection.LeftToRight, wrapContents: true, autoSize: true, margin: new Padding(0), anchor: AnchorStyles.Right | AnchorStyles.Top);
        // Add "Up" button
        var upButton = UIComponentFactory.CreateButton("▲", Constants.ButtonStyle.ArrowBtn, (s, e) =>
        {
            CPHLogger.LogV($"[{target}] Move Up button clicked.");
            ListBoxEventHandler.OnMoveItemUp(listBox);
        });
        var downButton = UIComponentFactory.CreateButton("▼", Constants.ButtonStyle.ArrowBtn, (s, e) =>
        {
            CPHLogger.LogV($"[{target}] Move Down button clicked.");
            ListBoxEventHandler.OnMoveItemDown(listBox);
        });
        // Add buttons to the panel
        arrowPanel.Controls.Add(upButton);
        arrowPanel.Controls.Add(downButton);
        // Log the successful creation
        CPHLogger.LogV($"[CreateListBoxNavigation] Navigation buttons added for: {target}");
        return arrowPanel;
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
            Margin = margin ?? new Padding(2, 0, 2, 0),
            Padding = padding ?? new Padding(1, 1, 1, 1),
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
                btn.Width = 120;
                btn.Margin = new Padding(1, 3, 1, 1);
                btn.Padding = new Padding(2, 2, 2, 2);
                btn.FlatAppearance.BorderSize = 1;
                btn.FlatAppearance.BorderColor = Constants.Border;
                break;
            case Constants.ButtonStyle.ArrowBtn:
                btn.Width = 26;
                btn.Height = 26;
                btn.Margin = new Padding(1, 3, 1, 0);
                btn.Padding = new Padding(0, 2, 0, 0);
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
            Margin = new Padding(50),
            Padding = new Padding(10),
            Font = font ?? new Font("Segoe UI", 10),
            ForeColor = Constants.PrimaryText,
            BackColor = Constants.FormColour
        };
        CPHLogger.LogV($"GroupBox created. Properties: Text=\"{title}\", Margin={groupBox.Margin}, Font={groupBox.Font}");
        return groupBox;
    }

    /// <summary>
    /// Creates and styles a ComboBox control.
    /// </summary>
    /// <param name = "items">A list of string items to populate the ComboBox.</param>
    /// <param name = "isDropDownList">If true, the ComboBox will be in DropDownList mode (prevents free text input).</param>
    /// <param name = "defaultSelectedIndex">The default selected index (if any).</param>
    /// <returns>A styled ComboBox control.</returns>
    public static ComboBox CreateComboBox(List<string> items, bool isDropDownList = true, int defaultSelectedIndex = 0, int? widthParam = null)
    {
        // Initialize the ComboBox
        var comboBox = new ComboBox
        {
            Dock = DockStyle.Fill,
            DropDownStyle = isDropDownList ? ComboBoxStyle.DropDownList : ComboBoxStyle.DropDown,
            Margin = new Padding(5),
            Font = new Font("Segoe UI", 10),
            ForeColor = Constants.PrimaryText,
            BackColor = Constants.FormColour,
            Width = widthParam ?? 150 // Default width is 150 if not specified
        };

        // Add items to the ComboBox
        if (items != null && items.Count > 0)
        {
            comboBox.Items.AddRange(items.ToArray());
        }

        // Set the default selected index, if valid
        if (defaultSelectedIndex >= 0 && defaultSelectedIndex < comboBox.Items.Count)
        {
            comboBox.SelectedIndex = defaultSelectedIndex;
        }

        // Log creation for debugging
        CPHLogger.LogV($"ComboBox created. Items: {string.Join(", ", items)}, Default Index: {defaultSelectedIndex}, Mode: {(isDropDownList ? "DropDownList" : "DropDown")}");
        return comboBox;
    }

    /// <summary>
    /// Factory for creating and styling FlowLayoutPanel controls.
    /// </summary>
    public static FlowLayoutPanel CreateFlowLayoutPanel(FlowDirection direction = FlowDirection.LeftToRight, bool wrapContents = true, bool autoSize = false, AnchorStyles anchor = AnchorStyles.Top | AnchorStyles.Left, Padding? margin = null)
    {
        var flowPanel = new FlowLayoutPanel
        {
            FlowDirection = direction,
            WrapContents = true,
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
            ForeColor = Constants.PrimaryText,
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

    public enum StartupBehaviorType
    {
        Application,
        Action
    }


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
        if (currentProcess == null)
            CPHLogger.LogE("Process object is null. Unable to log process details.");
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

/*************************************************Parent Classes**************************************************/
/*
** CLASS NAME: SelectItemsPanel [Last Updated: V2]
** Description: 
** A reusable, configurable panel for managing a list of items with common UI components such as ListBox, Add/Remove buttons, and navigation controls (Move Up/Down).
** Supports dynamic configuration for rows, columns, column spans, and row/column styles.
**
** Parameters: 
** sectionTitle: [IN][string] The title displayed in the GroupBox for this panel.
** items:        [IN][List<string>] Initial list of items to populate the ListBox.
** rows:         [IN][int][1] Number of rows in the layout.
** cols:         [IN][int][1] Number of columns in the layout.
**
** Methods:
** ConfigureLayoutStyles: Configures row and column styles for the layout panel.
** SetColumnSpans:        Sets specific column spans for controls in the layout.
** SetRowSpans:           Sets specific row spans for controls in the layout.
** AddCustomButtons:      Provides an overridable method for adding additional buttons.
** OnAddAction:           Handles the action when the "Add" button is clicked.
**
** Returns: [void]
*/
public class SelectItemsPanel : BaseConfigurationPanel
{
    // ListBox for displaying items
    protected readonly ListBox _itemsListBox;
    // Buttons for item manipulation
    protected readonly Button _addBtn;
    protected readonly Button _removeBtn;
    // Flow layout panels for controls
    protected readonly FlowLayoutPanel _buttonPanel;
    protected readonly FlowLayoutPanel _navigationPanel;
    // Table layout for organizing UI components
    protected TableLayoutPanel _layoutTable;
    /*
    ** Constructor: SelectItemsPanel
    ** Description:
    ** Initializes a SelectItemsPanel with specified rows, columns, and UI controls.
    **
    ** Parameters:
    ** sectionTitle: [IN][string] Title of the GroupBox containing this panel.
    ** items:        [IN][List<string>] Initial list of items to populate the ListBox.
    ** rows:         [IN][int][1] Number of rows in the layout table.
    ** cols:         [IN][int][1] Number of columns in the layout table.
    */
    public SelectItemsPanel(string sectionTitle, List<string> items, int rows = 1, int cols = 1)
    {
        CPHLogger.LogC("[S]SelectItemsPanel: Constructor");
        // Create a GroupBox to contain the layout
        var itemsGroupBox = UIComponentFactory.CreateGroupBox(sectionTitle);
        // Initialize the TableLayoutPanel with custom rows and columns
        _layoutTable = UIComponentFactory.CreateTableLayoutPanel(rows, cols);
        // Initialize ListBox and populate it with items
        CPHLogger.LogC("SelectItemsPanel: Initializing ListBox");
        _itemsListBox = UIComponentFactory.CreateListBox();
        foreach (var item in items)
        {
            _itemsListBox.Items.Add(item);
        }

        // Initialize Button Panel and buttons
        CPHLogger.LogC("SelectItemsPanel: Creating Button Panel");
        _buttonPanel = UIComponentFactory.CreateFlowLayoutPanel(direction: FlowDirection.LeftToRight, wrapContents: false, autoSize: true, anchor: AnchorStyles.Top | AnchorStyles.Left);
        
        _addBtn = UIComponentFactory.CreateButton("Add", Constants.ButtonStyle.Longer, OnAddAction);
        _removeBtn = UIComponentFactory.CreateButton("Remove", Constants.ButtonStyle.Longer, (s, e) => ListBoxEventHandler.RemoveSelectedItem(_itemsListBox, sectionTitle));
        _buttonPanel.Controls.Add(_addBtn);
        _buttonPanel.Controls.Add(_removeBtn);
        
        // Initialize Navigation Panel for Move Up/Down buttons
        CPHLogger.LogC("SelectItemsPanel: Creating Navigation Panel");
        _navigationPanel = UIComponentFactory.CreateListBoxNavigation(_itemsListBox, sectionTitle);
        
        // Add components to the TableLayoutPanel
        CPHLogger.LogC("SelectItemsPanel: Adding controls to layout table");
        _layoutTable.Controls.Add(_itemsListBox, 0, 0); // ListBox in first row
        _layoutTable.Controls.Add(_buttonPanel, 0, 1); // Button Panel in second row
        _layoutTable.Controls.Add(_navigationPanel, 0, 2); // Navigation Panel in third row
        
        // Add the TableLayoutPanel to the GroupBox
        itemsGroupBox.Controls.Add(_layoutTable);
        
        // Add the GroupBox to the UserControl
        Controls.Add(itemsGroupBox);
        CPHLogger.LogC("[E]SelectItemsPanel: Constructor");
    }

    /*
    ** Method: ConfigureLayoutStyles
    ** Description:
    ** Configures row and column styles for the TableLayoutPanel, enabling precise layout control.
    **
    ** Parameters:
    ** rowStyles:    [IN][List<RowStyle>] List of row styles to apply.
    ** columnStyles: [IN][List<ColumnStyle>] List of column styles to apply.
    **
    ** Returns: [SelectItemsPanel] Fluent API for chaining.
    */
    public SelectItemsPanel ConfigureLayoutStyles(List<RowStyle> rowStyles, List<ColumnStyle> columnStyles)
    {
        if (rowStyles != null)
        {
            _layoutTable.RowStyles.Clear();
            foreach (var style in rowStyles)
            {
                _layoutTable.RowStyles.Add(style);
            }
        }

        if (columnStyles != null)
        {
            _layoutTable.ColumnStyles.Clear();
            foreach (var style in columnStyles)
            {
                _layoutTable.ColumnStyles.Add(style);
            }
        }

        CPHLogger.LogC("SelectItemsPanel: Layout styles configured.");
        return this;
    }

    /*
    ** Method: SetColumnSpans
    ** Description:
    ** Sets custom column spans for specified controls in the layout table.
    **
    ** Parameters:
    ** columnSpans: [IN][Dictionary<Control, int>] Dictionary of controls and their column spans.
    **
    ** Returns: [SelectItemsPanel] Fluent API for chaining.
    */
    public SelectItemsPanel SetColumnSpans(Dictionary<Control, int> columnSpans)
    {
        foreach (var kvp in columnSpans)
        {
            if (_layoutTable.Controls.Contains(kvp.Key))
            {
                _layoutTable.SetColumnSpan(kvp.Key, kvp.Value);
                CPHLogger.LogV($"ColumnSpan set for {kvp.Key.GetType().Name} to {kvp.Value}");
            }
        }

        return this;
    }

    /*
    ** Method: SetRowSpans
    ** Description:
    ** Sets custom row spans for specified controls in the layout table.
    **
    ** Parameters:
    ** rowSpans: [IN][Dictionary<Control, int>] Dictionary of controls and their row spans.
    **
    ** Returns: [SelectItemsPanel] Fluent API for chaining.
    */
    public SelectItemsPanel SetRowSpans(Dictionary<Control, int> rowSpans)
    {
        foreach (var kvp in rowSpans)
        {
            if (_layoutTable.Controls.Contains(kvp.Key))
            {
                _layoutTable.SetRowSpan(kvp.Key, kvp.Value);
                CPHLogger.LogV($"RowSpan set for {kvp.Key.GetType().Name} to {kvp.Value}");
            }
        }

        return this;
    }

    /*
    ** Method: AddCustomButtons
    ** Description:
    ** Virtual method for adding custom buttons in derived classes.
    **
    ** Returns: [void]
    */
    protected virtual void AddCustomButtons()
    {
        // Overridable for derived classes
    }

    /*
    ** Method: ConfigureButtonPanel
    ** Description:
    ** Provides a way for derived classes to configure the `_buttonPanel` properties 
    ** after initialization, such as `FlowDirection`, wrapping behavior, and alignment.
    **
    ** Parameters:
    ** flowDirection: [IN][FlowDirection] Direction in which controls flow.
    ** wrapContents:  [IN][bool] Whether to wrap contents when they overflow.
    ** autoSize:      [IN][bool] Whether the panel adjusts size automatically.
    ** anchor:        [IN][AnchorStyles] How the panel is anchored.
    **
    ** Returns: [void]
    */
    protected void ConfigureButtonPanel(FlowDirection flowDirection = FlowDirection.LeftToRight, bool wrapContents = false, bool autoSize = true, AnchorStyles anchor = AnchorStyles.Top | AnchorStyles.Left)
    {
        if (_buttonPanel != null)
        {
            _buttonPanel.FlowDirection = flowDirection;
            _buttonPanel.WrapContents = wrapContents;
            _buttonPanel.AutoSize = autoSize;
            _buttonPanel.Anchor = anchor;
            CPHLogger.LogV($"Button Panel configured: FlowDirection={flowDirection}, WrapContents={wrapContents}, AutoSize={autoSize}, Anchor={anchor}");
        }
        else
        {
            CPHLogger.LogW("Button Panel is null. Configuration skipped.");
        }
    }

    /*
    ** Method: OnAddAction
    ** Description:
    ** Handles the "Add" button event, allowing users to add an item to the ListBox.
    **
    ** Parameters:
    ** sender: [IN][object] Event source.
    ** e:      [IN][EventArgs] Event arguments.
    */
    protected virtual void OnAddAction(object sender, EventArgs e)
    {
        using (var dialog = new PathInputDialog(FindForm()))
        {
            if (dialog.ShowDialog(this) == DialogResult.OK)
            {
                string actionName = dialog.EnteredPath;
                if (!string.IsNullOrWhiteSpace(actionName))
                {
                    _itemsListBox.Items.Add(actionName);
                    MessageBox.Show($"Action added: {actionName}");
                }
            }
        }
    }
}


public class ActionManagerForm : Form
{
    private ListBox actionListBox = new ListBox
    {
        Left = 20,
        Top = 20,
        Width = 400,
        Height = 300,
    };
    private Button addActionToListButton = new Button
    {
        Left = 430,
        Top = 20,
        Width = 120,
        Text = "Add Action",
    };
    private Button cancelAddButton = new Button
    {
        Left = 430,
        Top = 60,
        Width = 120,
        Text = "Cancel",
    };
    private List<ActionData> actionDataList;

    public string SelectedAction { get; private set; }

    public ActionManagerForm(List<ActionData> actionData)
    {
        this.Text = "Actions To Manage";
        this.Width = 600;
        this.Height = 400;
        this.Controls.Add(actionListBox);
        this.Controls.Add(addActionToListButton);
        this.Controls.Add(cancelAddButton);

        // Initialize actionDataList with the passed-in actionData
        actionDataList = actionData;

        addActionToListButton.Click += AddActionToListButton_Click;
        cancelAddButton.Click += CancelButton_Click;
        LoadActions();
    }

    private void LoadActions()
    {
        // Clear the action list box and populate it with actions
        actionListBox.Items.Clear(); // Clear previous items

        // Loop through each action in the list and display it
        foreach (var action in actionDataList)
        {
            // Format the display string for each action
            string actionDisplay = $"{action.Name} - {(action.Enabled ? "Enabled" : "Disabled")}";
            actionListBox.Items.Add(actionDisplay); // Add to the list box
        }
    }

    private void AddActionToListButton_Click(object sender, EventArgs e)
    {
        if (actionListBox.SelectedItem != null)
        {
            string selectedActionDisplay = actionListBox.SelectedItem.ToString();
            SelectedAction = selectedActionDisplay.Split('-')[0].Trim(); // Extract the action name

            // Close the form and set DialogResult to OK
            DialogResult = DialogResult.OK;
            Close();
        }
        else
        {
            MessageBox.Show(
                "Please select an action to add.",
                "Selection Required",
                MessageBoxButtons.OK,
                MessageBoxIcon.Warning
            );
        }
    }


    public class ApplicationData
    {
        public string Name { get; set; }
        public string Path { get; set; }

        public ApplicationData(string name, string path)
        {
            Name = name;
            Path = path;
        }
    }



    private void CancelButton_Click(object sender, EventArgs e)
    {
        Close();
    }

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




public class BaseConfigurationPanel : UserControl
{
    public BaseConfigurationPanel()
    {
        Dock = DockStyle.Fill;
        AutoSize = true;
        AutoSizeMode = AutoSizeMode.GrowAndShrink;
        Padding = new Padding(0, 0, 0, 0);
        Margin = new Padding(5, 2, 5, 15);
        CPHLogger.LogV($"BaseConfigurationPanel layout settings applied");
    }
}


/// <summary>
/// A base class that serves as a foundation for shared resources or functionality.
/// </summary>
public class SB
{
    public static IInlineInvokeProxy CPH;
    public static Dictionary<string, object> args;

    /// <summary>
    /// Retrieves a list of actions from Streamer.bot.
    /// </summary>
    public static List<ActionData> GetActions()
    {
        return CPH.GetActions();
    }

}