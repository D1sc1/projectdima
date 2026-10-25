using Calculator.Business.Models;
using Calculator.Business.Services;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace Calculator
{
    public partial class CalculatorForm : Form
    {
        private CalculatorModel _calculatorModel = new CalculatorModel();

        private CalculatorService _calculatorService = new CalculatorService();

        public CalculatorForm()
        {
            InitializeComponent();
        }

        private void DigitButton_Click(object sender, EventArgs e)
        {
            var digitString = ((Button)sender).Text;
            _calculatorService.PressDigit(_calculatorModel, digitString);
            DisplayResult();
        }

        private void DisplayResult()
        {
            DisplayLabel.Text = _calculatorModel.DisplayText;
        }

        private void ClearButton_Click(object sender, EventArgs e)
        {
            _calculatorService.PressClear(_calculatorModel);
            DisplayResult();
        }

        private void MoveXToYButton_Click(object sender, EventArgs e)
        {
            _calculatorService.PressMoveXToY(_calculatorModel);
            DisplayResult();
        }

        private void OperationButton_Click(object sender, EventArgs e)
        {
            var operationCode = ((Button)sender).Text;
            _calculatorService.PressOperation(_calculatorModel, operationCode);
            DisplayResult();
        }

        private void EqualButton_Click(object sender, EventArgs e)
        {
            _calculatorService.PressEqual(_calculatorModel);
            DisplayResult();
        }

        private void DecimalPointButton_Click(object sender, EventArgs e)
        {
            _calculatorService.PressDecimalPoint(_calculatorModel);
            DisplayResult();
        }

        private void ChangeSignButton_Click(object sender, EventArgs e)
        {
            _calculatorService.PressChangeSign(_calculatorModel);
            DisplayResult();
        }

        private void BackspaceButton_Click(object sender, EventArgs e)
        {
            _calculatorService.PressBackspace(_calculatorModel);
            DisplayResult();
        }

        private void FunctionButton_Click(object sender, EventArgs e)
        {
            var functionCode = ((Button)sender).Text;
            _calculatorService.PressFunction(_calculatorModel, functionCode);
            DisplayResult();
        }
    }
}
