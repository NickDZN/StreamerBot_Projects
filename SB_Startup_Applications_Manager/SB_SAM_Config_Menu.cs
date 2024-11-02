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
    // Applications To Start Form Items.   private Label applicationsListLabel = new Label
    {
        Text = "Applications to run at startup",
        Left = 20,
        Top = 20,
        AutoSize = true,
    };

    private ListBox applicationsListBox = new ListBox
    {
        Left = 20,
        Top = 40,
        Width = 250,
        Height = 100,
    };

    private Button applicationsAddButton = new Button
    {
        Left = 280,
        Top = 40,
        Width = 120,
        Text = "Add Application",
    };
    private Button applicationsAddPathButton = new Button
    {
        Left = 280,
        Top = 70,
        Width = 120,
        Text = "Add Path",
    };
    private Button applicationsRemoveButton = new Button
    {
        Left = 280,
        Top = 100,
        Width = 120,
        Text = "Remove Application",
        Enabled = false,
    };

    // Load Applications at startup Radio Group
    private GroupBox sbsam_StartupSettingsRGroup = new GroupBox
    {
        Text = "Load Applications on Startup",
        Left = 420,
        Top = 40,
        Width = 200,
        Height = 100,
    };
    private RadioButton sbsam_StartupSettingsRBYes = new RadioButton
    {
        Text = "Yes",
        Left = 10,
        Top = 20,
    };
    private RadioButton sbsam_StartupSettingsRBNo = new RadioButton // Fixed name to avoid duplication
    {
        Text = "No",
        Left = 10,
        Top = 40,
    };
    private RadioButton sbsam_StartupSettingsRBPrompt = new RadioButton
    {
        Text = "Prompt",
        Left = 10,
        Top = 60,
    };

    // Seconds to Delay Input
    private Label delayLabel = new Label
    {
        Text = "Seconds to Delay:",
        Left = 420,
        Top = 160,
        AutoSize = true,
    };
    private NumericUpDown secondsToDelayInput = new NumericUpDown
    {
        Left = 420,
        Top = 180,
        Width = 60,
        Minimum = 0, // Minimum delay
        Maximum = 60, // Maximum delay
        Value = 5 // Default value
    };

    // Actions to launch at startup section
    private Label actionsStatupPermittedLabel = new Label
    {
        Text = "Actions to run at startup",
        Left = 20,
        Top = 220,
        AutoSize = true,
    };
    private ListBox actionsStatupPermittedListBox = new ListBox
    {
        Left = 20,
        Top = 240,
        Width = 250,
        Height = 100,
    };
    private Button actionsStatupPermittedButtonAdd = new Button
    {
        Left = 280,
        Top = 240,
        Width = 120,
        Text = "Add Action",
    };
    private Button actionsStatupPermittedButtonRemove = new Button
    {
        Left = 280,
        Top = 270,
        Width = 120,
        Text = "Remove Action",
        Enabled = false,
    };

    // Actions to prevent launch at startup section
    private Label actionsStatupBlockedLabel = new Label
    {
        Text = "Actions to block running at startup",
        Left = 20,
        Top = 350,
        AutoSize = true,
    };

    private ListBox actionsStatupBlockedListBox = new ListBox
    {
        Left = 20,
        Top = 370,
        Width = 250,
        Height = 100,
    };
    private Button actionsStatupBlockedListButtonAdd = new Button
    {
        Left = 280,
        Top = 370,
        Width = 120,
        Text = "Add Action",
    };
    private Button actionsStatupBlockedListButtonRemove = new Button
    {
        Left = 280,
        Top = 400,
        Width = 120,
        Text = "Remove Action",
        Enabled = false,
    };

    // Form Bottom Buttons. 
    private Button resetConfigButton = new Button
    {
        Left = 20,
        Top = 490,
        Width = 100,
        Text = "Reset Config",
    };
    private Button saveConfigButton = new Button
    {
        Left = 380,
        Top = 490,
        Width = 100,
        Text = "Save Config",
        Enabled = false,
    };
    private Button closeButton = new Button
    {
        Left = 500,
        Top = 490,
        Width = 100,
        Text = "Close",
    };
    private ToolTip toolTip = new ToolTip();

    public StartupConfigForm(Rectangle activeWindowRect, List<ActionData> actions) // Constructor updated to accept actions
    {
        actionDataList = actions; // Store the action data in a local variable
        this.Text = "Startup Applications Settings";
        this.Width = 650;
        this.Height = 400;

        // Set the location of the form to be centered over the active window
        // Set the location of the form to be centered over the active window
        int centerX = activeWindowRect.Left + (activeWindowRect.Width - this.Width) / 2;
        int centerY = activeWindowRect.Top + (activeWindowRect.Height - this.Height) / 2;

        // Set the form's location
        this.Location = new Point(centerX, centerY);
        this.TopMost = true; // Ensure it is on top of the active window

        // Add controls to the form
        this.Controls.Add(applicationsListLabel);
        this.Controls.Add(applicationsListBox);
        this.Controls.Add(applicationsAddButton);
        this.Controls.Add(applicationsAddPathButton);
        this.Controls.Add(applicationsRemoveButton);
        this.Controls.Add(actionsStatupPermittedLabel);
        this.Controls.Add(actionsStatupPermittedListBox);
        this.Controls.Add(actionsStatupPermittedButtonAdd);
        this.Controls.Add(actionsStatupPermittedButtonAddRemove);
        this.Controls.Add(sbsam_StartupSettingsRGroup);
        this.Controls.Add(loadSpotifyGroup);
        this.Controls.Add(resetConfigButton);
        this.Controls.Add(saveConfigButton);
        this.Controls.Add(closeButton);

        // Initialize the components and tooltips
        InitializeComponents();
        InitializeToolTips();

        // Event handlers for button clicks
        applicationsAddButton.Click += AddApplication_Click;
        applicationsAddPathButton.Click += EnterPathButton_Click;
        applicationsRemoveButton.Click += RemoveApplication_Click;
        actionsStatupPermittedButtonAdd.Click += AddAction_Click;
        actionsStatupPermittedButtonAddRemove.Click += RemoveAction_Click;
        resetConfigButton.Click += ResetConfig_Click;
        saveConfigButton.Click += SaveConfig_Click;
        closeButton.Click += CloseButton_Click;

        // Event handlers for list item selection changes
        applicationsListBox.SelectedIndexChanged += ApplicationListBox_SelectedIndexChanged;
        actionsStatupPermittedListBox.SelectedIndexChanged += ActionListBox_SelectedIndexChanged;
    }

    private void InitializeComponents()
    {
        sbsam_StartupSettingsRGroup.Controls.Add(sbsam_StartupSettingsRBYes);
        sbsam_StartupSettingsRGroup.Controls.Add(sbsam_StartupSettingsRBYes);
        sbsam_StartupSettingsRGroup.Controls.Add(sbsam_StartupSettingsRBPrompt);

        loadSpotifyGroup.Controls.Add(loadSpotifyYes);
        loadSpotifyGroup.Controls.Add(loadSpotifyNo);
    }

    private void InitializeToolTips()
    {
        toolTip.SetToolTip(applicationsAddButton, "Select an application file to add.");
        toolTip.SetToolTip(applicationsAddPathButton, "Add the path entered in the textbox to the list.");
        toolTip.SetToolTip(applicationsRemoveButton, "Remove the selected application.");
        toolTip.SetToolTip(actionsStatupPermittedButtonAdd, "Add a new action to run at startup.");
        toolTip.SetToolTip(actionsStatupPermittedButtonAddRemove, "Remove the selected action.");
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
                    actionsStatupPermittedListBox.Items.Add(selectedAction); // Add action to the list box
                    saveConfigButton.Enabled = true; // Enable save button
                }
            }
        }
    }

    private void RemoveAction_Click(object sender, EventArgs e)
    {
        if (actionsStatupPermittedListBox.SelectedItem != null)
        {
            actionsStatupPermittedListBox.Items.Remove(actionsStatupPermittedListBox.SelectedItem);
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
            actionsStatupPermittedListBox.Items.Clear();
            sbsam_StartupSettingsRBYes.Checked = false;
            sbsam_StartupSettingsRBYes.Checked = false;
            sbsam_StartupSettingsRBPrompt.Checked = true;
            loadSpotifyYes.Checked = false;
            loadSpotifyNo.Checked = true;
            saveConfigButton.Enabled = false;
            applicationsRemoveButton.Enabled = false;
            actionsStatupPermittedButtonAddRemove.Enabled = false;
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
        actionsStatupPermittedButtonAddRemove.Enabled = actionsStatupPermittedListBox.SelectedItem != null;
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
