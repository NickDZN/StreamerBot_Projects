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

public class CPHInline {
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

public class LoadStartupConfigForm : Form {
	private List<ActionData> actionDataList;

	//SB_SAM Startup Configuration Buttons. 
	private RadioButton radioStartupConfigYes = new RadioButton {Text = "Yes", AutoSize = true, Dock = DockStyle.Fill, TextAlign = ContentAlignment.MiddleLeft};
	private RadioButton radioStartupConfigNo = new RadioButton {Text = "No", AutoSize = true, Dock = DockStyle.Fill, TextAlign = ContentAlignment.MiddleLeft};
	private RadioButton radioStartupConfigPrompt = new RadioButton {Text = "Prompt", AutoSize = true, Dock = DockStyle.Fill, TextAlign = ContentAlignment.MiddleLeft};
	private Label lblStartupConfigDelay = new Label {Text = "Delay (In seconds)", AutoSize = true, Dock = DockStyle.Fill, TextAlign = ContentAlignment.MiddleLeft};
	private NumericUpDown numupdwnStartupConfigDelay = new NumericUpDown {Width = 40, Minimum = 0, Maximum = 30, Value = 2, Anchor = AnchorStyles.Left, Margin = new Padding(2, 0, 0, 0)};

	private int indexOfListItem;

	// Application Start-up IO's.
	private ListBox lstApplications = new ListBox();
	private Button btnAddApplication = new Button { Text = "Add Application" };
	private Button btnAddApplicationPath = new Button { Text = "Add Path" };
	private Button btnRemoveApplication = new Button { Text = "Remove Application", Enabled = false };
	private Button btnMoveUp = new Button { Text = "▲" };
	private Button btnMoveDown = new Button { Text = "▼" };


	// Actions Startup Permitted IO's
	private ListBox lstActionsPermitted = new ListBox();
	private Button btnAddActionPermitted = new Button { Text = "Add Action" };
	private Button btnRemoveActionPermitted = new Button { Text = "Remove Action", Enabled = false };
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

	public LoadStartupConfigForm(Rectangle activeWindowRect, List<ActionData> actions) {
	// Locally store the list of actions
		actionDataList = actions;

		// Initialize standardized styles for controls
		InitializeControls();

		// Build the core form layout
		var tabControl = BuildCoreForm(activeWindowRect);

		// Create and configure tabs
		var startupTab = CreateTabPage("Startup");
		var streamEndingTab = CreateTabPage("Stream Ending");
		var supportTab = CreateTabPage("Support");

		// Add specific configurations to tabs
		AddStartupTabControls(startupTab);
		AddStreamEndingTabControls(streamEndingTab);
		AddSupportTabControls(supportTab);

		// Add tabs to the TabControl
		tabControl.TabPages.Add(startupTab);
		tabControl.TabPages.Add(streamEndingTab);
		tabControl.TabPages.Add(supportTab);

		// Add TabControl to the form
		this.Controls.Add(tabControl);



	}


   private void InitializeControls() {
		// Apply styles to buttons
		UIStyling.StyleMainButton(btnAddApplication);
		UIStyling.StyleMainButton(btnRemoveApplication);
		UIStyling.StyleMainButton(btnAddApplicationPath);
		UIStyling.StyleMainButton(btnSaveForm);
		UIStyling.StyleMainButton(btnCloseForm);
		UIStyling.StyleMainButton(btnShowAbout);
		UIStyling.StyleMainButton(btnTestConfig);

		// Apply styles to list boxes
		UIStyling.StyleListBox(lstApplications);
		UIStyling.StyleListBox(lstActionsPermitted);
		UIStyling.StyleListBox(lstActionsBlocked);

		// Apply styles to arrow buttons
		UIStyling.StyleArrowButton(btnMoveUp);
		UIStyling.StyleArrowButton(btnMoveDown);
	}



