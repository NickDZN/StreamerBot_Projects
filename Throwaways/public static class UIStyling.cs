public static class UIStyling
{
    public static void StyleNumberUpDown(NumericUpDown numericUpDown)
    {
        numericUpDown.Width = 40;
        numericUpDown.Minimum = 0;
        numericUpDown.Maximum = 30;
        numericUpDown.Value = 2;
        numericUpDown.Anchor = AnchorStyles.Left;
        numericUpDown.Margin = new Padding(2, 0, 0, 0);
        // Verbose logging with all properties and object name
        CPHLogger.LogDebug($"Styled NumericUpDown (Name={numericUpDown.Name}): Width={numericUpDown.Width}, Height={numericUpDown.Height}, " + $"Min={numericUpDown.Minimum}, Max={numericUpDown.Maximum}, Value={numericUpDown.Value}, " + $"Anchor={numericUpDown.Anchor}, Margin={numericUpDown.Margin}, Padding={numericUpDown.Padding}, " + $"TextAlign={numericUpDown.TextAlign}");
    }

    public static void StyleRadioButton(RadioButton radioButton, string prompt)
    {
        radioButton.Text = prompt;
        radioButton.AutoSize = true;
        radioButton.Dock = DockStyle.Fill;
        radioButton.TextAlign = ContentAlignment.MiddleLeft;
        // Verbose logging with all properties and object name
        CPHLogger.LogDebug($"Styled RadioButton (Name={radioButton.Name}): Width={radioButton.Width}, Height={radioButton.Height}, " + $"Text={radioButton.Text}, AutoSize={radioButton.AutoSize}, Dock={radioButton.Dock}, " + $"TextAlign={radioButton.TextAlign}, Checked={radioButton.Checked}, Margin={radioButton.Margin}, " + $"Padding={radioButton.Padding}, Font={radioButton.Font.Name}");
    }

    public static void StyleLabel(Label label, string labelText)
    {
        label.Text = labelText;
        label.AutoSize = true;
        label.Dock = DockStyle.Fill;
        label.TextAlign = ContentAlignment.MiddleLeft;
        // Verbose logging with all properties and object name
        CPHLogger.LogDebug($"Styled Label (Name={label.Name}): Width={label.Width}, Height={label.Height}, Text={label.Text}, " + $"AutoSize={label.AutoSize}, Dock={label.Dock}, TextAlign={label.TextAlign}, " + $"Margin={label.Margin}, Padding={label.Padding}, Font={label.Font.Name}");
    }


    public static void StyleListBox(ListBox listBox)
    {
        listBox.Font = new Font("Segoe UI", 10, FontStyle.Regular);
        listBox.BackColor = Color.White;
        listBox.ForeColor = Color.Black;
        listBox.BorderStyle = BorderStyle.FixedSingle;
        listBox.Dock = DockStyle.Fill;
        listBox.Height = 140;
        listBox.Width = 250;
        listBox.Padding = new Padding(5, 5, 5, 0);
        listBox.Margin = new Padding(5, 5, 5, 0);
        // Verbose logging with all properties and object name
        CPHLogger.LogDebug($"Styled ListBox (Name={listBox.Name}): Width={listBox.Width}, Height={listBox.Height}, Font={listBox.Font.Name}, " + $"ForeColor={listBox.ForeColor}, Dock={listBox.Dock}, Padding={listBox.Padding}, Margin={listBox.Margin}, " + $"BorderStyle={listBox.BorderStyle}");
    }

    public static void StylePanel(Panel panel, Padding? panelPadding = null)
    {
        panel.Dock = DockStyle.Fill;
        panel.AutoScroll = true;
        panel.Padding = panelPadding ?? new Padding(0);
        panel.BackColor = Color.WhiteSmoke;
        panel.BorderStyle = BorderStyle.FixedSingle;
        // Verbose logging with all properties and object name
        CPHLogger.LogDebug($"Styled Panel (Name={panel.Name}): Width={panel.Width}, Height={panel.Height}, AutoScroll={panel.AutoScroll}, " + $"Padding={panel.Padding}, BorderStyle={panel.BorderStyle}, BackColor={panel.BackColor}, Dock={panel.Dock}");
    }

    public static void StyleFlowBox(FlowLayoutPanel flowBox, FlowDirection fBoxDirection = FlowDirection.LeftToRight, // Default to LeftToRight
 bool autoWrap = true, Padding? customPadding = null, // Allow optional padding
 AnchorStyles anchorStyle = AnchorStyles.Top | AnchorStyles.Left | AnchorStyles.Right | AnchorStyles.Bottom // Default anchor
    )
    {
        flowBox.FlowDirection = fBoxDirection;
        flowBox.WrapContents = autoWrap;
        flowBox.Anchor = anchorStyle;
        flowBox.AutoSize = true;
        flowBox.AutoSizeMode = AutoSizeMode.GrowAndShrink;
        flowBox.Padding = customPadding ?? new Padding(0);
        flowBox.Margin = customPadding ?? new Padding(0);
        flowBox.BackColor = Color.WhiteSmoke;
        flowBox.BorderStyle = BorderStyle.FixedSingle;
        // Verbose logging with all properties and object name
        CPHLogger.LogDebug($"Styled FlowLayoutPanel (Name={flowBox.Name}): Width={flowBox.Width}, Height={flowBox.Height}, " + $"FlowDirection={flowBox.FlowDirection}, WrapContents={flowBox.WrapContents}, Anchor={flowBox.Anchor}, " + $"AutoSize={flowBox.AutoSize}, Padding={flowBox.Padding}, Margin={flowBox.Margin}, " + $"BackColor={flowBox.BackColor}, BorderStyle={flowBox.BorderStyle}");
    }

    public static void StyleTableLayoutPanel(TableLayoutPanel tableLayoutPanel, int columnCount = 2, int rowCount = 1, List<RowStyle> customRowStyles = null, List<ColumnStyle> customColumnStyles = null, bool autoSizeTable = true)
    {
        tableLayoutPanel.ColumnCount = columnCount;
        tableLayoutPanel.RowCount = rowCount;
        tableLayoutPanel.Dock = DockStyle.Fill;
        tableLayoutPanel.AutoSizeMode = AutoSizeMode.GrowAndShrink;
        tableLayoutPanel.Padding = new Padding(0);
        tableLayoutPanel.Margin = new Padding(0);
        tableLayoutPanel.CellBorderStyle = TableLayoutPanelCellBorderStyle.Single;
        tableLayoutPanel.AutoSize = autoSizeTable;
        if (autoSizeTable)
        {
            tableLayoutPanel.AutoSizeMode = AutoSizeMode.GrowAndShrink;
        }
        else
        {
            tableLayoutPanel.AutoSizeMode = AutoSizeMode.GrowOnly;
        }

        // Apply row styles
        for (int i = 0; i < rowCount; i++)
        {
            RowStyle rowStyle = i < customRowStyles?.Count ? customRowStyles[i] : new RowStyle(SizeType.AutoSize);
            tableLayoutPanel.RowStyles.Add(rowStyle);
        }

        // Apply column styles
        for (int i = 0; i < columnCount; i++)
        {
            ColumnStyle columnStyle = i < customColumnStyles?.Count ? customColumnStyles[i] : new ColumnStyle(SizeType.Percent, 100f / columnCount);
            tableLayoutPanel.ColumnStyles.Add(columnStyle);
        }

        // Verbose logging with all properties and object name
        CPHLogger.LogDebug($"Styled TableLayoutPanel (Name={tableLayoutPanel.Name}): Width={tableLayoutPanel.Width}, Height={tableLayoutPanel.Height}, " + $"ColumnCount={tableLayoutPanel.ColumnCount}, RowCount={tableLayoutPanel.RowCount}, AutoSize={tableLayoutPanel.AutoSize}, " + $"Padding={tableLayoutPanel.Padding}, Margin={tableLayoutPanel.Margin}, CellBorderStyle={tableLayoutPanel.CellBorderStyle}, " + $"AutoSizeMode={tableLayoutPanel.AutoSizeMode}");
        CPHLogger.LogDebug($"ColumnStyle: {string.Join(", ", tableLayoutPanel.ColumnStyles.Cast<ColumnStyle>().Select(cs => cs.SizeType.ToString()))}");
        CPHLogger.LogDebug($"RowStyle: {string.Join(", ", tableLayoutPanel.RowStyles.Cast<RowStyle>().Select(rs => rs.SizeType.ToString()))}");
    }

    public static void StyleGroupBox(GroupBox groupBox, string text = null, int? height = null)
    {
        groupBox.Font = new Font("Segoe UI", 10, FontStyle.Bold);
        groupBox.ForeColor = Color.DimGray;
        groupBox.BackColor = Color.WhiteSmoke;
        groupBox.Dock = DockStyle.Fill;
        groupBox.Padding = new Padding(2, 2, 2, 2);
        groupBox.Margin = new Padding(2, 2, 2, 2);
        groupBox.AutoSize = !height.HasValue;
        if (height.HasValue)
            groupBox.Height = height.Value;
        if (!string.IsNullOrEmpty(text))
            groupBox.Text = text;
        // Verbose logging with all properties and object name
        CPHLogger.LogDebug($"Styled GroupBox (Name={groupBox.Name}): Width={groupBox.Width}, Height={groupBox.Height}, " + $"Text={groupBox.Text}, AutoSize={groupBox.AutoSize}, Padding={groupBox.Padding}, " + $"Margin={groupBox.Margin}, BackColor={groupBox.BackColor}, ForeColor={groupBox.ForeColor}, Dock={groupBox.Dock}");
    }

    public static void StyleTabControl(TabControl tabControl)
    {
        tabControl.Dock = DockStyle.Fill;
        tabControl.Font = new Font("Segoe UI", 10, FontStyle.Regular);
        tabControl.Padding = new Point(0, 0);
        tabControl.Appearance = TabAppearance.FlatButtons; // Set tabs to flat style
        tabControl.ItemSize = new Size(120, 20); // Custom size for each tab
        tabControl.DrawMode = TabDrawMode.OwnerDrawFixed; // Enable custom drawing
        tabControl.DrawItem += (s, e) => // Define custom drawing behavior
        {
            // Fill tab background with custom color
            e.Graphics.FillRectangle(new SolidBrush(Color.WhiteSmoke), e.Bounds);
            // Draw the tab text with custom color
            TextRenderer.DrawText(e.Graphics, tabControl.TabPages[e.Index].Text, e.Font, e.Bounds, Color.Black);
        };
        // Verbose logging with all properties and object name
        CPHLogger.LogDebug($"Styled TabControl (Name={tabControl.Name}): Width={tabControl.Width}, Height={tabControl.Height}, " + $"ItemSize={tabControl.ItemSize}, TabCount={tabControl.TabPages.Count}, Padding={tabControl.Padding}, " + $"Appearance={tabControl.Appearance}, DrawMode={tabControl.DrawMode}");
    }
}





