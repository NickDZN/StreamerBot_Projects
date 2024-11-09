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
    private RadioButton sbsamStartupConfigRBYes = new RadioButton {Text = "Yes", AutoSize = true, Dock = DockStyle.Fill, TextAlign = ContentAlignment.MiddleLeft};
    private RadioButton sbsamStartupConfigRBNo = new RadioButton {Text = "No", AutoSize = true, Dock = DockStyle.Fill, TextAlign = ContentAlignment.MiddleLeft};
    private RadioButton sbsamStartupConfigRBPrompt = new RadioButton {Text = "Prompt", AutoSize = true, Dock = DockStyle.Fill, TextAlign = ContentAlignment.MiddleLeft};
    private Label sbsamStartupConfigDelayLabel = new Label {Text = "Delay (In seconds)", AutoSize = true, Dock = DockStyle.Fill, TextAlign = ContentAlignment.MiddleLeft};
    private NumericUpDown sbsamStartupConfigDelayInput = new NumericUpDown {
        Width = 40,
        Minimum = 0,
        Maximum = 30,
        Value = 2,
        Anchor = AnchorStyles.Left,
        Margin = new Padding(2, 0, 0, 0)
    };

    // Application Start-up IO's.
    private ListBox applicationsListBox = new ListBox {Width = 250, Height = 100};
    private Button applicationsAddButton = new Button {Width = 120, Text = "Add Application"};
    private Button applicationsAddPathButton = new Button {Width = 120, Text = "Add Path"};
    private Button applicationsRemoveButton = new Button {Width = 120, Text = "Remove Application", Enabled = false};

    // Actions Startup Permitted IO's
    private ListBox actionsPermittedListBox = new ListBox {Width = 250, Height = 100};
    private Button actionsPermittedButtonAdd = new Button {Width = 120, Text = "Add Action"};
    private Button actionsPermittedButtonRemove = new Button {Width = 120, Text = "Remove Action", Enabled = false};

    // Actions Startup Blocked IO's
    private ListBox actionsBlockedListBox = new ListBox {Width = 250, Height = 100};
    private Button actionsBlockedButtonAdd = new Button {Width = 120, Text = "Add Action"};
    private Button actionsBlockedButtonRemove = new Button {Width = 120, Text = "Remove Action", Enabled = false};
    
    //User Settings Controls
    private Button sbsamOptionsResetAll = new Button { Width = 80, Text = "Remove All" };
    private Button sbsamOptionsImport = new Button { Width = 80, Text = "Import" };
    private Button sbsamOptionsExport = new Button { Width = 80, Text = "Export" };
    
    // Main Form Controls. 
    private Button sbsamControlSaveButton = new Button { Width = 90, Text = "Save", Enabled = false };
    private Button sbsamControlCloseButton = new Button { Width = 90, Text = "Close" };
    private Button sbsamControlAbout = new Button { Width = 80, Text = "About" };
    private Button sbsamControlTest = new Button { Width = 80, Text = "Test" };

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
        AddActionControls(mainLayoutPanel, "Actions to run at startup", actionsPermittedListBox, actionsPermittedButtonAdd, actionsPermittedButtonRemove);
        AddActionControls(mainLayoutPanel, "Actions to block running at startup", actionsBlockedListBox, actionsBlockedButtonAdd, actionsBlockedButtonRemove);

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

        settingsPanel.Controls.Add(sbsamOptionsResetAll, 0, 1);
        settingsPanel.Controls.Add(sbsamOptionsImport, 1, 1);
        settingsPanel.Controls.Add(sbsamOptionsExport, 2, 1);
        settingsPanel.Controls.Add(sbsamControlAbout, 3, 1);
        settingsPanel.Controls.Add(sbsamControlTest, 4, 1);

        sbsamOptionsResetAll.Click += MainCanvasCloseButton_Click;
        sbsamOptionsImport.Click += MainCanvasCloseButton_Click;
        sbsamOptionsExport.Click += MainCanvasCloseButton_Click;
        sbsamControlAbout.Click += MainCanvasCloseButton_Click;
        sbsamControlTest.Click += MainCanvasCloseButton_Click;                                

        mainLayoutPanel.Controls.Add(settingsPanel);
    }

    private void AddApplicationControlButtons(TableLayoutPanel mainLayoutPanel) { 
        
        // Define Layout. 
        TableLayoutPanel controlButtonsPanel = new TableLayoutPanel {
            ColumnCount = 2,
            AutoSize = true,
            AutoSizeMode = AutoSizeMode.GrowAndShrink,
            Dock = DockStyle.Bottom
        };

        // Add Buttons. 
        controlButtonsPanel.Controls.Add(sbsamControlSaveButton, 0, 0);
        controlButtonsPanel.Controls.Add(sbsamControlCloseButton, 1, 0);

        // Add event triggers. 
        sbsamControlSaveButton.Click += MainCanvasSaveButton_Click;
        sbsamControlCloseButton.Click += MainCanvasCloseButton_Click;

        // Add to Canvas.
        mainLayoutPanel.Controls.Add(controlButtonsPanel);
    }

    private void AddApplicationControls(TableLayoutPanel mainLayoutPanel) {
        TableLayoutPanel applicationsPanel = new TableLayoutPanel {
            ColumnCount = 2,
            AutoSize = true,
            AutoSizeMode = AutoSizeMode.GrowAndShrink,
            Padding = new Padding(0, 10, 0, 10)
        };

        applicationsListBox.Width = 300;
        applicationsPanel.Controls.Add(new Label { Text = "Applications to run at startup", AutoSize = true }, 0, 0);
        applicationsPanel.Controls.Add(applicationsListBox, 0, 1);
        applicationsPanel.SetRowSpan(applicationsListBox, 2);

        // Buttons for application list
        TableLayoutPanel appButtons = new TableLayoutPanel { ColumnCount = 1, AutoSize = true };
        appButtons.Controls.Add(applicationsAddButton);
        appButtons.Controls.Add(applicationsRemoveButton);
        appButtons.Controls.Add(applicationsAddPathButton);

        // Handle selecting an item event. 
        applicationsListBox.SelectedIndexChanged += ApplicationListBox_SelectedIndexChanged; 

        // Handle buttons clicked events.
        applicationsAddButton.Click += AddApplication_Click;
        applicationsAddPathButton.Click += EnterPathButton_Click;
        applicationsRemoveButton.Click += RemoveApplication_Click;

        // Display Canvas.
        applicationsPanel.Controls.Add(appButtons, 1, 1);
        mainLayoutPanel.Controls.Add(applicationsPanel);
    }

    private void AddActionControls(TableLayoutPanel mainLayoutPanel, string title, ListBox listBox, Button addButton, Button removeButton) {
        
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

        // Add table to canvas. . 
        actionsPanel.Controls.Add(actionButtons, 1, 1);

        // Finalise. 
        mainLayoutPanel.Controls.Add(actionsPanel);
    }

    private void AddStartupConfigurationControls(TableLayoutPanel mainLayoutPanel) {
        // Create a GroupBox to hold the startup options section
        GroupBox startupOptionsGroup = new GroupBox
        {
            Text = "Load Applications on Startup",
            Width = 400,
            Height = 80
        };

        // Create a TableLayoutPanel with 3 columns and 2 rows to align options
        TableLayoutPanel startupOptionsPanel = new TableLayoutPanel
        {
            ColumnCount = 3,
            RowCount = 6,
            Dock = DockStyle.Fill,
            AutoSize = true,
            AutoSizeMode = AutoSizeMode.GrowAndShrink,
            //CellBorderStyle = TableLayoutPanelCellBorderStyle.Single
        };

        // Define column styles for alignment
        startupOptionsPanel.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 60)); // Fixed width for the first column
        startupOptionsPanel.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 60)); // Fixed width for the second column
        startupOptionsPanel.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));  // Remaining space for the third column

        // Add radio buttons to the first row
        startupOptionsPanel.Controls.Add(sbsamStartupConfigRBYes, 0, 0);    // Column 0, Row 0
        startupOptionsPanel.Controls.Add(sbsamStartupConfigRBNo, 1, 0);     // Column 1, Row 0
        startupOptionsPanel.Controls.Add(sbsamStartupConfigRBPrompt, 2, 0); // Column 2, Row 0

        // Add the delay label to the second row, spanning the first two columns
        startupOptionsPanel.Controls.Add(sbsamStartupConfigDelayLabel, 4, 0);

        // Add the delay input control to the second row, third column
        startupOptionsPanel.Controls.Add(sbsamStartupConfigDelayInput, 5, 0);

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
                                if (!applicationsListBox.Items.Contains(selectedFile)) {
                                    applicationsListBox.Items.Add(selectedFile);
                                    sbsamControlSaveButton.Enabled = true;
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

    private void EnterPathButton_Click(object sender, EventArgs e)
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
                        if (!applicationsListBox.Items.Contains(pathToAdd))
                        {
                            applicationsListBox.Items.Add(pathToAdd);
                            sbsamControlSaveButton.Enabled = true;
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
        if (applicationsListBox.SelectedItem != null) {
            applicationsListBox.Items.Remove(applicationsListBox.SelectedItem);
            sbsamControlSaveButton.Enabled = true;
        }
    }

    private void AddAction_Click(object sender, EventArgs e)
    {
        // Open the action manager form and pass the global action list
        using (ActionManagerForm actionManagerDialog = new ActionManagerForm(actionDataList)) // Pass the actions
        {
            if (actionManagerDialog.ShowDialog(this) == DialogResult.OK)
            {
                string selectedAction = actionManagerDialog.SelectedAction; // Get the selected action
                if (!string.IsNullOrWhiteSpace(selectedAction))
                {
                    actionsPermittedListBox.Items.Add(selectedAction); // Add action to the list box
                    sbsamControlSaveButton.Enabled = true; // Enable save button
                }
            }
        }
    }

    private void RemoveAction_Click(object sender, EventArgs e)
    {
        if (actionsPermittedListBox.SelectedItem != null) {
            actionsPermittedListBox.Items.Remove(actionsPermittedListBox.SelectedItem);
            sbsamControlSaveButton.Enabled = true;
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
            applicationsListBox.Items.Clear();
            actionsPermittedListBox.Items.Clear();
            sbsamStartupConfigRBYes.Checked = false;
            sbsamStartupConfigRBNo.Checked = false;
            sbsamStartupConfigRBPrompt.Checked = true;
            sbsamControlSaveButton.Enabled = false;
            applicationsRemoveButton.Enabled = false;
            actionsPermittedButtonRemove.Enabled = false;
        }
    }

    private void MainCanvasSaveButton_Click(object sender, EventArgs e) {
        MessageBox.Show("Configuration saved!");
        sbsamControlSaveButton.Enabled = false;
    }

    private void MainCanvasCloseButton_Click(object sender, EventArgs e) {
        this.Close();
    }

    private void ApplicationListBox_SelectedIndexChanged(object sender, EventArgs e) {
        applicationsRemoveButton.Enabled = applicationsListBox.SelectedItem != null;
    }

    private void ActionListBox_SelectedIndexChanged(object sender, EventArgs e)
    {
        actionsPermittedButtonRemove.Enabled = actionsPermittedListBox.SelectedItem != null;
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
        Location = new Point(
            ownerForm.Left + (ownerForm.Width - Width) / 2,
            ownerForm.Top + (ownerForm.Height - Height) / 2
        );

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