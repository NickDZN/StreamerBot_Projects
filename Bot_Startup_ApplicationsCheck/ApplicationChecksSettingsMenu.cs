using System;
using System.Drawing;
using System.IO;
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


        CPH.actionListBox

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

        // Show the window title and dimensions
        // MessageBox.Show($"Active Window Title: {windowTitle}\n" +
        //                 $"Dimensions: {activeWindowRect.Width}x{activeWindowRect.Height}\n" +
        //                 $"Position: ({activeWindowRect.Left}, {activeWindowRect.Top})");S

        // Enable visual styles for the application
        Application.EnableVisualStyles();

        // Create an instance of StartupConfigForm, passing the dimensions of the active window
        // Check if form instance is already open
        if (mainFormInstance == null || mainFormInstance.IsDisposed) {
            mainFormInstance = new StartupConfigForm(activeWindowRect);
            Application.Run(mainFormInstance);
        } 
        else {
            mainFormInstance.BringToFront();
        }
        
        return true; 
    }
}

public class StartupConfigForm : Form
{
    private Label applicationListLabel = new Label { Text = "Applications to run at startup", Left = 20, Top = 20, AutoSize = true };
    private Label actionListLabel = new Label { Text = "Actions to run at startup", Left = 20, Top = 160, AutoSize = true };

    // Application list section
    private ListBox applicationListBox = new ListBox { Left = 20, Top = 40, Width = 250, Height = 100 };
    private Button addApplicationButton = new Button { Left = 280, Top = 40, Width = 120, Text = "Add Application" };
    private Button enterPathButton = new Button { Left = 280, Top = 70, Width = 120, Text = "Add from Textbox" };
    private Button removeApplicationButton = new Button { Left = 280, Top = 100, Width = 120, Text = "Remove Application", Enabled = false };

    // Action list section
    private ListBox actionListBox = new ListBox { Left = 20, Top = 200, Width = 250, Height = 100 };
    private Button addActionButton = new Button { Left = 280, Top = 200, Width = 120, Text = "Add Action" };
    private Button removeActionButton = new Button { Left = 280, Top = 230, Width = 120, Text = "Remove Action", Enabled = false };

    private GroupBox loadApplicationsGroup = new GroupBox { Text = "Load Applications on Startup", Left = 420, Top = 40, Width = 200, Height = 100 };
    private RadioButton loadApplicationsYes = new RadioButton { Text = "Yes", Left = 10, Top = 20 };
    private RadioButton loadApplicationsNo = new RadioButton { Text = "No", Left = 10, Top = 40 };
    private RadioButton loadApplicationsPrompt = new RadioButton { Text = "Prompt", Left = 10, Top = 60 };

    private GroupBox loadSpotifyGroup = new GroupBox { Text = "Load Spotify Listener on Startup", Left = 420, Top = 160, Width = 200, Height = 100 };
    private RadioButton loadSpotifyYes = new RadioButton { Text = "Yes", Left = 10, Top = 20 };
    private RadioButton loadSpotifyNo = new RadioButton { Text = "No", Left = 10, Top = 40 };

    private Button resetConfigButton = new Button { Left = 20, Top = 320, Width = 100, Text = "Reset Config" };
    private Button saveConfigButton = new Button { Left = 380, Top = 320, Width = 100, Text = "Save Config", Enabled = false };
    private Button closeButton = new Button { Left = 500, Top = 320, Width = 100, Text = "Close" };

    private ToolTip toolTip = new ToolTip();

    public StartupConfigForm(Rectangle activeWindowRect)
    {
        this.Text = "Startup Applications Settings";
        this.Width = 650;
        this.Height = 400;

        // Set the location of the form to be centered over the active window
        // Set the location of the form to be centered over the active window
        int centerX = activeWindowRect.Left + (activeWindowRect.Width - this.Width) / 2;
        int centerY = activeWindowRect.Top + (activeWindowRect.Height - this.Height) / 2;

        // Show the window title and dimensions
        MessageBox.Show($"Dimensions: {centerX}x{centerY})");

        // Set the form's location
        this.Location = new Point(centerX, centerY);
        this.TopMost = true; // Ensure it is on top of the active window

        // Add controls to the form
        this.Controls.Add(applicationListLabel);
        this.Controls.Add(applicationListBox);
        this.Controls.Add(addApplicationButton);
        this.Controls.Add(enterPathButton);
        this.Controls.Add(removeApplicationButton);
        this.Controls.Add(actionListLabel);
        this.Controls.Add(actionListBox);
        this.Controls.Add(addActionButton);
        this.Controls.Add(removeActionButton);
        this.Controls.Add(loadApplicationsGroup);
        this.Controls.Add(loadSpotifyGroup);
        this.Controls.Add(resetConfigButton);
        this.Controls.Add(saveConfigButton);
        this.Controls.Add(closeButton);

        // Initialize the components and tooltips
        InitializeComponents();
        InitializeToolTips();

        // Event handlers for button clicks
        addApplicationButton.Click += AddApplication_Click;
        enterPathButton.Click += EnterPathButton_Click;
        removeApplicationButton.Click += RemoveApplication_Click;
        addActionButton.Click += AddAction_Click;
        removeActionButton.Click += RemoveAction_Click;
        resetConfigButton.Click += ResetConfig_Click;
        saveConfigButton.Click += SaveConfig_Click;
        closeButton.Click += CloseButton_Click;

        // Event handlers for list item selection changes
        applicationListBox.SelectedIndexChanged += ApplicationListBox_SelectedIndexChanged;
        actionListBox.SelectedIndexChanged += ActionListBox_SelectedIndexChanged;
    }

