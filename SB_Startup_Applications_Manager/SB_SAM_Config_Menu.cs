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

    private static StartupConfigForm mainFormInstance = null;

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
            mainFormInstance = new StartupConfigForm(activeWindowRect, actionList); // Pass the global actions list
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

public class StartupConfigForm : Form
{
    private List<ActionData> actionDataList; 

    // Table Layouts to help with alignment.
    private TableLayoutPanel sbsam_layoutGroup = new TableLayoutPanel {
        ColumnCount = 5,
        RowCount = 1, 
        Dock = DockStyle.None, 
        AutoSize = true,
        AutoSizeMode = AutoSizeMode.GrowAndShrink,
        Padding = new Padding(2),
        CellBorderStyle = TableLayoutPanelCellBorderStyle.Single
    };

    private TableLayoutPanel applicationsLayoutPanel = new TableLayoutPanel {
        ColumnCount = 2,
        RowCount = 2,
        Dock = DockStyle.None,
        AutoSize = true,
        AutoSizeMode = AutoSizeMode.GrowAndShrink,
        Padding = new Padding(2),
        CellBorderStyle = TableLayoutPanelCellBorderStyle.Single
    };

    // Setting up the layout for buttons on the right side
    private TableLayoutPanel buttonsLayoutPanel = new TableLayoutPanel {
        ColumnCount = 1,
        RowCount = 4,
        Dock = DockStyle.Fill,
        AutoSize = true,
        AutoSizeMode = AutoSizeMode.GrowAndShrink
    };

    private TableLayoutPanel actionsPermittedLayoutPanel = new TableLayoutPanel {
        ColumnCount = 2,
        RowCount = 2,
        Dock = DockStyle.None,
        AutoSize = true,
        AutoSizeMode = AutoSizeMode.GrowAndShrink,
        Padding = new Padding(2),
        CellBorderStyle = TableLayoutPanelCellBorderStyle.Single
    };

    // Setting up the layout for buttons on the right side
    private TableLayoutPanel actionsPermittedButtonPanel = new TableLayoutPanel {
        ColumnCount = 1,
        RowCount = 4,
        Dock = DockStyle.Fill,
        AutoSize = true,
        AutoSizeMode = AutoSizeMode.GrowAndShrink
    };

    private TableLayoutPanel actionsBlockedLayoutPanel = new TableLayoutPanel {
        ColumnCount = 2,
        RowCount = 2,
        Dock = DockStyle.None,
        AutoSize = true,
        AutoSizeMode = AutoSizeMode.GrowAndShrink,
        Padding = new Padding(2),
        CellBorderStyle = TableLayoutPanelCellBorderStyle.Single
    };

    // Setting up the layout for buttons on the right side
    private TableLayoutPanel actionsBlockedButtonPanel = new TableLayoutPanel {
        ColumnCount = 1,
        RowCount = 4,
        Dock = DockStyle.Fill,
        AutoSize = true,
        AutoSizeMode = AutoSizeMode.GrowAndShrink
    };

    private TableLayoutPanel mainCanvasButtons = new TableLayoutPanel {
        Left = 20,
        Top = 0,
        ColumnCount = 4,
        RowCount = 1, 
        Dock = DockStyle.None, 
        AutoSize = true,
        AutoSizeMode = AutoSizeMode.GrowAndShrink,
        Padding = new Padding(2),
        CellBorderStyle = TableLayoutPanelCellBorderStyle.Single
    };

    private TableLayoutPanel mainControlButtons = new TableLayoutPanel {
        ColumnCount = 2,
        RowCount = 1, 
        Dock = DockStyle.None, 
        AutoSize = true,
        AutoSizeMode = AutoSizeMode.GrowAndShrink,
        Padding = new Padding(2),
        CellBorderStyle = TableLayoutPanelCellBorderStyle.Single
    };