public class UIComponentFactory
{
    public class UIComponentFactory
    {
        /// <summary>
        /// Creates and styles a NumericUpDown control.
        /// </summary>
        /// <param name="width">The width of the NumericUpDown control.</param>
        /// <param name="height">The height of the NumericUpDown control.</param>
        /// <param name="minimum">The minimum value for the NumericUpDown control.</param>
        /// <param name="maximum">The maximum value for the NumericUpDown control.</param>
        /// <param name="value">The default value for the NumericUpDown control.</param>
        /// <returns>A styled <see cref="NumericUpDown"/> control.</returns>
        public static NumericUpDown CreateStyledNumericUpDown(int width = 40,
            int height = 20,
            int minimum = 0,
            int maximum = 30,
            int value = 2)
        {
            var numericUpDown = new NumericUpDown
            {
                Width = width,
                Height = height,
                Minimum = minimum,
                Maximum = maximum,
                Value = value,
                Anchor = AnchorStyles.Left,
                Margin = new Padding(2, 0, 0, 0)
            };

            // Verbose logging of all properties
            CPHLogger.LogVerbose($"NumericUpDown created. Properties: Width={numericUpDown.Width}, Height={numericUpDown.Height}, " +
                                 $"Minimum={numericUpDown.Minimum}, Maximum={numericUpDown.Maximum}, Value={numericUpDown.Value}, " +
                                 $"Anchor={numericUpDown.Anchor}, Margin={numericUpDown.Margin}");

            return numericUpDown;
        }

