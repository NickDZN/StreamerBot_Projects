using System;
using System.Collections.Generic;
using System.Windows.Forms;
using Newtonsoft.Json;

public class CPHInline
{
    // Main execution method for this class
    public bool Execute()
    {
        CPH.LogInfo("Loading Box");

        // Define the message and caption for the MessageBox
        string message = "Do you want to run the startup scripts?";
        string caption = "Startup Process Confirmation";

        MessageBoxButtons buttons = MessageBoxButtons.YesNo;

        // Create an invisible, topmost form to ensure the MessageBox appears in front
        Form topMostForm = CreateTempInvisibleWindow();
        DialogResult result = MessageBox.Show(topMostForm, message, caption, buttons, MessageBoxIcon.Question);
        topMostForm.Close();

        // Process the result from the MessageBox
        if (result == DialogResult.Yes)
        {
            CPH.LogInfo("User chose to run startup scripts.");
            CPH.RunAction("[02] StartingStreamActions", true);
        }
        else
        {
            CPH.LogInfo("User chose not to run startup scripts.");
        }

        return true;
    }

    // Method to create a temporary, invisible form that can be used as the owner for the MessageBox
    public Form CreateTempInvisibleWindow()
    {
        // Create a new instance of Form to act as the topmost window
        Form topMostForm = new Form();

        topMostForm.StartPosition = FormStartPosition.Manual;
        topMostForm.Width = 1;
        topMostForm.Height = 1;
        topMostForm.ShowInTaskbar = false;
        topMostForm.Opacity = 0;
        topMostForm.TopMost = true;

        topMostForm.Show();

        return topMostForm;
    }
}