    // Settings Inputs. 
    private GroupBox sbsam_StartupSettingsRGroup = new GroupBox {
        Text = "Load Applications on Startup",
        Width = 350, 
        Height = 60, 
    };
    private RadioButton sbsam_StartupSettingsRBYes = new RadioButton {
        Text = "Yes",
        AutoSize = true,
        Dock = DockStyle.Fill,
        TextAlign = ContentAlignment.MiddleLeft
    };
    private RadioButton sbsam_StartupSettingsRBNo = new RadioButton {
        Text = "No",
        AutoSize = true,
        Dock = DockStyle.Fill,
        TextAlign = ContentAlignment.MiddleLeft
    };
    private RadioButton sbsam_StartupSettingsRBPrompt = new RadioButton {
        Text = "Prompt",
        AutoSize = true,
        Dock = DockStyle.Fill,
        TextAlign = ContentAlignment.MiddleLeft
    };
    private NumericUpDown sbsam_StartupSecondsToDelayInput = new NumericUpDown {
        Width = 50,
        Minimum = 0,
        Maximum = 30,
        Value = 2,
        Anchor = AnchorStyles.None,
        Margin = new Padding(0, 0, 0, 0)
    };
    private Label sbsam_StartupSettingsdelayLabel = new Label {
        Text = "Second(s) Delay Between Apps:",
        AutoSize = true,
        Dock = DockStyle.Fill,
        TextAlign = ContentAlignment.MiddleLeft
    };


    // Applications Inputs. 
    private Label applicationsListLabel = new Label {
        Text = "Applications to run at startup",
        AutoSize = true,
    };

    private ListBox applicationsListBox = new ListBox {
        Width = 250,
        Height = 100,
    };

    private Button applicationsAddButton = new Button {
        Width = 120,
        Text = "Add Application",
    };

    private Button applicationsAddPathButton = new Button {
        Width = 120,
        Text = "Add Path",
    };
    private Button applicationsRemoveButton = new Button {
        Width = 120,
        Text = "Remove Application",
        Enabled = false,
    };


    // Actions to launch at startup section
    private Label actionsStartupPermittedLabel = new Label {
        Text = "Actions to run at startup",
        AutoSize = true,
    };
    private ListBox actionsStartupPermittedListBox = new ListBox {
        Width = 250,
        Height = 100,
    };
    private Button actionsStartupPermittedButtonAdd = new Button {
        Width = 120,
        Text = "Add Action",
    };
    private Button actionsStartupPermittedButtonRemove = new Button {
        Width = 120,
        Text = "Remove Action",
        Enabled = false,
    };


    // Actions to prevent launching at startup section
    private Label actionsStartupBlockedLabel = new Label {
        Text = "Actions to block running at startup",
        AutoSize = true,
    };

    private ListBox actionsStartupBlockedListBox = new ListBox {
        Width = 250,
        Height = 100,
    };

    private Button actionsStartupBlockedButtonAdd = new Button {
        Width = 120,
        Text = "Add Action",
    };

    private Button actionsStartupBlockedButtonRemove = new Button {
        Width = 120,
        Text = "Remove Action",
        Enabled = false,
    };

    // Form Control Buttons. 
    private Button resetConfigButton = new Button {
        Width = 70,
        Text = "Reset All",
    };
    private Button importConfigButton = new Button {
        Width = 70,
        Text = "Import",
    };

    private Button ExportConfigButton = new Button {
        Width = 70,
        Text = "Export",
    };
    private Button saveConfigButton = new Button {
        Width = 70,
        Text = "Save",
        Enabled = false,
    };
    private Button closeButton = new Button {
        Width = 70,
        Text = "Close",
    };
    

    private Button sbsamControlSaveButton = new Button {Width = 90, Text = "Save", Enabled = false};
    private Button sbsamControlCloseButton = new Button {Width = 90, Text = "Close"};  
    private Button sbsamOptionsResetAll = new Button {Width = 90, Text = "Remove All"};
    private Button sbsamOptionsAbout = new Button {Width = 90, Text = "About"};
    private Button sbsamOptionsImport = new Button {Width = 90, Text = "Import"};
    private Button sbsamOptionsExport = new Button {Width = 90, Text = "Export"};
    
    private ToolTip toolTip = new ToolTip();

