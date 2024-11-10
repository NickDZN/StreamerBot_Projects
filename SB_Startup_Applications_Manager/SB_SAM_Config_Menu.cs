using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
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
        // Attempt to get the handle of the currently active window
        IntPtr activeWindowHandle = GetForegroundWindow();

        // Check if the window was found
        if (activeWindowHandle == IntPtr.Zero)
        {
            MessageBox.Show("No active window found.");
            return false;
        }

        // Get the window title
        StringBuilder windowTitle = new StringBuilder(256);
        GetWindowText(activeWindowHandle, windowTitle, windowTitle.Capacity);

        // Get the dimensions of the active window
        if (!GetWindowRect(activeWindowHandle, out Rectangle activeWindowRect))
        {
            MessageBox.Show("Failed to get window dimensions.");
            return false;
        }

        // Enable visual styles for the application
        Application.EnableVisualStyles();

        // Load the global action list
        List<ActionData> actionList = CPH.GetActions();

        // Create an instance of StartupConfigForm, passing the dimensions of the active window
        if (mainFormInstance == null || mainFormInstance.IsDisposed)
        {
            // Create a new instance of StartupConfigForm if no form is open
            mainFormInstance = new LoadStartupConfigForm(activeWindowRect, actionList); // Pass the global actions list
            Application.Run(mainFormInstance);
        }
        else
        {
            // Bring the existing form instance to the front
            mainFormInstance.BringToFront();
        }

        return true;
    }
}

public class LoadStartupConfigForm : Form
{
    private List<ActionData> actionDataList;

    //SB_SAM Startup Configuration Buttons. 
    private RadioButton radioStartupConfigYes = new RadioButton {Text = "Yes", AutoSize = true, Dock = DockStyle.Fill, TextAlign = ContentAlignment.MiddleLeft};
    private RadioButton radioStartupConfigNo = new RadioButton {Text = "No", AutoSize = true, Dock = DockStyle.Fill, TextAlign = ContentAlignment.MiddleLeft};
    private RadioButton radioStartupConfigPrompt = new RadioButton {Text = "Prompt", AutoSize = true, Dock = DockStyle.Fill, TextAlign = ContentAlignment.MiddleLeft};
    private Label lblStartupConfigDelay = new Label {Text = "Delay (In seconds)", AutoSize = true, Dock = DockStyle.Fill, TextAlign = ContentAlignment.MiddleLeft};
    private NumericUpDown numupdwnStartupConfigDelay = new NumericUpDown {
        Width = 40,
        Minimum = 0,
        Maximum = 30,
        Value = 2,
        Anchor = AnchorStyles.Left,
        Margin = new Padding(2, 0, 0, 0)
    };

    // Application Start-up IO's.
    private ListBox lstApplications = new ListBox {Width = 250, Height = 100};
    private Button btnAddApplication = new Button {Width = 120, Text = "Add Application"};
    private Button btnAddApplicationPath = new Button {Width = 120, Text = "Add Path"};
    private Button btnRemoveApplication = new Button {Width = 120, Text = "Remove Application", Enabled = false};

    // Actions Startup Permitted IO's
    private ListBox lstActionsPermitted = new ListBox {Width = 250, Height = 100};
    private Button btnAddActionPermitted = new Button {Width = 120, Text = "Add Action"};
    private Button btnRemoveActionPermitted = new Button {Width = 120, Text = "Remove Action", Enabled = false};

    // Actions Startup Blocked IO's
    private ListBox lstActionsBlocked = new ListBox {Width = 250, Height = 100};
    private Button btnAddActionBlocked = new Button {Width = 120, Text = "Add Action"};
    private Button btnRemoveActionBlocked = new Button {Width = 120, Text = "Remove Action", Enabled = false};
    
    //User Settings Controls
    private Button btnResetAllSettings = new Button { Width = 80, Text = "Remove All" };
    private Button btnImportSettings = new Button { Width = 80, Text = "Import" };
    private Button btnExportSettings = new Button { Width = 80, Text = "Export" };
    
