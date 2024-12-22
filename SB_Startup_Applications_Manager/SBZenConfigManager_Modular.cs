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

            CPHLogger.logRectDetails(windowRect);
            Screen targetMonitor = Screen.FromRectangle(windowRect);
            Rectangle normalizedWindowRect = NormalizeToMonitor(windowRect, targetMonitor);

            Thread staThread = new Thread(() =>
            {
                try
                {
                    Application.EnableVisualStyles();
                    List<ActionData> actionList = CPH.GetActions();

                    if (mainFormInstance == null || mainFormInstance.IsDisposed)
                    {
                        mainFormInstance = new LoadStartupConfigForm(normalizedWindowRect, actionList);
                        mainFormInstance.StartPosition = FormStartPosition.Manual;
                        mainFormInstance.Location = new Point(
                            targetMonitor.Bounds.Left + normalizedWindowRect.X + 15,
                            targetMonitor.Bounds.Top + normalizedWindowRect.Y + 15
                        );
                        Application.Run(mainFormInstance);
                    }
                    else
                    {
                        mainFormInstance.BringToFront();
                    }
                }
                catch (Exception ex)
                {
                    CPHLogger.LogE($"Unhandled exception in STA thread: {ex.Message}\n{ex.StackTrace}");
                }
            });

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
        int normalizedX = windowRect.Left - monitorBounds.Left;
        int normalizedY = windowRect.Top - monitorBounds.Top;
        return new Rectangle(normalizedX, normalizedY, windowRect.Width, windowRect.Height);
    }
}

/// <summary>
/// Main configuration form for managing Streamer.bot settings.
/// </summary>
public class LoadStartupConfigForm : Form
{
    private readonly UserConfigurationPanel _userConfigurationControls;
    private readonly SelectApplicationsPanel _permittedStartupApplicationsSection;
    private readonly SelectActionsPanel _permittedActionsSection;
    private readonly SelectActionsPanel _blockedActionsSection;
    private readonly StartupBehaviorControlPanel _startupBehaviorControl;
    private readonly FormsControlPanel _formFlowControls;

    public LoadStartupConfigForm(Rectangle activeWindowRect, List<ActionData> actions)
    {
        CPHLogger.LogD("[S]LoadStartupConfigForm.");
        SetFormProperties(this);
        SuspendLayout();

        var coreLayoutPanelForForm = UIComponentFactory.CreateTableLayoutPanel(rows: 6, columns: 1);

        _userConfigurationControls = new UserConfigurationPanel();
        coreLayoutPanelForForm.Controls.Add(_userConfigurationControls, 0, 0);        

        _permittedStartupApplicationsSection = new SelectApplicationsPanel("Permitted Actions", actions);
        coreLayoutPanelForForm.Controls.Add(_permittedStartupApplicationsSection, 0, 1);

        _permittedStartupActionsSection = new SelectActionsPanel("Permitted Actions", actions);
        coreLayoutPanelForForm.Controls.Add(_permittedStartupActionsSection, 0, 2);

        _blockedStartupActionsSection = new SelectActionsPanel("Blocked Actions", actions);
        coreLayoutPanelForForm.Controls.Add(_blockedStartupActionsSection, 0, 3);

        _startupBehaviorControl = new StartupBehaviorControlPanel();
        coreLayoutPanelForForm.Controls.Add(_startupBehaviorControl, 0, 4);

        _formFlowControls = new FormsControlPanel();
        coreLayoutPanelForForm.Controls.Add(_formFlowControls, 0, 5);

        Controls.Add(coreLayoutPanelForForm);
        ResumeLayout();
        CPHLogger.LogAll(this);
        CPHLogger.logRectDetails(activeWindowRect);
    }

    private void SetFormProperties(Form form)
    {
        CPHLogger.LogD("[S]SetFormProps.");
        this.Text = Constants.FormName;
        this.MinimumSize = new Size(100, 100);
        this.BackColor = Constants.FormColour;
        this.Font = new Font("Segoe UI", 10);
        this.FormBorderStyle = FormBorderStyle.FixedDialog;
        this.AutoSize = true;
    }
}