    public StartupConfigForm(Rectangle activeWindowRect, List<ActionData> actions) {
    actionDataList = actions;
    this.Text = "Startup Applications Settings";
    this.Width = 600;
    this.Height = 700;

    // Positioning of the form to center on the active window
    int centerX = activeWindowRect.Left + (activeWindowRect.Width - this.Width) / 2;
    int centerY = activeWindowRect.Top + (activeWindowRect.Height - this.Height) / 2;
    this.Location = new Point(centerX, centerY);
    this.TopMost = true;

    // Main TableLayoutPanel to hold all sections
    TableLayoutPanel mainLayoutPanel = new TableLayoutPanel {
        Dock = DockStyle.Fill,
        ColumnCount = 1,
        RowCount = 6,
        Padding = new Padding(10),
        AutoSize = true,
        AutoSizeMode = AutoSizeMode.GrowAndShrink
    };
    this.Controls.Add(mainLayoutPanel);

    // 1. Welcome Message Panel
    Label welcomeLabel = new Label {
        Text = "Welcome to startup manager. Please visit the following link for any help: www.a.com",
        Dock = DockStyle.Top,
        AutoSize = true
    };
    mainLayoutPanel.Controls.Add(welcomeLabel);

    // 2. Settings Buttons Panel
    TableLayoutPanel settingsPanel = new TableLayoutPanel {
        ColumnCount = 4,
        AutoSize = true,
        AutoSizeMode = AutoSizeMode.GrowAndShrink
    };
    settingsPanel.Controls.Add(sbsamOptionsResetAll, 0, 0);        
    settingsPanel.Controls.Add(sbsamOptionsImport, 1, 0);
    settingsPanel.Controls.Add(sbsamOptionsExport, 2, 0);
    settingsPanel.Controls.Add(sbsamOptionsAbout, 3, 0);
    mainLayoutPanel.Controls.Add(settingsPanel);


    // 3. Applications Section
    AddApplicationSection(mainLayoutPanel);

    // 4. Actions to Run Section
    AddActionsSection(mainLayoutPanel, "Actions to run at startup", actionsStartupPermittedListBox, actionsStartupPermittedButtonAdd, actionsStartupPermittedButtonRemove);

    // 5. Actions to Block Section
    AddActionsSection(mainLayoutPanel, "Actions to block running at startup", actionsStartupBlockedListBox, actionsStartupBlockedButtonAdd, actionsStartupBlockedButtonRemove);

    // 6. Startup Options Section
    AddStartupOptionsSection(mainLayoutPanel);

    // 7. Control Buttons (Save/Close)
    TableLayoutPanel controlButtonsPanel = new TableLayoutPanel {
        ColumnCount = 2,
        AutoSize = true,
        AutoSizeMode = AutoSizeMode.GrowAndShrink,
        Dock = DockStyle.Bottom
    };
    controlButtonsPanel.Controls.Add(sbsamControlSaveButton, 0,0);
    controlButtonsPanel.Controls.Add(sbsamControlCloseButton, 1,0);
    mainLayoutPanel.Controls.Add(controlButtonsPanel);

}

private void AddApplicationSection(TableLayoutPanel mainLayoutPanel) {
    TableLayoutPanel applicationsPanel = new TableLayoutPanel {
        ColumnCount = 2,
        AutoSize = true,
        AutoSizeMode = AutoSizeMode.GrowAndShrink,
        Padding = new Padding(0, 10, 0, 10)
    };
    applicationsPanel.Controls.Add(new Label { Text = "Applications to run at startup", AutoSize = true }, 0, 0);
    applicationsPanel.Controls.Add(applicationsListBox, 0, 1);
    applicationsPanel.SetRowSpan(applicationsListBox, 2); // Listbox spans 2 rows

    // Buttons for application list
    TableLayoutPanel appButtons = new TableLayoutPanel { ColumnCount = 1, AutoSize = true };
    appButtons.Controls.Add(applicationsAddButton);
    appButtons.Controls.Add(applicationsRemoveButton);
    appButtons.Controls.Add(applicationsAddPathButton);
    applicationsPanel.Controls.Add(appButtons, 1, 1);
    
    mainLayoutPanel.Controls.Add(applicationsPanel);
}

private void AddActionsSection(TableLayoutPanel mainLayoutPanel, string title, ListBox listBox, Button addButton, Button removeButton) {
    TableLayoutPanel actionsPanel = new TableLayoutPanel {
        ColumnCount = 2,
        AutoSize = true,
        AutoSizeMode = AutoSizeMode.GrowAndShrink,
        Padding = new Padding(0, 10, 0, 10)
    };
    actionsPanel.Controls.Add(new Label { Text = title, AutoSize = true }, 0, 0);
    actionsPanel.Controls.Add(listBox, 0, 1);
    actionsPanel.SetRowSpan(listBox, 2); // Listbox spans 2 rows

    // Buttons for actions
    TableLayoutPanel actionButtons = new TableLayoutPanel { ColumnCount = 1, AutoSize = true };
    actionButtons.Controls.Add(addButton);
    actionButtons.Controls.Add(removeButton);
    actionsPanel.Controls.Add(actionButtons, 1, 1);
    
    mainLayoutPanel.Controls.Add(actionsPanel);
}

private void AddStartupOptionsSection(TableLayoutPanel mainLayoutPanel) {
    GroupBox startupOptionsGroup = new GroupBox { Text = "Load Applications on Startup", Width = 400, Height = 80 };
    TableLayoutPanel startupOptionsPanel = new TableLayoutPanel {
        ColumnCount = 5,
        Dock = DockStyle.Fill,
        AutoSize = true,
        AutoSizeMode = AutoSizeMode.GrowAndShrink
    };
    startupOptionsPanel.Controls.Add(sbsam_StartupSettingsRBYes, 0, 0);
    startupOptionsPanel.Controls.Add(sbsam_StartupSettingsRBNo, 1, 0);
    startupOptionsPanel.Controls.Add(sbsam_StartupSettingsRBPrompt, 2, 0);
    startupOptionsPanel.Controls.Add(sbsam_StartupSecondsToDelayInput, 3, 0);
    startupOptionsPanel.Controls.Add(sbsam_StartupSettingsdelayLabel, 4, 0);
    startupOptionsGroup.Controls.Add(startupOptionsPanel);

    mainLayoutPanel.Controls.Add(startupOptionsGroup);
}
    