    private void InitializeComponents()
    {
        loadApplicationsGroup.Controls.Add(loadApplicationsYes);
        loadApplicationsGroup.Controls.Add(loadApplicationsNo);
        loadApplicationsGroup.Controls.Add(loadApplicationsPrompt);

        loadSpotifyGroup.Controls.Add(loadSpotifyYes);
        loadSpotifyGroup.Controls.Add(loadSpotifyNo);
    }

    private void InitializeToolTips()
    {
        toolTip.SetToolTip(addApplicationButton, "Select an application file to add.");
        toolTip.SetToolTip(enterPathButton, "Add the path entered in the textbox to the list.");
        toolTip.SetToolTip(removeApplicationButton, "Remove the selected application.");
        toolTip.SetToolTip(addActionButton, "Add a new action to run at startup.");
        toolTip.SetToolTip(removeActionButton, "Remove the selected action.");
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
                        this.Invoke(new Action(() =>
                        {
                            if (!applicationListBox.Items.Contains(selectedFile))
                            {
                                applicationListBox.Items.Add(selectedFile);
                                saveConfigButton.Enabled = true;
                            }
                            else
                            {
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
                        if (!applicationListBox.Items.Contains(pathToAdd))
                        {
                            applicationListBox.Items.Add(pathToAdd);
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
        if (applicationListBox.SelectedItem != null)
        {
            applicationListBox.Items.Remove(applicationListBox.SelectedItem);
            saveConfigButton.Enabled = true;
        }
    }

    private void AddAction_Click(object sender, EventArgs e)
    {
        actionListBox.Items.Add("New Action");
        saveConfigButton.Enabled = true;
    }

    private void RemoveAction_Click(object sender, EventArgs e)
    {
        if (actionListBox.SelectedItem != null)
        {
            actionListBox.Items.Remove(actionListBox.SelectedItem);
            saveConfigButton.Enabled = true;
        }
    }

    private void ResetConfig_Click(object sender, EventArgs e)
    {
        DialogResult result = MessageBox.Show("Are you sure you want to reset the configuration?", "Confirm Reset", MessageBoxButtons.YesNo, MessageBoxIcon.Warning);
        if (result == DialogResult.Yes)
        {
            applicationListBox.Items.Clear();
            actionListBox.Items.Clear();
            loadApplicationsYes.Checked = false;
            loadApplicationsNo.Checked = false;
            loadApplicationsPrompt.Checked = true;
            loadSpotifyYes.Checked = false;
            loadSpotifyNo.Checked = true;
            saveConfigButton.Enabled = false;
            removeApplicationButton.Enabled = false;
            removeActionButton.Enabled = false;
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
        removeApplicationButton.Enabled = applicationListBox.SelectedItem != null;
    }

    private void ActionListBox_SelectedIndexChanged(object sender, EventArgs e)
    {
        removeActionButton.Enabled = actionListBox.SelectedItem != null;
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
        Location = new Point(ownerForm.Left + (ownerForm.Width - Width) / 2,
                             ownerForm.Top + (ownerForm.Height - Height) / 2);

        Label promptLabel = new Label { Text = "Enter or paste the path of the application:", Left = 10, Top = 10, Width = 360 };
        pathTextBox = new TextBox { Left = 10, Top = 40, Width = 360, ForeColor = Color.Gray, Text = PlaceholderText };

        // Set up placeholder events
        pathTextBox.GotFocus += RemovePlaceholder;
        pathTextBox.LostFocus += SetPlaceholder;

        okButton = new Button { Text = "OK", Left = 220, Width = 75, Top = 70, DialogResult = DialogResult.OK };
        cancelButton = new Button { Text = "Cancel", Left = 300, Width = 75, Top = 70, DialogResult = DialogResult.Cancel };

        okButton.Click += (sender, e) => { DialogResult = DialogResult.OK; Close(); };
        cancelButton.Click += (sender, e) => { DialogResult = DialogResult.Cancel; Close(); };

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