        /// <summary>
        /// Creates and styles a RadioButton control.
        /// </summary>
        /// <param name="text">The text for the RadioButton.</param>
        /// <param name="autoSize">Indicates if the RadioButton should automatically size itself.</param>
        /// <param name="checkedValue">Indicates if the RadioButton is initially checked.</param>
        /// <returns>A styled <see cref="RadioButton"/> control.</returns>
        public static RadioButton CreateRadioButton(string text, bool autoSize = true, bool checkedValue = false)
        {
            var radioButton = new RadioButton
            {
                Text = text,
                AutoSize = autoSize,
                Dock = DockStyle.Fill,
                TextAlign = ContentAlignment.MiddleLeft,
                Checked = checkedValue
            };

            CPHLogger.LogVerbose(
                $"RadioButton created. Properties: Text=\"{radioButton.Text}\", AutoSize={radioButton.AutoSize}, Dock={radioButton.Dock}, " +
                $"TextAlign={radioButton.TextAlign}, Checked={radioButton.Checked}");
            return radioButton;
        }

        /// <summary>
        /// Creates and styles a Label control.
        /// </summary>
        /// <param name="text">The text for the Label.</param>
        /// <param name="textAlign">The text alignment for the Label.</param>
        /// <param name="margin">Optional margin for the Label.</param>
        /// <param name="padding">Optional padding for the Label.</param>
        /// <returns>A styled <see cref="Label"/> control.</returns>
        public static Label CreateLabel(string text, ContentAlignment textAlign = ContentAlignment.MiddleLeft,
            Padding? margin = null, Padding? padding = null)
        {
            var label = new Label
            {
                Text = text,
                AutoSize = true,
                Dock = DockStyle.Fill,
                TextAlign = textAlign,
                Margin = margin ?? new Padding(5),
                Padding = padding ?? new Padding(5)
            };

            CPHLogger.LogVerbose(
                $"Label created. Properties: Text=\"{label.Text}\", AutoSize={label.AutoSize}, Dock={label.Dock}, TextAlign={label.TextAlign}, " +
                $"Margin={label.Margin}, Padding={label.Padding}");
            return label;
        }