	private TabControl BuildCoreForm(Rectangle activeWindowRect) {
	// Configure the form properties with a modern theme
		this.Text = "Startup Manager";
		this.Width = 800;
		this.Height = 600;
		this.BackColor = Color.WhiteSmoke; // Light background color
		this.FormBorderStyle = FormBorderStyle.FixedDialog; // Clean, non-resizable window
		this.Font = new Font("Segoe UI", 10, FontStyle.Regular); // Use a modern font

		// Center the form based on the active window's position
		int centerX = activeWindowRect.Left + (activeWindowRect.Width - this.Width) / 2;
		int centerY = activeWindowRect.Top + (activeWindowRect.Height - this.Height) / 2;
		this.Location = new Point(centerX, centerY);
		this.TopMost = true;

		// Create the TabControl with styled tabs
		TabControl tabControl = new TabControl {
			Dock = DockStyle.Fill,
			Font = new Font("Segoe UI", 10, FontStyle.Regular),
			Padding = new Point(10, 10)
		};
	
		tabControl.Appearance = TabAppearance.FlatButtons; // Flat-style tabs
		tabControl.ItemSize = new Size(120, 30); // Larger, clickable tabs
		tabControl.DrawMode = TabDrawMode.OwnerDrawFixed;
		tabControl.DrawItem += (s, e) => {
			e.Graphics.FillRectangle(new SolidBrush(Color.WhiteSmoke), e.Bounds);
			TextRenderer.DrawText(e.Graphics, tabControl.TabPages[e.Index].Text, e.Font, e.Bounds, Color.Black);
		};

		return tabControl;
	}


// Helper method to create a new tab page with common padding and layout
	private TabPage CreateTabPage(string title) {
		return new TabPage(title) {Padding = new Padding(10) };
	}

// Method to add controls for the "Startup" tab
	private void AddStartupTabControls(TabPage startupTab) {
	// Check if startupTab is not null to avoid null reference errors
		if (startupTab == null) throw new ArgumentNullException(nameof(startupTab));

	// Create a main layout panel for the "Startup" tab
		var mainLayoutPanel = new TableLayoutPanel 	{
			Dock = DockStyle.Fill,
			ColumnCount = 1,
			RowCount = 6,
			Padding = new Padding(10),
			AutoSize = true,
			AutoSizeMode = AutoSizeMode.GrowAndShrink,
			CellBorderStyle = TableLayoutPanelCellBorderStyle.Single
		};

		// Add controls specific to "Startup" configuration
		AddConfigurationControls(mainLayoutPanel);
		AddApplicationControls(mainLayoutPanel);
		AddActionControls(mainLayoutPanel, "Actions to run at startup", lstActionsPermitted, btnAddActionPermitted, btnRemoveActionPermitted, AddActionPermitted_SelIndhanged, AddActionPermitted_Click, RemoveActionPermitted_Click);
		AddActionControls(mainLayoutPanel, "Actions to block running at startup", lstActionsBlocked, btnAddActionBlocked, btnRemoveActionBlocked, AddActionBlocked_SelIndhanged, AddActionBlocked_Click, RemoveActionBlocked_Click);


		// Enable reordering for each ListBox
		EnableListBoxOrdering(lstApplications);
		EnableListBoxOrdering(lstActionsPermitted);
		EnableListBoxOrdering(lstActionsBlocked);

		// Add additional controls for startup configuration
		AddStartupConfigurationControls(mainLayoutPanel);
		AddApplicationControlButtons(mainLayoutPanel);

		// Add the configured layout to the "Startup" tab
		startupTab.Controls.Add(mainLayoutPanel);
	}

// Method to add controls for the "Stream Ending" tab
	private void AddStreamEndingTabControls(TabPage streamEndingTab) {
	// Check if streamEndingTab is not null to avoid null reference errors
	if (streamEndingTab == null) throw new ArgumentNullException(nameof(streamEndingTab));

	// Create and add layout and controls specific to "Stream Ending" configuration
	var streamEndingLayoutPanel = new TableLayoutPanel
	{
		Dock = DockStyle.Fill,
		ColumnCount = 1,
		Padding = new Padding(10),
		AutoSize = true,
		AutoSizeMode = AutoSizeMode.GrowAndShrink,
		CellBorderStyle = TableLayoutPanelCellBorderStyle.Single
	};

	Label label = new Label
	{
		Text = "Stream Ending Configuration",
		Dock = DockStyle.Top,
		TextAlign = ContentAlignment.MiddleCenter
	};
	
	streamEndingLayoutPanel.Controls.Add(label);

	// Add any additional controls needed for the Stream Ending tab here

	streamEndingTab.Controls.Add(streamEndingLayoutPanel);
}

// Method to add controls for the "Support" tab
private void AddSupportTabControls(TabPage supportTab)
{
	// Check if supportTab is not null to avoid null reference errors
	if (supportTab == null) throw new ArgumentNullException(nameof(supportTab));

	// Create and add layout and controls specific to "Support" configuration
	var supportLayoutPanel = new TableLayoutPanel
	{
		Dock = DockStyle.Fill,
		ColumnCount = 1,
		Padding = new Padding(10),
		AutoSize = true,
		AutoSizeMode = AutoSizeMode.GrowAndShrink,
		CellBorderStyle = TableLayoutPanelCellBorderStyle.Single
	};

	Label supportLabel = new Label
	{
		Text = "Support Information",
		Dock = DockStyle.Top,
		TextAlign = ContentAlignment.MiddleCenter
	};

	supportLayoutPanel.Controls.Add(supportLabel);

	// Add any additional controls needed for the Support tab here

	supportTab.Controls.Add(supportLayoutPanel);
}



