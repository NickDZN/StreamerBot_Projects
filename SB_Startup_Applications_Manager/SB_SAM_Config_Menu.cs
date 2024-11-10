using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Windows.Forms;
using System.Text.Json;

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

    public bool Execute() {
        
        // Attempt to get the handle of the currently active window
        IntPtr activeWindowHandle = GetForegroundWindow();

        // Check if the window was found
        if (activeWindowHandle == IntPtr.Zero) {
            MessageBox.Show("No active window found.");
            return false;
        }

        // Get the window title
        StringBuilder windowTitle = new StringBuilder(256);
        GetWindowText(activeWindowHandle, windowTitle, windowTitle.Capacity);

        // Get the dimensions of the active window
        if (!GetWindowRect(activeWindowHandle, out Rectangle activeWindowRect)) {
            MessageBox.Show("Failed to get window dimensions.");
            return false;
        }

        // Start new thread for the form. 
        Thread staThread = new Thread(() => {

            // Enable visual styles for the form
            Application.EnableVisualStyles();

            // Get the global action list
            List<ActionData> actionList = CPH.GetActions();

            // Create a new instance of StartupConfigForm if no form is open
            if (mainFormInstance == null || mainFormInstance.IsDisposed) {                
                mainFormInstance = new LoadStartupConfigForm(activeWindowRect, actionList);
                Application.Run(mainFormInstance);
            }
            // Bring the existing form instance to the front
            else {                
                mainFormInstance.BringToFront();
            }
        });

        staThread.SetApartmentState(ApartmentState.STA);
        staThread.Start();
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
    private NumericUpDown numupdwnStartupConfigDelay = new NumericUpDown {Width = 40, Minimum = 0, Maximum = 30, Value = 2, Anchor = AnchorStyles.Left, Margin = new Padding(2, 0, 0, 0)};

    private int indexOfListItem;

    // Application Start-up IO's.
    private ListBox lstApplications = new ListBox {Width = 250, Height = 100};
    private Button btnAddApplication = new Button {Width = 120, Text = "Add Application"};
    private Button btnAddApplicationPath = new Button {Width = 120, Text = "Add Path"};
    private Button btnRemoveApplication = new Button {Width = 120, Text = "Remove Application", Enabled = false};

    // Define the buttons with text symbols for arrows
    private Button btnMoveUp = new Button { Width = 20, Height = 20, Text = "^", Font = new Font("Arial", 9, FontStyle.Bold),  };
    private Button btnMoveDown = new Button { Width = 20, Height = 20, Text = "↓", Font = new Font("Arial", 9, FontStyle.Bold) };


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

        // Enable reordering for each ListBox
        EnableListBoxOrdering(lstApplications);
        EnableListBoxOrdering(lstActionsPermitted);
        EnableListBoxOrdering(lstActionsBlocked);

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
           
        // Main applications panel with explicit row heights
        TableLayoutPanel tpanelApplications = new TableLayoutPanel {
            ColumnCount = 2,
            RowCount = 3,
            AutoSize = true,
            AutoSizeMode = AutoSizeMode.GrowAndShrink,
            Padding = new Padding(0)
        };

        // Add Label. 
        tpanelApplications.Controls.Add(new Label { Text = "Applications to run at startup", AutoSize = true }, 0, 0);

        // Configure and add list box. 
        lstApplications.Width = 300;
        lstApplications.Margin = new Padding(0);
        lstApplications.Padding = new Padding(0);
        tpanelApplications.Controls.Add(lstApplications, 0, 1);

        // Create panel for main buttons. 
        TableLayoutPanel tpanelApplicationContols = new TableLayoutPanel {
            ColumnCount = 1, 
            AutoSize = true, 
            Margin = new Padding(5, 0, 0, 0),
            Padding = new Padding(0)
        };

        // Add buttons to the panel. 
        tpanelApplicationContols.Controls.Add(btnAddApplication);
        tpanelApplicationContols.Controls.Add(btnRemoveApplication);
        tpanelApplicationContols.Controls.Add(btnAddApplicationPath);

        // Create arrow buttons panel. Flow Layout for easy HAlign. 
        FlowLayoutPanel fpanelApplicationArrows = new FlowLayoutPanel {
            FlowDirection = FlowDirection.LeftToRight,
            Anchor = AnchorStyles.Right,
            AutoSize = true,
            Margin = new Padding(0),
            Padding = new Padding(0)
        };

        // Create the arrow buttons. 
        btnMoveUp.Margin = new Padding(0, 0, 1, 0);
        btnMoveDown.Margin = new Padding(1, 0, 0, 0);
        fpanelApplicationArrows.Controls.Add(btnMoveUp);
        fpanelApplicationArrows.Controls.Add(btnMoveDown);

        // Add tpanelApplicationContols to the right of lstApplications
        tpanelApplications.Controls.Add(tpanelApplicationContols, 1, 1);
        tpanelApplications.SetRowSpan(tpanelApplicationContols, 2);

        // Add arrowButtonsPanel below the ListBox, centered
        tpanelApplications.Controls.Add(fpanelApplicationArrows, 0, 2);

        // Attach event handlers.   
        lstApplications.SelectedIndexChanged += ApplicationListBox_SelectedIndexChanged; 
        btnAddApplication.Click += AddApplication_Click;
        btnAddApplicationPath.Click += AddApplicationPath_Click;
        btnRemoveApplication.Click += RemoveApplication_Click;
        btnMoveUp.Click += btnApplicationsUp_Click;
        btnMoveDown.Click += btnApplicationsDown_Click;

        mainLayoutPanel.Controls.Add(tpanelApplications);
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
            Height = 50
        };

        // Create a TableLayoutPanel with 3 columns and 2 rows to align options
        TableLayoutPanel startupOptionsPanel = new TableLayoutPanel {
            ColumnCount = 6,
            RowCount = 3,
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
        // Run the file dialog in a separate STA thread
        Thread fileDialogThread = new Thread(() => {
            try             {
                using (OpenFileDialog fileDialog = new OpenFileDialog()) {
                    fileDialog.Filter = "Executable Files (*.exe)|*.exe|All Files (*.*)|*.*";
                    fileDialog.Title = "Select an Application File";

                    if (fileDialog.ShowDialog(this) == DialogResult.OK) {
                        // Create an instance of ApplicationFileDetails to hold file name and path
                        ApplicationFileDetails selectedFile = new ApplicationFileDetails(fileDialog.FileName);

                        // Update the UI on the main thread using Invoke
                        this.Invoke(new Action(() => {
                            // Check if the file (by full path) is already in the list
                            if (!lstApplications.Items.Cast<ApplicationFileDetails>().Any(f => f.FullPath == selectedFile.FullPath)) {
                                lstApplications.Items.Add(selectedFile);
                                btnSaveForm.Enabled = true;
                            }
                            else {
                                MessageBox.Show("This application file has already been added.");
                            }
                        }));
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

    private void AddApplicationPath_Click(object sender, EventArgs e) {
        using (PathInputDialog pathDialog = new PathInputDialog(this)) {
            if (pathDialog.ShowDialog(this) == DialogResult.OK) {
                string pathToAdd = pathDialog.EnteredPath; 

                if (!string.IsNullOrWhiteSpace(pathToAdd)) {
                    if (File.Exists(pathToAdd) || Directory.Exists(pathToAdd)) {
                        if (!lstApplications.Items.Contains(pathToAdd)) {
                            ApplicationFileDetails selectedFile = new ApplicationFileDetails(pathToAdd);
                            
                            lstApplications.Items.Add(selectedFile); 
                            btnSaveForm.Enabled = true;
                        }
                        else {
                            MessageBox.Show("This application path has already been added.");
                        }
                    }
                    else {
                        MessageBox.Show("The specified path does not exist.");
                    }
                }
                else {
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

    private void EnableListBoxOrdering(ListBox listBox) {
        listBox.MouseDown += ListBox_MouseDown;
        listBox.MouseMove += ListBox_MouseMove;
        listBox.DragOver += ListBox_DragOver;
        listBox.DragDrop += ListBox_DragDrop;
        listBox.AllowDrop = true;
    }

    // Start dragging the item if the mouse is pressed down
    private void ListBox_MouseDown(object sender, MouseEventArgs mouseEventArgs) {
        ListBox listBox = (ListBox)sender;
        indexOfListItem = listBox.IndexFromPoint(mouseEventArgs.X, mouseEventArgs.Y);
    }

    // Handle moving the item if the mouse is dragged
    private void ListBox_MouseMove(object sender, MouseEventArgs mouseEventArgs) {
        ListBox listBox = (ListBox)sender;
        
        // Start dragging if the left button is held down
        if (mouseEventArgs.Button == MouseButtons.Left && indexOfListItem >= 0) {
            listBox.DoDragDrop(listBox.Items[indexOfListItem], DragDropEffects.Move);
        }
    }

    private void btnApplicationsUp_Click(object sender, EventArgs clickEventArgs) {

        ListBox listBox = lstApplications;

        // Ensure an item is selected and it's not the first item
        if (listBox.SelectedIndex > 0) {
            int selectedIndex = listBox.SelectedIndex;
        
            // Store the item to move
            var item = listBox.Items[selectedIndex];
        
            // Remove it and insert it at the new position
            listBox.Items.RemoveAt(selectedIndex);
            listBox.Items.Insert(selectedIndex - 1, item);
        
            // Set the moved item as selected
            listBox.SelectedIndex = selectedIndex - 1;
        }
    }

    private void btnApplicationsDown_Click(object sender, EventArgs clickEventArgs) {
        // Reference the ListBox directly, assuming it's named lstApplications
        ListBox listBox = lstApplications;

        // Ensure an item is selected and it's not the last item
        if (listBox.SelectedIndex < listBox.Items.Count - 1 && listBox.SelectedIndex != -1) {
            int selectedIndex = listBox.SelectedIndex;
            
            // Store the item to move
            var item = listBox.Items[selectedIndex];
            
            // Remove it and insert it at the new position
            listBox.Items.RemoveAt(selectedIndex);
            listBox.Items.Insert(selectedIndex + 1, item);
            
            // Set the moved item as selected
            listBox.SelectedIndex = selectedIndex + 1;
        }
    }

    // Allow item to be dropped in new position
    private void ListBox_DragOver(object sender, DragEventArgs dragEventArgs) {
        dragEventArgs.Effect = DragDropEffects.Move;
    }

    // Reorder the item when dropped in a new position
    private void ListBox_DragDrop(object sender, DragEventArgs dragEventArgs) {
        ListBox listBox = (ListBox)sender;
        
        // Get the index of the drop target
        int indexOfItemUnderMouseToDrop = listBox.IndexFromPoint(listBox.PointToClient(new Point(dragEventArgs.X, dragEventArgs.Y)));
        
        // Move the dragged item to the drop position if it's valid and different
        if (indexOfItemUnderMouseToDrop != ListBox.NoMatches && indexOfItemUnderMouseToDrop != indexOfListItem) {
            object draggedItem = listBox.Items[indexOfListItem];
            listBox.Items.RemoveAt(indexOfListItem);
            listBox.Items.Insert(indexOfItemUnderMouseToDrop, draggedItem);

            // Update selection to indicate new position
            listBox.SetSelected(indexOfItemUnderMouseToDrop, true);
        }
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
    private ListBox lstAMFListBox = new ListBox {Left = 20, Top = 20, Width = 400, Height = 300,};
    private Button btnAMFAddItem = new Button {Left = 430, Top = 20, Width = 120, Text = "Add Action",};
    private Button btnAMFRemoveButton = new Button {Left = 430, Top = 40, Width = 120,Text = "Cancel",};
    private List<ActionData> actionDataList;

    public string SelectedAction { get; private set; }

    public ActionManagerForm(List<ActionData> actionData) {
        this.Text = "Actions To Manage";
        this.Width = 600;
        this.Height = 400;
        this.Controls.Add(lstAMFListBox);
        this.Controls.Add(btnAMFAddItem);
        this.Controls.Add(btnAMFRemoveButton);

        // Initialize actionDataList with the passed-in actionData
        actionDataList = actionData;

        btnAMFAddItem.Click += AddActionToListButton_Click;
        btnAMFRemoveButton.Click += CancelButton_Click;
        LoadActions();
    }

    private void LoadActions()
    {
        // Clear the action list box and populate it with actions
        lstAMFListBox.Items.Clear(); // Clear previous items

        // Loop through each action in the list and display it
        foreach (var action in actionDataList)
        {
            // Format the display string for each action
            string actionDisplay = $"{action.Name} - {(action.Enabled ? "Enabled" : "Disabled")}";
            lstAMFListBox.Items.Add(actionDisplay); // Add to the list box
        }
    }

    private void AddActionToListButton_Click(object sender, EventArgs e)
    {
        if (lstAMFListBox.SelectedItem != null)
        {
            string selectedActionDisplay = lstAMFListBox.SelectedItem.ToString();
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








public class ApplicationFileDetails
{
    public string FileName { get; set; }    // Only the file name for display
    public string FullPath { get; set; }    // Full path for access

    public ApplicationFileDetails(string fullPath) {
        FullPath = fullPath;
        FileName = Path.GetFileName(fullPath); // Extract file name from full path
    }

    public override string ToString() {
        return FileName; // Display the file name in the ListBox
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

public static class UserSettingsControl {
    public static void SaveStartupManagerSettings(StartupManagerSettings settings, string filePath) {
        try {
            // Serialize the settings object to JSON format
            string json = JsonSerializer.Serialize(settings, new JsonSerializerOptions { WriteIndented = true });

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