public class StartupBehaviorControlPanel : UserControl
{
    public StartupBehaviorControl()
    {
        var layout = UIComponentFactory.CreateTableLayoutPanel(1, 2);
        var startupLabel = UIComponentFactory.CreateLabel("Startup Behavior:");
        var startupOption = UIComponentFactory.CreateComboBox(new List<string> { "Yes", "No", "Prompt" });
        startupOption.SelectedIndexChanged += (sender, e) => OnStartupOptionChanged();
        layout.Controls.Add(startupLabel, 0, 0);
        layout.Controls.Add(startupOption, 1, 0);
        Controls.Add(layout);
    }

    private void OnStartupOptionChanged()
    {
        MessageBox.Show("Startup option changed");
    }
}


public class UserConfigurationPanel : UserControl 
{

}


public class SelectApplicationsPanel : UserControl
{
    private readonly ListBox _applicationsListBox;
    private readonly Button _addBtn;
    private readonly Button _addPathBtn;
    private readonly Button _removeBtn;


    /// <summary>
    /// Initializes a new instance of SelectApplicationsPanel.
    /// </summary>
    /// <param name="sectionTitle">Title of the section (e.g., "Startup Applications").</param>
    /// <param name="applications">List of applications to populate the ListBox.</param>
    public SelectApplicationsPanel(string sectionTitle, List<ApplicationData> applications)
    {
        // Create GroupBox as the outer container
        var applicationGroupBox = UIComponentFactory.CreateGroupBox(sectionTitle);

        // Create TableLayoutPanel for layout
        var applicationsLayoutTable = UIComponentFactory.CreateTableLayoutPanel(2, 1);
        var applicationsButtonPanel = UIComponentFactory.CreateFlowLayoutPanel();

        // ListBox for displaying applications
        _applicationsListBox = UIComponentFactory.CreateListBox();
        foreach (var app in applications)
        {
            _applicationsListBox.Items.Add(app.Name);
        }

        // Create Arrow Buttons. 
        var listNavigationPanel = UIComponentFactory.CreateListBoxNavigation(_applicationsListBox, "ApplicationsPanel");        

        // Attach selection changed event
        _applicationsListBox.SelectedIndexChanged += ListBoxEventHandler.OnListBoxIndexChanged;

        // Create Buttons with unique EHs. 
        _addBtn = UIComponentFactory.CreateButton("Add", Constants.ButtonStyle.Default, OnAddAction);
        _addPathBtn = UIComponentFactory.CreateButton("Add Path", Constants.ButtonStyle.Default, OnAddPathAction);

        // Create Buttons with centraliaed EHs 
        _removeBtn = UIComponentFactory.CreateButton(
            "Remove", 
            Constants.ButtonStyle.Default, 
            (s, e) => ListBoxHandler.RemoveSelectedItem(_applicationsListBox, "ApplicationsPanel"));

        // Add buttons to FlowLayoutPanel
        _applicationsButtonPanel.Controls.Add(_addBtn);
        _applicationsButtonPanel.Controls.Add(_addPathBtn);
        _applicationsButtonPanel.Controls.Add(_removeBtn);

        // Add controls to TableLayoutPanel 
        applicationsLayoutTable.Controls.Add(_applicationsListBox, 0, 0);
        applicationsLayoutTable.Controls.Add(applicationsButtonPanel, 1, 0);
        applicationsLayoutTable.Controls.Add(listNavigationPanel, 0, 1);

        // Add layout to GroupBox and GroupBox to Panel
        applicationGroupBox.Controls.Add(applicationsLayoutTable);
        Controls.Add(applicationGroupBox);
    }

    /// <summary>
    /// Handles Add Button Click.
    /// </summary>
    private void OnAddAction(object sender, EventArgs e)
    {
        using (var openFileDialog = new OpenFileDialog())
        {
            openFileDialog.Filter = Constants.ExecutableFilter;
            if (openFileDialog.ShowDialog() == DialogResult.OK)
            {
                _applicationsListBox.Items.Add(openFileDialog.FileName);
                MessageBox.Show($"Application added: {openFileDialog.FileName}");
            }
        }
    }