	private void AddConfigurationControls(TableLayoutPanel mainLayoutPanel) {
		
		// 2. Settings Buttons Panel
		TableLayoutPanel settingsPanel = new TableLayoutPanel {
			ColumnCount = 5,
			RowCount = 2,
			AutoSize = true,
			AutoSizeMode = AutoSizeMode.GrowAndShrink,
			Padding = new Padding(0),
			Margin = new Padding(0),
			CellBorderStyle = TableLayoutPanelCellBorderStyle.Single
		};

		Label configurationControlLabel = new Label { Text = "Manage your configuration", AutoSize = true };

		settingsPanel.Controls.Add(configurationControlLabel, 0, 0);
		settingsPanel.SetColumnSpan(configurationControlLabel, 5);

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
		
	FlowLayoutPanel buttonPanel = new FlowLayoutPanel
	{
		FlowDirection = FlowDirection.LeftToRight,
		Dock = DockStyle.Fill, // Ensures the panel spans the width of the form
		AutoSize = true,
		AutoSizeMode = AutoSizeMode.GrowAndShrink,
		Padding = new Padding(0),
		Margin = new Padding(0, 20, 0, 10)
	};

	// Center-align the content within the FlowLayoutPanel
	buttonPanel.Anchor = AnchorStyles.None;
	buttonPanel.WrapContents = false; // Ensures buttons are laid out in a single line
	//buttonPanel.HorizontalAlign = ContentAlignment.MiddleCenter;

	// Add the "Save" and "Cancel" buttons to the FlowLayoutPanel with padding for spacing
	btnSaveForm.Margin = new Padding(10); // Adds space around each button
	btnCloseForm.Margin = new Padding(10);

		// Add buttons to the FlowLayoutPanel
		buttonPanel.Controls.Add(btnSaveForm);
		buttonPanel.Controls.Add(btnCloseForm);

		// Attach click event handlers
		btnSaveForm.Click += MainCanvasSaveButton_Click;
		btnCloseForm.Click += MainCanvasCloseButton_Click;

		// Add the button panel to the main layout panel
		mainLayoutPanel.Controls.Add(buttonPanel);
		mainLayoutPanel.SetCellPosition(buttonPanel, new TableLayoutPanelCellPosition(0, mainLayoutPanel.RowCount - 1));

	}

	
	private void AddApplicationControls(TableLayoutPanel mainLayoutPanel)
{
	TableLayoutPanel tpanelApplications = new TableLayoutPanel
	{
		ColumnCount = 3,
		RowCount = 3,
		Dock = DockStyle.Fill,
		AutoSize = true,
		AutoSizeMode = AutoSizeMode.GrowAndShrink,
		Padding = new Padding(5),
		Margin = new Padding(5)
	};

	// Define column styles
	tpanelApplications.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 70)); // List box
	tpanelApplications.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 20)); // Buttons
	tpanelApplications.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 10)); // Arrows

	// Add label
	tpanelApplications.Controls.Add(new Label
	{
		Text = "Applications to run at startup",
		AutoSize = true,
		Anchor = AnchorStyles.Left
	}, 0, 0);
	tpanelApplications.SetColumnSpan(tpanelApplications.Controls[tpanelApplications.Controls.Count - 1], 3);

	// Add list box
	tpanelApplications.Controls.Add(lstApplications, 0, 1);

	// Create panel for Add/Remove buttons
	FlowLayoutPanel buttonPanel = new FlowLayoutPanel
	{
		FlowDirection = FlowDirection.TopDown,
		Dock = DockStyle.Fill,
		AutoSize = true
	};
	buttonPanel.Controls.Add(btnAddApplication);
	buttonPanel.Controls.Add(btnRemoveApplication);
	buttonPanel.Controls.Add(btnAddApplicationPath);

	// Add button panel
	tpanelApplications.Controls.Add(buttonPanel, 1, 1);

	// Add arrow buttons
	FlowLayoutPanel arrowPanel = new FlowLayoutPanel
	{
		FlowDirection = FlowDirection.TopDown,
		Dock = DockStyle.Fill,
		AutoSize = true
	};
	arrowPanel.Controls.Add(btnMoveUp);
	arrowPanel.Controls.Add(btnMoveDown);

	tpanelApplications.Controls.Add(arrowPanel, 2, 1);

	// Add completed panel to main layout
	mainLayoutPanel.Controls.Add(tpanelApplications);
}


	

	//Actions allowed list and controls. 
	private void AddActionControls(TableLayoutPanel mainLayoutPanel, string title, ListBox listBox, Button addButton, Button removeButton, EventHandler ListBoxSelected, EventHandler addButtonClick, EventHandler removeButtonClick) {


	TableLayoutPanel actionsPanel = new TableLayoutPanel
	{
		ColumnCount = 2,
		AutoSize = true,
		AutoSizeMode = AutoSizeMode.GrowAndShrink,
		Padding = new Padding(5)
	};

	// Add label
	actionsPanel.Controls.Add(new Label { Text = title, AutoSize = true }, 0, 0);
	actionsPanel.SetColumnSpan(actionsPanel.Controls[actionsPanel.Controls.Count - 1], 2);

	// Add list box
	actionsPanel.Controls.Add(listBox, 0, 1);

	// Add buttons
	FlowLayoutPanel buttonPanel = new FlowLayoutPanel
	{
		FlowDirection = FlowDirection.TopDown,
		Dock = DockStyle.Fill,
		AutoSize = true
	};
	buttonPanel.Controls.Add(addButton);
	buttonPanel.Controls.Add(removeButton);

	actionsPanel.Controls.Add(buttonPanel, 1, 1);

	// Add events
	addButton.Click += addButtonClick;
	removeButton.Click += removeButtonClick;

	// Add actions panel to main layout
	mainLayoutPanel.Controls.Add(actionsPanel);
}



