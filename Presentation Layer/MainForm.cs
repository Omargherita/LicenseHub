using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace Presentation_Layer
{
    public partial class MainForm : Form
    {
        public MainForm()
        {
            InitializeComponent();
            this.DoubleBuffered = true;
            pbMainLogo.SendToBack();
        }

        private void button4_Click(object sender, EventArgs e)
        {

        }

        private void Form1_Load(object sender, EventArgs e)
        {
            UpdateLayout();
        }

        private void button3_Click(object sender, EventArgs e)
        {

        }

        private void button2_Click(object sender, EventArgs e)
        {

        }

        private void button5_Click(object sender, EventArgs e)
        {

        }

        private void button1_Click(object sender, EventArgs e)
        {

        }

        private void MainForm_Resize(object sender, EventArgs e)
        {
            UpdateLayout();
        }

        // Vibecoded method just to improve main menu UX, nothing more
        private void UpdateLayout()
        {
            if (this.ClientSize.Width <= 0 || this.ClientSize.Height <= 0)
                return;

            this.SuspendLayout();

            // 1. Center the buttons horizontally
            flowLayoutPanel1.Left = (this.ClientSize.Width - flowLayoutPanel1.Width) / 2;

            // 2. Calculate logo dimensions maintaining aspect ratio
            double aspectRatio = 1936.0 / 455.0; // Default aspect ratio of the logo
            if (pbMainLogo.Image != null && pbMainLogo.Image.Height > 0)
            {
                aspectRatio = (double)pbMainLogo.Image.Width / pbMainLogo.Image.Height;
            }

            // Proportional logo height based on form height (scales nicely with window resize)
            int targetLogoHeight = (int)(this.ClientSize.Height * 0.17);
            targetLogoHeight = Math.Max(65, Math.Min(170, targetLogoHeight));
            int targetLogoWidth = (int)(targetLogoHeight * aspectRatio);

            // Constrain logo width to fit form width with margin
            int maxLogoWidth = Math.Max(100, (int)(this.ClientSize.Width * 0.85));
            if (targetLogoWidth > maxLogoWidth)
            {
                targetLogoWidth = maxLogoWidth;
                targetLogoHeight = (int)(targetLogoWidth / aspectRatio);
            }

            // 3. Vertical layout positioning
            int buttonsHeight = flowLayoutPanel1.Height;
            int minBottomMargin = 20;
            int minTopMargin = 15;
            int minGap = 20; // Minimum clearance between bottom of logo and top of buttons

            // Position buttons in lower-middle area
            int buttonsTop = ((this.ClientSize.Height - buttonsHeight) / 2) + 80;

            // Ensure buttons do not overflow form bottom
            if (buttonsTop + buttonsHeight > this.ClientSize.Height - minBottomMargin)
            {
                buttonsTop = this.ClientSize.Height - buttonsHeight - minBottomMargin;
            }

            // Space available above buttons
            int spaceAbove = buttonsTop;
            int maxAllowedLogoHeight = spaceAbove - minGap - minTopMargin;
            if (maxAllowedLogoHeight >= 40 && targetLogoHeight > maxAllowedLogoHeight)
            {
                targetLogoHeight = maxAllowedLogoHeight;
                targetLogoWidth = (int)(targetLogoHeight * aspectRatio);
            }

            pbMainLogo.Size = new Size(targetLogoWidth, targetLogoHeight);

            // Center logo horizontally
            pbMainLogo.Left = (this.ClientSize.Width - pbMainLogo.Width) / 2;

            // Center logo vertically in the space above buttons
            int logoTop = (buttonsTop - pbMainLogo.Height) / 2;
            if (logoTop < minTopMargin)
            {
                logoTop = minTopMargin;
            }
            pbMainLogo.Top = logoTop;

            // Strict guarantee: buttons must never be higher than logo bottom + minGap
            if (buttonsTop < pbMainLogo.Bottom + minGap)
            {
                buttonsTop = pbMainLogo.Bottom + minGap;
            }

            flowLayoutPanel1.Top = buttonsTop;

            this.ResumeLayout();
        }

        private void label1_Click(object sender, EventArgs e)
        {

        }
    }
}