    // Main Form Controls. 
    private Button btnSaveForm = new Button { Width = 90, Text = "Save", Enabled = false };
    private Button btnCloseForm = new Button { Width = 90, Text = "Close" };
    private Button btnShowAbout = new Button { Width = 80, Text = "About" };
    private Button btnTestConfig = new Button { Width = 80, Text = "Test" };

    // Tooltips.     
    private ToolTip toolTip = new ToolTip();

    public LoadStartupConfigForm(Rectangle activeWindowRect, List<ActionData> actions) {
        // Locally store list of actions. 
        actionDataList = actions;

        // Set up the main layout panel
        var mainLayoutPanel = BuildCoreForm(activeWindowRect);

        // Add User Controls
        AddConfigurationControls(mainLayoutPanel);

        // Add the list box sections. 
        AddApplicationControls(mainLayoutPanel);
        AddActionControls(mainLayoutPanel, "Actions to run at startup", lstActionsPermitted, btnAddActionPermitted, btnRemoveActionPermitted, AddActionPermitted_SelIndhanged, AddActionPermitted_Click, RemoveActionPermitted_Click);
        AddActionControls(mainLayoutPanel, "Actions to block running at startup", lstActionsBlocked, btnAddActionBlocked, btnRemoveActionBlocked, AddActionBlocked_SelIndhanged, AddActionBlocked_Click, RemoveActionBlocked_Click);

        // Add the options buttons. 
        AddStartupConfigurationControls(mainLayoutPanel);

        // Add the control buttons. 
        AddApplicationControlButtons(mainLayoutPanel);
    }

    private TableLayoutPanel BuildCoreForm(Rectangle activeWindowRect) {
        
        // Configure the form properties
        this.Text = "Startup Manager";
        this.Width = 500;
        this.Height = 700;

        // Center the form based on the active window's position
        int centerX = activeWindowRect.Left + (activeWindowRect.Width - this.Width) / 2;
        int centerY = activeWindowRect.Top + (activeWindowRect.Height - this.Height) / 2;
        this.Location = new Point(centerX, centerY);
        this.TopMost = true;

        // Create the main layout panel
        TableLayoutPanel mainLayoutPanel = new TableLayoutPanel {
            Dock = DockStyle.Fill,
            ColumnCount = 1,
            RowCount = 6,
            Padding = new Padding(10),
            AutoSize = true,
            AutoSizeMode = AutoSizeMode.GrowAndShrink
        };

        // Add main layout panel to form controls
        this.Controls.Add(mainLayoutPanel);
        return mainLayoutPanel;
    }


    private void AddConfigurationControls(TableLayoutPanel mainLayoutPanel) {
        
        // 2. Settings Buttons Panel
        TableLayoutPanel settingsPanel = new TableLayoutPanel {
            ColumnCount = 5,
            RowCount = 2,
            AutoSize = true,
            AutoSizeMode = AutoSizeMode.GrowAndShrink
        };

        Label configurationControlLabel = new Label { Text = "Manage your configuration", AutoSize = true };

        settingsPanel.Controls.Add(configurationControlLabel, 0, 0);
        settingsPanel.SetColumnSpan(configurationControlLabel, 2);

        settingsPanel.Controls.Add(btnResetAllSettings, 0, 1);
        settingsPanel.Controls.Add(btnImportSettings, 1, 1);
        settingsPanel.Controls.Add(btnExportSettings, 2, 1);
        settingsPanel.Controls.Add(btnShowAbout, 3, 1);
        settingsPanel.Controls.Add(btnTestConfig, 4, 1);

        btnResetAllSettings.Click += MainCanvasCloseButton_Click;
        btnImportSettings.Click += MainCanvasCloseButton_Click;
        btnExportSettings.Click += MainCanvasCloseButton_Click;
        btnShowAbout.Click += MainCanvasCloseButton_Click;
        btnTestConfig.Click += MainCanvasCloseButton_Click;                                

        mainLayoutPanel.Controls.Add(settingsPanel);
    }