        public static class UIElementFactory
        {
            /// <summary>
            /// Creates and styles a Button control.
            /// </summary>
            /// <param name="text">The text displayed on the button.</param>
            /// <param name="clickEvent">Optional click event handler.</param>
            /// <param name="buttonStyle">The style of the button (from <see cref="Constants.ButtonStyle"/>).</param>
            /// <param name="btnEnabled">Specifies whether the button is enabled.</param>
            /// <returns>A styled <see cref="Button"/> control.</returns>
            public static Button CreateButton(
                string text,
                EventHandler clickEvent = null,
                Constants.ButtonStyle buttonStyle = Constants.ButtonStyle.Default,
                bool btnEnabled = true)
            {
                // Create a base button with common properties
                var btn = new Button
                {
                    Text = text,
                    Height = 24,
                    Enabled = btnEnabled,
                    AutoSize = false,
                    FlatStyle = FlatStyle.Flat,
                    Font = new Font("Microsoft Sans Serif", 8.5f),
                    BackColor = Color.White,
                    ForeColor = SystemColors.ControlText
                };

                // Apply different styles based on the ButtonStyle enum
                switch (buttonStyle)
                {
                    case Constants.ButtonStyle.Primary:
                        btn.Width = 90;
                        btn.Margin = new Padding(0, 0, 0, 0);
                        btn.Padding = new Padding(2, 2, 2, 2);
                        btn.BackColor = Color.DodgerBlue;
                        btn.ForeColor = Color.White;
                        btn.FlatAppearance.BorderSize = 1;
                        btn.FlatAppearance.BorderColor = Color.RoyalBlue;
                        break;

                    case Constants.ButtonStyle.Longer:
                        btn.Width = 120;
                        btn.Margin = new Padding(1, 3, 1, 1);
                        btn.Padding = new Padding(2, 2, 2, 2);
                        btn.BackColor = Color.Gainsboro;
                        btn.ForeColor = Color.Black;
                        btn.FlatAppearance.BorderSize = 1;
                        btn.FlatAppearance.BorderColor = Color.DarkGray;
                        break;

                    case Constants.ButtonStyle.ArrowBtn:
                        btn.Width = 20;
                        btn.Height = 20;
                        btn.Margin = new Padding(1, 0, 1, 0);
                        btn.Padding = new Padding(0, 0, 0, 0);
                        btn.BackColor = Color.White;
                        btn.ForeColor = SystemColors.ControlText;
                        btn.FlatAppearance.BorderSize = 1;
                        btn.FlatAppearance.BorderColor = Color.DarkGray;
                        btn.BackgroundImageLayout = ImageLayout.Center;
                        break;

                    case Constants.ButtonStyle.FlowControl:
                        btn.Width = 100;
                        btn.Margin = new Padding(5, 2, 5, 2);
                        btn.Padding = new Padding(5, 0, 5, 0);
                        btn.BackColor = Color.White;
                        btn.ForeColor = SystemColors.ControlText;
                        btn.FlatAppearance.BorderSize = 1;
                        btn.FlatAppearance.BorderColor = Color.DarkGray;
                        btn.BackgroundImageLayout = ImageLayout.Center;
                        break;

                    default:
                        // Default style
                        btn.Width = 90;
                        btn.Margin = new Padding(0);
                        btn.Padding = new Padding(2, 2, 2, 2);
                        btn.BackColor = Color.White;
                        btn.ForeColor = SystemColors.ControlText;
                        btn.FlatAppearance.BorderSize = 1;
                        btn.FlatAppearance.BorderColor = Color.DarkGray;
                        break;
                }

                // Attach the click event handler if provided
                clickEvent?.Invoke(btn, EventArgs.Empty);

                // Verbose logging of all button properties
                CPHLogger.LogVerbose(
                    $"Button created. Properties: Text=\"{btn.Text}\", Width={btn.Width}, Height={btn.Height}, Enabled={btn.Enabled}, " +
                    $"Margin={btn.Margin}, Padding={btn.Padding}, Style={buttonStyle}, BackColor={btn.BackColor}, ForeColor={btn.ForeColor}, " +
                    $"FlatStyle={btn.FlatStyle}, BorderSize={btn.FlatAppearance.BorderSize}, BorderColor={btn.FlatAppearance.BorderColor}");

                return btn;
            }
        }

    public static TableLayoutPanel CreateTableLayoutPanel(int rowCount, int columnCount)
    {
        var tableLayout = new TableLayoutPanel
        {
            Dock = DockStyle.Fill,
            Height = 340,
            ColumnCount = columnCount,
            RowCount = rowCount,
            AutoSize = false,
            AutoSizeMode = AutoSizeMode.GrowOnly,
            CellBorderStyle = TableLayoutPanelCellBorderStyle.Single,
            Padding = new Padding(5)
        };


        
        for (int i = 0; i < columnCount; i++)
        {
            tableLayout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100f / columnCount));
        }

        for (int i = 0; i < rowCount; i++)
        {
            tableLayout.RowStyles.Add(new RowStyle(SizeType.Absolute, 340)); // Fixed height rows
        }

        CPHLogger.LogD($"TableLayoutPanel created with {rowCount} rows and {columnCount} columns.");
        return tableLayout;
    }


    }