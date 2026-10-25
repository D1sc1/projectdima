using AlarmClock.Models;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace AlarmClock.Forms
{
    public partial class AwakeForm : Form
    {
        private const string ImageFolderName = "Images";

        /// <summary>
        /// На сколько минут откладывается будильник кнопкой "Отложить"
        /// </summary>
        private const int SnoozeMinutes = 5;

        private string[] _imageFileNames;

        private int _imageIndex;

        public AlarmState AlarmState { get; set; }

        /// <summary>
        /// Пользователь отложил будильник
        /// </summary>
        public bool IsSnoozed { get; private set; }

        public AwakeForm()
        {
            InitializeComponent();
        }

        private void AwakeForm_Load(object sender, EventArgs e)
        {
            Text = AlarmState.AlarmMessage;
            InitializeImages();
        }

        private void InitializeImages()
        {
            _imageFileNames = Directory.EnumerateFiles(ImageFolderName).ToArray();
            _imageIndex = 0;
            AwakePictureBox.Load(_imageFileNames[_imageIndex]);
        }

        private void AwakeTimer_Tick(object sender, EventArgs e)
        {
            _imageIndex++;
            if (_imageIndex >= _imageFileNames.Length)
            {
                _imageIndex = 0;
            }

            AwakePictureBox.Load(_imageFileNames[_imageIndex]);
        }

        private void SnoozeButton_Click(object sender, EventArgs e)
        {
            IsSnoozed = true;
            Close();
        }

        private void AwakeForm_FormClosed(object sender, FormClosedEventArgs e)
        {
            if (IsSnoozed)
            {
                AlarmState.AlarmTime = DateTime.Now.AddMinutes(SnoozeMinutes);
            }
            else
            {
                AlarmState.IsAlarmActive = false;
            }

            AlarmState.IsAwakeActivated = false;
        }
    }
}