    // Flow control. Save and exit buttons. 
    //ToDo: Centralise buttons to the bottom. 
    private void AddApplicationControlButtons(TableLayoutPanel mainLayoutPanel) { 
        
        // Define Layout. 
        TableLayoutPanel controlButtonsPanel = new TableLayoutPanel {
            ColumnCount = 2,
            AutoSize = true,
            AutoSizeMode = AutoSizeMode.GrowAndShrink,
            Dock = DockStyle.Bottom
        };

        // Add Buttons. 
        controlButtonsPanel.Controls.Add(btnSaveForm, 0, 0);
        controlButtonsPanel.Controls.Add(btnCloseForm, 1, 0);

        // Add event triggers. 
        btnSaveForm.Click += MainCanvasSaveButton_Click;
        btnCloseForm.Click += MainCanvasCloseButton_Click;

        // Add to Canvas.
        mainLayoutPanel.Controls.Add(controlButtonsPanel);
    }

    // Application list and controls. 
    private void AddApplicationControls(TableLayoutPanel mainLayoutPanel) {
        TableLayoutPanel applicationsPanel = new TableLayoutPanel {
            ColumnCount = 2,
            AutoSize = true,
            AutoSizeMode = AutoSizeMode.GrowAndShrink,
            Padding = new Padding(0, 10, 0, 10)
        };

        lstApplications.Width = 300;
        applicationsPanel.Controls.Add(new Label { Text = "Applications to run at startup", AutoSize = true }, 0, 0);
        applicationsPanel.Controls.Add(lstApplications, 0, 1);
        applicationsPanel.SetRowSpan(lstApplications, 2);

        // Buttons for application list
        TableLayoutPanel appButtons = new TableLayoutPanel { ColumnCount = 1, AutoSize = true };
        appButtons.Controls.Add(btnAddApplication);
        appButtons.Controls.Add(btnRemoveApplication);
        appButtons.Controls.Add(btnAddApplicationPath);

        // Handle selecting an item event. 
        lstApplications.SelectedIndexChanged += ApplicationListBox_SelectedIndexChanged; 

        // Handle buttons clicked events.
        btnAddApplication.Click += AddApplication_Click;
        btnAddApplicationPath.Click += AddApplicationPath_Click;
        btnRemoveApplication.Click += RemoveApplication_Click;

        // Display Canvas.
        applicationsPanel.Controls.Add(appButtons, 1, 1);
        mainLayoutPanel.Controls.Add(applicationsPanel);
    }

    //Actions allowed list and controls. 
    private void AddActionControls(TableLayoutPanel mainLayoutPanel, string title, ListBox listBox, Button addButton, Button removeButton, EventHandler ListBoxSelected, EventHandler addButtonClick, EventHandler removeButtonClick) {
        
        TableLayoutPanel actionsPanel = new TableLayoutPanel {
            ColumnCount = 2,
            AutoSize = true,
            AutoSizeMode = AutoSizeMode.GrowAndShrink,
            Padding = new Padding(0, 10, 0, 10)
        };

        // Configure Objects. 
        actionsPanel.Controls.Add(new Label { Text = title, AutoSize = true }, 0, 0);
        actionsPanel.Controls.Add(listBox, 0, 1);
        actionsPanel.SetRowSpan(listBox, 2);
        listBox.Width = 300;

        // Add Objects
        TableLayoutPanel actionButtons = new TableLayoutPanel { ColumnCount = 1, AutoSize = true };
        actionButtons.Controls.Add(addButton);
        actionButtons.Controls.Add(removeButton);

        listBox.SelectedIndexChanged += ListBoxSelected; 

        addButton.Click += addButtonClick; 
        removeButton.Click += removeButtonClick; 

        // Add table to canvas. . 
        actionsPanel.Controls.Add(actionButtons, 1, 1);

        // Finalise. 
        mainLayoutPanel.Controls.Add(actionsPanel);
    }

