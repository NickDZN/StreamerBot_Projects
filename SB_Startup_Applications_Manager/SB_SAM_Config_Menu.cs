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
        Left = 20,
        Top = 50,
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
        ColumnCount = 8,
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




    private ToolTip toolTip = new ToolTip();

    public StartupConfigForm(Rectangle activeWindowRect, List<ActionData> actions) // Constructor updated to accept actions
    {
        // Store List Locally. 
        actionDataList = actions;

        // Form Settings. 
        this.Text = "Startup Applications Settings";
        this.Width = 600;
        this.Height = 600;

        // Set the location of the form to be centered over the active window
        int centerX = activeWindowRect.Left + (activeWindowRect.Width - this.Width) / 2;
        int centerY = activeWindowRect.Top + (activeWindowRect.Height - this.Height) / 2;

        // Set the form's location
        this.Location = new Point(centerX, centerY);
        this.TopMost = true;

        // Add controls to the form
        InitialiseStartupOptions();
        InitialiseApplicationItems();
        InitialisePermittedActionsItems();
        InitialiseBlockedActionsItems();
        InitialiseFormControlButtons();
        this.Load += PositionApplicationsLayoutPanel;

        // Initialize the components and tooltips        
        InitialiseToolTips();

        // Event handlers for button clicks
        applicationsAddButton.Click += AddApplication_Click;
        applicationsAddPathButton.Click += EnterPathButton_Click;
        applicationsRemoveButton.Click += RemoveApplication_Click;
        actionsStartupPermittedButtonAdd.Click += AddAction_Click;
        actionsStartupPermittedButtonRemove.Click += RemoveAction_Click;
        resetConfigButton.Click += ResetConfig_Click;
        saveConfigButton.Click += SaveConfig_Click;
        closeButton.Click += CloseButton_Click;

        // Event handlers for list item selection changes
        applicationsListBox.SelectedIndexChanged += ApplicationListBox_SelectedIndexChanged;
        actionsStartupPermittedListBox.SelectedIndexChanged += ActionListBox_SelectedIndexChanged;
    }

    private void InitialiseStartupOptions() {
        // Define a single row with an adjustable height
        sbsam_layoutGroup.RowStyles.Clear();
        sbsam_layoutGroup.RowStyles.Add(new RowStyle(SizeType.Absolute, 35F)); // Set row height to 35 pixels

        // Adding controls to the TableLayoutPanel
        this.Controls.Add(sbsam_StartupSettingsRGroup);
        sbsam_layoutGroup.Controls.Add(sbsam_StartupSettingsRBYes, 0, 0);
        sbsam_layoutGroup.Controls.Add(sbsam_StartupSettingsRBNo, 1, 0);
        sbsam_layoutGroup.Controls.Add(sbsam_StartupSettingsRBPrompt, 2, 0);
        sbsam_layoutGroup.Controls.Add(sbsam_StartupSecondsToDelayInput, 3, 0);
        sbsam_layoutGroup.Controls.Add(sbsam_StartupSettingsdelayLabel, 4, 0);
        sbsam_StartupSettingsRGroup.Controls.Add(sbsam_layoutGroup);     
    }

    private void InitialiseApplicationItems()
    {
        applicationsLayoutPanel.Controls.Add(applicationsListLabel, 0, 0); 
        applicationsLayoutPanel.Controls.Add(applicationsListBox, 0, 1);

        // Add buttons to the buttons layout panel (right side)
        buttonsLayoutPanel.Controls.Add(applicationsAddButton, 0, 1);
        buttonsLayoutPanel.Controls.Add(applicationsRemoveButton, 0, 2);
        buttonsLayoutPanel.Controls.Add(applicationsAddPathButton, 0, 3);

        // Add the buttons layout panel to the right side of the applications layout panel
        applicationsLayoutPanel.Controls.Add(buttonsLayoutPanel, 1, 1);

        // Set row spans for applications layout panel items
        applicationsLayoutPanel.SetRowSpan(applicationsListBox, 2);

        // Add the applications layout panel to the main form
        this.Controls.Add(applicationsLayoutPanel);     
    }

    private void InitialisePermittedActionsItems()
    {
        actionsPermittedLayoutPanel.Controls.Add(actionsStartupPermittedLabel, 0, 0); 
        actionsPermittedLayoutPanel.Controls.Add(actionsStartupPermittedListBox, 0, 1);

        // Add buttons to the buttons layout panel (right side)
        actionsPermittedButtonPanel.Controls.Add(actionsStartupPermittedButtonAdd, 0, 1);
        actionsPermittedButtonPanel.Controls.Add(actionsStartupPermittedButtonRemove, 0, 2);

        // Add the buttons layout panel to the right side of the applications layout panel
        actionsPermittedLayoutPanel.Controls.Add(actionsPermittedButtonPanel, 1, 1);

        // Set row spans for applications layout panel items
        actionsPermittedLayoutPanel.SetRowSpan(actionsStartupPermittedListBox, 2);

        // Add the applications layout panel to the main form
        this.Controls.Add(actionsPermittedLayoutPanel);     
    }

    private void InitialiseBlockedActionsItems()
    {
        actionsBlockedLayoutPanel.Controls.Add(actionsStartupBlockedLabel, 0, 0); 
        actionsBlockedLayoutPanel.Controls.Add(actionsStartupBlockedListBox, 0, 1);

        // Add buttons to the buttons layout panel (right side)
        actionsBlockedButtonPanel.Controls.Add(actionsStartupBlockedButtonAdd, 0, 1);
        actionsBlockedButtonPanel.Controls.Add(actionsStartupBlockedButtonRemove, 0, 2);

        // Add the buttons layout panel to the right side of the applications layout panel
        actionsBlockedLayoutPanel.Controls.Add(actionsBlockedButtonPanel, 1, 1);

        // Set row spans for applications layout panel items
        actionsBlockedLayoutPanel.SetRowSpan(actionsStartupBlockedListBox, 2);

        // Add the applications layout panel to the main form
        this.Controls.Add(actionsBlockedLayoutPanel);     
    }

    private void InitialiseFormControlButtons()
    {
        // Add buttons to the buttons layout panel (right side)
        mainCanvasButtons.Controls.Add(resetConfigButton, 0, 0);
        mainCanvasButtons.Controls.Add(ExportConfigButton, 1, 0);
        mainCanvasButtons.Controls.Add(importConfigButton, 2, 0);
        mainCanvasButtons.Controls.Add(saveConfigButton, 7, 0);
        mainCanvasButtons.Controls.Add(closeButton, 8, 0);
    
        // Add the applications layout panel to the main form
        this.Controls.Add(mainCanvasButtons);     
    }



    private void PositionApplicationsLayoutPanel(object sender, EventArgs e) {        
        // Position applicationsLayoutPanel below sbsam_layoutGroup
        applicationsLayoutPanel.Top = sbsam_layoutGroup.Bottom + 20;
        applicationsLayoutPanel.Left = sbsam_layoutGroup.Left;

        // Position actionsPermittedLayoutPanel below sbsam_layoutGroup
        actionsPermittedLayoutPanel.Top = applicationsLayoutPanel.Bottom + 20;
        actionsPermittedLayoutPanel.Left = sbsam_layoutGroup.Left;

        // Position actionsBlockedLayoutPanel below sbsam_layoutGroup
        actionsBlockedLayoutPanel.Top = actionsPermittedLayoutPanel.Bottom + 20;
        actionsBlockedLayoutPanel.Left = sbsam_layoutGroup.Left;           

        mainCanvasButtons.Top = actionsBlockedLayoutPanel.Bottom + 20;
        mainCanvasButtons.Left = sbsam_layoutGroup.Left;                        
    }



    private void InitialiseToolTips()
    {
        toolTip.SetToolTip(applicationsAddButton, "Select an application file to add.");
        toolTip.SetToolTip(applicationsAddPathButton, "Add the path entered in the textbox to the list.");
        toolTip.SetToolTip(applicationsRemoveButton, "Remove the selected application.");
        toolTip.SetToolTip(actionsStartupPermittedButtonAdd, "Add a new action to run at startup.");
        toolTip.SetToolTip(actionsStartupPermittedButtonRemove, "Remove the selected action.");
        toolTip.SetToolTip(resetConfigButton, "Reset the configuration to defaults.");
        toolTip.SetToolTip(saveConfigButton, "Save the current configuration.");
        toolTip.SetToolTip(closeButton, "Close the settings window.");
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