    /// <summary>
    /// Handles Add Path Button Click.
    /// </summary>
    private void OnAddPathAction(object sender, EventArgs e)
    {
        using (var folderDialog = new FolderBrowserDialog())
        {
            if (folderDialog.ShowDialog() == DialogResult.OK)
            {
                _applicationsListBox.Items.Add(folderDialog.SelectedPath);
                MessageBox.Show($"Path added: {folderDialog.SelectedPath}");
            }
        }
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
        if (listBox.SelectedItem == null || listBox.SelectedIndex <= 0) { 
            CPHLogger.LogE("OnMoveItemUp Error");
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
        if (listBox.SelectedItem == null || listBox.SelectedIndex >= listBox.Items.Count - 1) {
            CPHLogger.LogE("OnMoveItemDown Error");
            return; 
        }

        int index = listBox.SelectedIndex;
        var item = listBox.SelectedItem;

        listBox.Items.RemoveAt(index);
        listBox.Items.Insert(index + 1, item);
        listBox.SelectedIndex = index + 1;
    }

    /// <summary>
    /// 
    /// TODO: Implement central version of this. 
    /// 
    /// </summary>
    /// <param name="sender"></param>
    /// <param name="e"></param>
    
    public static void OnRemoveAction(object sender, EventArgs e)
    {
        if (_applicationsListBox.SelectedItem != null)
        {
            var removedItem = _applicationsListBox.SelectedItem.ToString();
            _applicationsListBox.Items.Remove(_applicationsListBox.SelectedItem);
            MessageBox.Show($"Removed {sender.name} list item: {removedItem}");
        }
        else
        {
            MessageBox.Show("Please select an application to remove.");
        }
    }
}










public class SelectActionsPanel : UserControl 
{
    public StartupApplicationsSection(string sectionTitle, List<ActionData> applications)
    {
        // UI Holders.
        var _applicationGroupBox     = UIComponentFactory.CreateGroupBox(sectionTitle);
        var _applicationsLayoutTable = UIComponentFactory.CreateTableLayoutPanel(2, 1);    
        var _applicationsListBox     = UIComponentFactory.CreateListBox();
        var _applicationsButtonPanel = UIComponentFactory.CreateFlowLayoutPanel();

        // UI Interactions
        var _addBtn      = UIComponentFactory.CreateButton("Add", Constants.ButtonStyle.Default);
        var _addPathBtn  = UIComponentFactory.CreateButton("Add", Constants.ButtonStyle.Default);
        var _removeBtn   = UIComponentFactory.CreateButton("Remove", Constants.ButtonStyle.Default);
        
        // Add events. 
        _addBtn.Click        += (sender, e) => OnAddAction();
        _addPathBtn.Click    += (sender, e) => OnAddPathAction();
        _removeBtn.Click     += (sender, e) => OnRemoveAction();

        // Build section. 
        _applicationsButtonPanel.Controls.Add(_addBtn);
        _applicationsButtonPanel.Controls.Add(_addPathBtn);
        _applicationsButtonPanel.Controls.Add(_removeBtn);


        _applicationsLayoutTable.Controls.Add(_applicationsListBox, 0, 0);
        _applicationsLayoutTable.Controls.Add(_applicationsButtonPanel, 1, 0);
        
        _applicationGroupBox.Controls.Add(_applicationsLayoutTable);    
        
        Controls.Add(applicationsLayoutTable);
    }
}




public class StartupBehaviorControlPanel : UserControl 
{

}


public class FormsControlPanel : UserControl 
{

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
    /// <param name = "value">The default value for the NumericUpDown control.</param>
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
    /// <param name="listBox">The target ListBox to apply navigation actions.</param>
    /// <param name="target">The target the event will manipulate.</param>
    /// <returns>A FlowLayoutPanel with navigation buttons.</returns>
    public static FlowLayoutPanel CreateListBoxNavigation(ListBox listBox, string target)
    {
        // Log the creation of the navigation panel
        CPHLogger.LogV($"[CreateListBoxNavigation] Creating FlowLayoutPanel for: {target}");

        // Create the navigation panel
        var arrowPanel = UIComponentFactory.CreateFlowLayoutPanel(
            FlowDirection.LeftToRight,
            wrapContents: true,
            autoSize: true,
            margin: new Padding(0),
            anchor: AnchorStyles.Right
        );

        // Add "Up" button
        var upButton = UIComponentFactory.CreateButton(
            "▲",
            Constants.ButtonStyle.ArrowBtn,
            (s, e) => {
                CPHLogger.LogV($"[{target}] Move Up button clicked.");
                ListBoxHandler.MoveItemUp(listBox);
            }
        );

        var downButton = UIComponentFactory.CreateButton(
            "▼",
            Constants.ButtonStyle.ArrowBtn,
            (s, e) => {
                CPHLogger.LogV($"[{target}] Move Down button clicked.");
                ListBoxHandler.MoveItemDown(listBox);
            }
        );



        // Add buttons to the panel
        arrowPanel.Controls.Add(upButton);
        arrowPanel.Controls.Add(downButton);

        // Log the successful creation
        CPHLogger.LogV($"[CreateListBoxNavigation] Navigation buttons added for: {target}");

        return arrowPanel;
    }