    private void AddApplication_Click(object sender, EventArgs e)
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
                                if (!applicationsListBox.Items.Contains(selectedFile))
                                {
                                    applicationsListBox.Items.Add(selectedFile);
                                    saveConfigButton.Enabled = true;
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
                            saveConfigButton.Enabled = true;
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
        if (applicationsListBox.SelectedItem != null)
        {
            applicationsListBox.Items.Remove(applicationsListBox.SelectedItem);
            saveConfigButton.Enabled = true;
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
                    actionsStartupPermittedListBox.Items.Add(selectedAction); // Add action to the list box
                    saveConfigButton.Enabled = true; // Enable save button
                }
            }
        }
    }

    private void RemoveAction_Click(object sender, EventArgs e)
    {
        if (actionsStartupPermittedListBox.SelectedItem != null)
        {
            actionsStartupPermittedListBox.Items.Remove(actionsStartupPermittedListBox.SelectedItem);
            saveConfigButton.Enabled = true;
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
            actionsStartupPermittedListBox.Items.Clear();
            sbsam_StartupSettingsRBYes.Checked = false;
            sbsam_StartupSettingsRBNo.Checked = false;
            sbsam_StartupSettingsRBPrompt.Checked = true;
            saveConfigButton.Enabled = false;
            applicationsRemoveButton.Enabled = false;
            actionsStartupPermittedButtonRemove.Enabled = false;
        }
    }

    private void SaveConfig_Click(object sender, EventArgs e)
    {
        MessageBox.Show("Configuration saved!");
        saveConfigButton.Enabled = false;
    }

    private void CloseButton_Click(object sender, EventArgs e)
    {
        this.Close();
    }

    private void ApplicationListBox_SelectedIndexChanged(object sender, EventArgs e)
    {
        applicationsRemoveButton.Enabled = applicationsListBox.SelectedItem != null;
    }

    private void ActionListBox_SelectedIndexChanged(object sender, EventArgs e)
    {
        actionsStartupPermittedButtonRemove.Enabled = actionsStartupPermittedListBox.SelectedItem != null;
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