    private void AddStartupConfigurationControls(TableLayoutPanel mainLayoutPanel) {
        // Create a GroupBox to hold the startup options section
        GroupBox startupOptionsGroup = new GroupBox {
            Text = "Load Applications on Startup",
            Width = 400,
            Height = 80
        };

        // Create a TableLayoutPanel with 3 columns and 2 rows to align options
        TableLayoutPanel startupOptionsPanel = new TableLayoutPanel {
            ColumnCount = 3,
            RowCount = 6,
            Dock = DockStyle.Fill,
            AutoSize = true,
            AutoSizeMode = AutoSizeMode.GrowAndShrink,
            //CellBorderStyle = TableLayoutPanelCellBorderStyle.Single
        };

        // Define column styles for alignment
        startupOptionsPanel.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 60));
        startupOptionsPanel.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 60));
        startupOptionsPanel.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));

        // Add radio buttons to the first row
        startupOptionsPanel.Controls.Add(radioStartupConfigYes, 0, 0);    
        startupOptionsPanel.Controls.Add(radioStartupConfigNo, 1, 0);     
        startupOptionsPanel.Controls.Add(radioStartupConfigPrompt, 2, 0); 

        // Add the delay label to the second row, spanning the first two columns
        startupOptionsPanel.Controls.Add(lblStartupConfigDelay, 4, 0);

        // Add the delay input control to the second row, third column
        startupOptionsPanel.Controls.Add(numupdwnStartupConfigDelay, 5, 0);

        // Add the TableLayoutPanel to the GroupBox
        startupOptionsGroup.Controls.Add(startupOptionsPanel);

        // Add the GroupBox to the main layout panel
        mainLayoutPanel.Controls.Add(startupOptionsGroup);
    }



    private void AddApplication_Click(object sender, EventArgs e)
    {
        // Run the file dialog in a separate thread
        Thread fileDialogThread = new Thread(() => {
            try {
                using (OpenFileDialog fileDialog = new OpenFileDialog()) {
                    fileDialog.Filter = "Executable Files (*.exe)|*.exe|All Files (*.*)|*.*";
                    fileDialog.Title = "Select an Application File";

                    if (fileDialog.ShowDialog(this) == DialogResult.OK) {
                        string selectedFile = fileDialog.FileName;
                        this.Invoke(
                            new Action(() => {
                                if (!lstApplications.Items.Contains(selectedFile)) {
                                    lstApplications.Items.Add(selectedFile);
                                    btnSaveForm.Enabled = true;
                                }
                                else {
                                    MessageBox.Show("This application file has already been added.");
                                }
                            })
                        );
                    }
                }
            }
            catch (Exception ex) {
                MessageBox.Show($"An error occurred while selecting the file:\n{ex.Message}");
            }
        });

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
                            lstApplications.Items.Add(pathToAdd);
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

    private void RemoveApplication_Click(object sender, EventArgs e) {
        if (lstApplications.SelectedItem != null) {
            lstApplications.Items.Remove(lstApplications.SelectedItem);
            btnSaveForm.Enabled = true;
        }
    }

    private void ApplicationListBox_SelectedIndexChanged(object sender, EventArgs e) {
        btnRemoveApplication.Enabled = lstApplications.SelectedItem != null;
    }

    private void AddActionPermitted_SelIndhanged(object sender, EventArgs e) {
        btnRemoveActionPermitted.Enabled = lstActionsPermitted.SelectedItem != null;
    }

    private void AddActionPermitted_Click(object sender, EventArgs e) {
        using (ActionManagerForm actionManagerDialog = new ActionManagerForm(actionDataList)) {
            if (actionManagerDialog.ShowDialog(this) == DialogResult.OK) {
                string selectedAction = actionManagerDialog.SelectedAction; 
                if (!string.IsNullOrWhiteSpace(selectedAction)) {
                    lstActionsPermitted.Items.Add(selectedAction);
                    btnSaveForm.Enabled = true;
                }
            }
        }
    }

    private void RemoveActionPermitted_Click(object sender, EventArgs e) {
        if (lstActionsPermitted.SelectedItem != null) {
            lstActionsPermitted.Items.Remove(lstActionsPermitted.SelectedItem);
            btnSaveForm.Enabled = true;
        }
    }

    private void AddActionBlocked_SelIndhanged(object sender, EventArgs e) {
        btnRemoveActionBlocked.Enabled = lstActionsBlocked.SelectedItem != null;
    }

    private void AddActionBlocked_Click(object sender, EventArgs e) {
        using (ActionManagerForm actionManagerDialog = new ActionManagerForm(actionDataList)) {
            if (actionManagerDialog.ShowDialog(this) == DialogResult.OK) {
                string selectedAction = actionManagerDialog.SelectedAction; 
                if (!string.IsNullOrWhiteSpace(selectedAction)) {
                    lstActionsBlocked.Items.Add(selectedAction);
                    btnSaveForm.Enabled = true;
                }
            }
        }
    }

    private void RemoveActionBlocked_Click(object sender, EventArgs e) {
        if (lstActionsBlocked.SelectedItem != null) {
            lstActionsBlocked.Items.Remove(lstActionsBlocked.SelectedItem);
            btnSaveForm.Enabled = true;
        }
    }

    private void ResetConfig_Click(object sender, EventArgs e) {
        DialogResult result = MessageBox.Show(
            "Are you sure you want to reset the configuration?",
            "Confirm Reset",
            MessageBoxButtons.YesNo,
            MessageBoxIcon.Warning
        );

        if (result == DialogResult.Yes) {
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

    private void MainCanvasSaveButton_Click(object sender, EventArgs e) {
        MessageBox.Show("Configuration saved!");
        btnSaveForm.Enabled = false;
    }

    private void MainCanvasCloseButton_Click(object sender, EventArgs e) {
        this.Close();
    }
}

public class PathInputDialog : Form {
    private TextBox pathTextBox;
    private Button btnPidOkay;
    private Button btnPidCancel;
    public string EnteredPath => pathTextBox.Text;
    private const string PlaceholderText = "Enter or paste the application path here";

    public PathInputDialog(Form ownerForm) {
        Text = "Enter Application Path";
        Width = 400;
        Height = 150;

        StartPosition = FormStartPosition.Manual;
        Location = new Point (
            ownerForm.Left + (ownerForm.Width - Width) / 2,
            ownerForm.Top + (ownerForm.Height - Height) / 2
        );

        Label promptLabel = new Label {
            Text = "Enter the path of the application:",
            Left = 10,
            Top = 10,
            Width = 360,
        };

        pathTextBox = new TextBox {
            Left = 10,
            Top = 40,
            Width = 360,
            ForeColor = Color.Gray,
            Text = PlaceholderText,
        };

        // Set up placeholder events
        pathTextBox.GotFocus += RemovePlaceholder;
        pathTextBox.LostFocus += SetPlaceholder;

        btnPidOkay = new Button {Text = "OK", Left = 220, Width = 75, Top = 70, DialogResult = DialogResult.OK, };
        btnPidCancel = new Button {Text = "Cancel", Left = 300, Width = 75, Top = 70, DialogResult = DialogResult.Cancel, };

        btnPidOkay.Click += (sender, e) => {
            DialogResult = DialogResult.OK;
            Close();
        };

        btnPidCancel.Click += (sender, e) => {
            DialogResult = DialogResult.Cancel;
            Close();
        };

        Controls.Add(promptLabel);
        Controls.Add(pathTextBox);
        Controls.Add(btnPidOkay);
        Controls.Add(btnPidCancel);
    }

    private void RemovePlaceholder(object sender, EventArgs e) {
        if (pathTextBox.Text == PlaceholderText) {
            pathTextBox.Text = "";
            pathTextBox.ForeColor = Color.Black;
        }
    }

    private void SetPlaceholder(object sender, EventArgs e) {
        if (string.IsNullOrWhiteSpace(pathTextBox.Text)) {
            pathTextBox.Text = PlaceholderText;
            pathTextBox.ForeColor = Color.Gray;
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
            MessageBox.Show("Please select an action to add.", "Selection Required", MessageBoxButtons.OK, MessageBoxIcon.Warning);
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