    /// <summary>
    /// Creates and styles a RadioButton control.
    /// </summary>
    /// <param name = "text">The text for the RadioButton.</param>
    /// <param name = "autoSize">Indicates if the RadioButton should automatically size itself.</param>
    /// <param name = "isChecked">Indicates if the RadioButton is initially checked.</param>
    /// <returns>A styled <see cref = "RadioButton"/> control.</returns>
    public static RadioButton CreateRadioButton(string text, bool autoSize = true, bool isChecked = false)
    {
        var radioButton = new RadioButton
        {
            Text = text,
            AutoSize = autoSize,
            Dock = DockStyle.Fill,
            TextAlign = ContentAlignment.MiddleLeft,
            Checked = isChecked,
        };
        CPHLogger.LogV($"RadioButton created. Properties: Text=\"{radioButton.Text}\", AutoSize={radioButton.AutoSize}, Dock={radioButton.Dock}, " + $"TextAlign={radioButton.TextAlign}, Checked={radioButton.Checked}");
        return radioButton;
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
            Margin = margin ?? new Padding(5),
            Padding = padding ?? new Padding(5),
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
                btn.Width = 130;
                btn.Margin = new Padding(1, 3, 1, 1);
                btn.Padding = new Padding(2, 2, 2, 2);
                btn.FlatAppearance.BorderSize = 1;
                btn.FlatAppearance.BorderColor = Constants.Border;
                break;
            case Constants.ButtonStyle.ArrowBtn:
                btn.Width = 20;
                btn.Height = 20;
                btn.Margin = new Padding(1, 0, 1, 0);
                btn.Padding = new Padding(0, 0, 0, 0);
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
            Margin = margin ?? new Padding(5),
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
    /// <param name="items">A list of string items to populate the ComboBox.</param>
    /// <param name="isDropDownList">If true, the ComboBox will be in DropDownList mode (prevents free text input).</param>
    /// <param name="defaultSelectedIndex">The default selected index (if any).</param>
    /// <returns>A styled ComboBox control.</returns>
    public static ComboBox CreateComboBox(List<string> items, bool isDropDownList = true, int defaultSelectedIndex = 0)
    {
        // Initialize the ComboBox
        var comboBox = new ComboBox
        {
            Dock = DockStyle.Fill, // Fills its container
            DropDownStyle = isDropDownList ? ComboBoxStyle.DropDownList : ComboBoxStyle.DropDown, // DropDownList restricts selection to predefined items
            Margin = new Padding(5), // Adds consistent spacing
            Font = new Font("Segoe UI", 10), // Standard font
            ForeColor = Constants.PrimaryText, // Text color
            BackColor = Constants.Surface // Background color
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
            WrapContents = wrapContents,
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
            ForeColor = Constants.PrimaryText            
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
    public enum StartupMode {Yes, No, Prompt,}
    public enum ButtonStyle {Default, Primary, Longer, ArrowBtn, FlowControl,}    
    public enum RowStyling {Default, Distributed, Custom,}
    public enum ColumnStyling {Default, Distributed, Custom,}
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


    // Prebuilt Logging Methods. 
    public static void logProcessDetails(Process currentProcess)
    {
        if (currentProcess == null) CPHLogger.LogE("Process object is null. Unable to log process details.");

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


/// <summary>
/// A base class that serves as a foundation for shared resources or functionality.
/// </summary>
public class SB
{
    public static IInlineInvokeProxy CPH;
    public static Dictionary<string, object> args;
}