protected override void OnLoad(EventArgs e)
{
	base.OnLoad(e);

	// Calculate the total required height of the form
	int requiredHeight = this.Controls.OfType<Control>()
						   .Sum(control => control.PreferredSize.Height + control.Margin.Vertical);

	// Adjust the form size if the content exceeds the current size
	if (requiredHeight > this.Height)
	{
		this.Height = Math.Min(requiredHeight + 50, Screen.PrimaryScreen.WorkingArea.Height);
	}
}



private void AddStartupConfigurationControls(TableLayoutPanel mainLayoutPanel)
{
	// Styled GroupBox for startup options
	GroupBox startupOptionsGroup = new GroupBox
	{
		Text = "Load Applications on Startup",
		Font = new Font("Segoe UI", 10, FontStyle.Bold),
		ForeColor = Color.DimGray,
		BackColor = Color.White,
		Width = 400,
		Height = 80
	};

	TableLayoutPanel startupOptionsPanel = new TableLayoutPanel
	{
		ColumnCount = 6,
		RowCount = 2,
		Dock = DockStyle.Fill,
		AutoSize = true,
		BackColor = Color.WhiteSmoke // Consistent background
	};

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
		Thread fileDialogThread = new Thread(() => {
			try             {
				using (OpenFileDialog fileDialog = new OpenFileDialog()) {
					fileDialog.Filter = "Executable Files (*.exe)|*.exe|All Files (*.*)|*.*";
					fileDialog.Title = "Select an Application File";

					if (fileDialog.ShowDialog(this) == DialogResult.OK) {
						// Create an instance of ApplicationFileDetails to hold file name and path
						// When adding a new application file
						ApplicationFileDetails selectedFile = new ApplicationFileDetails(fileDialog.FileName, lstApplications.Items.Count);


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
							ApplicationFileDetails selectedFile = new ApplicationFileDetails(pathToAdd, lstApplications.Items.Count);

							
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

				// Access the list of selected actions
				List<string> selectedActions = actionManagerDialog.SelectedActions;

				foreach (string action in selectedActions) { 
					lstActionsPermitted.Items.Add(action); 
				}
				btnSaveForm.Enabled = true;
				
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
				// Access the list of selected actions
				List<string> selectedActions = actionManagerDialog.SelectedActions;

				foreach (string action in selectedActions) { 
					lstActionsBlocked.Items.Add(action); 
				}
				btnSaveForm.Enabled = true;
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
   
	private void ListBox_DragOver(object sender, DragEventArgs dragEventArgs) {
		dragEventArgs.Effect = DragDropEffects.Move;
	}

	private void btnApplicationsUp_Click(object sender, EventArgs clickEventArgs) {
		ListBox listBox = lstApplications;

		if (listBox.SelectedIndex > 0) {
			int selectedIndex = listBox.SelectedIndex;
			var item = (ApplicationFileDetails)listBox.Items[selectedIndex];

			// Swap the item with the one above it in the ListBox
			listBox.Items.RemoveAt(selectedIndex);
			listBox.Items.Insert(selectedIndex - 1, item);
			listBox.SelectedIndex = selectedIndex - 1;

			// Update the Index property for both items involved in the swap
			item.Index = selectedIndex - 1;
			if (listBox.Items[selectedIndex] is ApplicationFileDetails itemAbove) {
				itemAbove.Index = selectedIndex;
			}
		}
	}

	private void btnApplicationsDown_Click(object sender, EventArgs clickEventArgs) {
		ListBox listBox = lstApplications;

		if (listBox.SelectedIndex < listBox.Items.Count - 1 && listBox.SelectedIndex != -1) {
			int selectedIndex = listBox.SelectedIndex;
			var item = (ApplicationFileDetails)listBox.Items[selectedIndex];

			// Swap the item with the one below it in the ListBox
			listBox.Items.RemoveAt(selectedIndex);
			listBox.Items.Insert(selectedIndex + 1, item);
			listBox.SelectedIndex = selectedIndex + 1;

			// Update the Index property for both items involved in the swap
			item.Index = selectedIndex + 1;
			if (listBox.Items[selectedIndex] is ApplicationFileDetails itemBelow) {
				itemBelow.Index = selectedIndex;
			}
		}
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
	private void MainCanvasSaveButton_Click(object sender, EventArgs e) {
		SaveCurrentSettings();
		MessageBox.Show("Configuration saved!");
		btnSaveForm.Enabled = false;
	}

	private void MainCanvasCloseButton_Click(object sender, EventArgs e) {
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
				DelayInSeconds = (int)numupdwnStartupConfigDelay.Value // Get delay from NumericUpDown control
			},

			// Populate Applications list from ListBox items
			Applications = lstApplications.Items.Cast<ApplicationFileDetails>()
				.Select((app, index) => new ApplicationConfig
				{
					Path = app.FullPath,
					IsEnabled = true, // Or bind this to another control if needed
					Order = index // Use the list index as the order
				}).ToList(),

			// Populate Actions from permitted and blocked actions ListBoxes
			Actions = new ActionConfigs
			{
				Permitted = lstActionsPermitted.Items.Cast<ActionConfig>()
					.Select((action, index) => new ActionConfig
					{
						Name = action.Name,
						IsEnabled = action.IsEnabled,
						Order = index
					}).ToList(),
				
				Blocked = lstActionsBlocked.Items.Cast<ActionConfig>()
					.Select((action, index) => new ActionConfig
					{
						Name = action.Name,
						IsEnabled = action.IsEnabled,
						Order = index
					}).ToList()
			},

			// Populate UserSettings
			UserSettings = new UserSettingsConfig
			{
				ResetConfig = false, // Or bind to a control like a CheckBox
				ExportSettings = new ExportImportConfig { Path = "default_export_path" },
				ImportSettings = new ExportImportConfig { Path = "default_import_path" },
				LastSaveTime = DateTime.Now
			}
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
		string dataDir = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "data");

		// Ensure the "data" directory exists
		if (!Directory.Exists(dataDir))
		{
			Directory.CreateDirectory(dataDir);
		}

		// Define the full path to the settings file within the "data" directory
		string filePath = Path.Combine(dataDir, "settings.json");

		// Retrieve current settings from the UI and save them
		var settings = GetCurrentSettingsFromUI();
		UserSettingsControl.SaveStartupManagerSettings(settings, filePath);
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
	private ListView lstAMFListView = new ListView
	{
		Left = 20,
		Top = 20,
		Width = 400,
		Height = 300,
		View = View.Details,
		FullRowSelect = true,
		GridLines = true,
		MultiSelect = true // Allow multiple selections
	};

	private Button btnAMFAddItems = new Button { Left = 430, Top = 20, Width = 120, Text = "Add Selected" };
	private Button btnAMFCancelButton = new Button { Left = 430, Top = 60, Width = 120, Text = "Cancel" };
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
			SelectedActions = lstAMFListView.SelectedItems
				.Cast<ListViewItem>()
				.Select(item => item.Text)
				.ToList();

			// Close the form and set DialogResult to OK
			DialogResult = DialogResult.OK;
			Close();
		}
		else
		{
			MessageBox.Show("Please select one or more actions to add.", "Selection Required", MessageBoxButtons.OK, MessageBoxIcon.Warning);
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









public class ApplicationFileDetails {
	public string FileName { get; set; }
	public string FullPath { get; set; }
	public int Index { get; set; } // New property to store the index

	public ApplicationFileDetails(string fullPath, int index) {
		FullPath = fullPath;
		FileName = Path.GetFileName(fullPath);
		Index = index; // Initialize the index
	}

	public override string ToString() {
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


public static class UIStyling
{
	// Style for primary/main buttons
	public static void StyleMainButton(Button button) {        
		button.Font = new Font("Microsoft Sans Serif",9);
		button.Width = 90;
		button.Height = 24;
		button.Margin = new Padding(0,0,0,0);
		button.Padding = new Padding(3,3,3,3);		
	}

	// Style for secondary buttons (less prominent)
	public static void StyleLongerButton(Button button) {        
		button.Width = 120;
		button.Height = 24;
		button.Margin = new Padding(0,0,0,0);
		button.Padding = new Padding(3,3,3,3);		
	}

	// Style for arrow buttons (up/down buttons)
	public static void StyleArrowButton(Button button) {
		button.Width = 20;
		button.Height = 20;
		button.Margin = new Padding(0,0,0,0);
		button.Padding = new Padding(3,3,3,3);		
	}

	// Style for list boxes
	public static void StyleListBox(ListBox listBox) {
		listBox.Font = new Font("Segoe UI", 10, FontStyle.Regular);
		listBox.BackColor = Color.White; // Clean white background
		listBox.ForeColor = Color.Black; // Black text
		listBox.BorderStyle = BorderStyle.FixedSingle; // Thin border for subtle definition
		listBox.Dock = DockStyle.Fill;
		listBox.Height = 120; // Default height for list boxes
		listBox.Width = 300;  // Default width for list boxes
		listBox.Margin = new Padding(5); // Add spacing
	}
}
