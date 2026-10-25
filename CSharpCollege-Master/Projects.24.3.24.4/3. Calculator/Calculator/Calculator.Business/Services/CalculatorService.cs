using Calculator.Business.Models;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Calculator.Business.Services
{
    public class CalculatorService
    {
        public void PressDigit(CalculatorModel calculatorModel, string digitString)
        {
            if (!int.TryParse(digitString, out var digit))
            {
                return;
            }

            var inputText = calculatorModel.IsLastDigitPressed ? calculatorModel.InputText : "0";

            if (inputText == "0")
            {
                inputText = digit.ToString();
            }
            else if (inputText == "-0")
            {
                inputText = "-" + digit;
            }
            else
            {
                inputText += digit;
            }

            SetInputText(calculatorModel, inputText);
        }

        public void PressDecimalPoint(CalculatorModel calculatorModel)
        {
            if (!calculatorModel.IsLastDigitPressed)
            {
                SetInputText(calculatorModel, "0.");
                return;
            }

            if (calculatorModel.InputText.Contains("."))
            {
                return;
            }

            SetInputText(calculatorModel, calculatorModel.InputText + ".");
        }

        public void PressBackspace(CalculatorModel calculatorModel)
        {
            if (!calculatorModel.IsLastDigitPressed)
            {
                return;
            }

            var inputText = calculatorModel.InputText.Substring(0, calculatorModel.InputText.Length - 1);
            if (inputText == "" || inputText == "-")
            {
                inputText = "0";
            }

            SetInputText(calculatorModel, inputText);
        }

        public void PressChangeSign(CalculatorModel calculatorModel)
        {
            if (!calculatorModel.IsLastDigitPressed)
            {
                calculatorModel.RegisterX = -calculatorModel.RegisterX;
                return;
            }

            var inputText = calculatorModel.InputText;
            SetInputText(calculatorModel, inputText.StartsWith("-") ? inputText.Substring(1) : "-" + inputText);
        }

        public void PressFunction(CalculatorModel calculatorModel, string functionCode)
        {
            switch (functionCode)
            {
                case "π":
                    calculatorModel.RegisterX = Math.PI;
                    break;

                case "x²":
                    calculatorModel.RegisterX = calculatorModel.RegisterX * calculatorModel.RegisterX;
                    break;

                case "n!":
                    calculatorModel.RegisterX = Factorial(calculatorModel.RegisterX);
                    break;

                default:
                    return;
            }

            calculatorModel.IsLastDigitPressed = false;
        }

        public void PressClear(CalculatorModel calculatorModel)
        {
            calculatorModel.RegisterX = 0;
            calculatorModel.IsLastDigitPressed = false;
        }

        public void PressMoveXToY(CalculatorModel calculatorModel)
        {
            calculatorModel.RegisterY = calculatorModel.RegisterX;
            calculatorModel.IsLastDigitPressed = false;
        }

        public void PressOperation(CalculatorModel calculatorModel, string operationCode)
        {
            CompleteOperation(calculatorModel);

            PressMoveXToY(calculatorModel);
            calculatorModel.OperationCode = operationCode;
            calculatorModel.IsLastDigitPressed = false;
        }

        public void PressEqual(CalculatorModel calculatorModel)
        {
            CompleteOperation(calculatorModel);
            calculatorModel.OperationCode = null;
            calculatorModel.IsLastDigitPressed = false;
        }

        private void CompleteOperation(CalculatorModel calculatorModel)
        {
            switch (calculatorModel.OperationCode)
            {
                case "+":
                    calculatorModel.RegisterX = calculatorModel.RegisterX + calculatorModel.RegisterY;
                    break;

                case "-":
                    calculatorModel.RegisterX = calculatorModel.RegisterY - calculatorModel.RegisterX;
                    break;

                case "*":
                    calculatorModel.RegisterX = calculatorModel.RegisterX * calculatorModel.RegisterY;
                    break;

                case "/":
                    calculatorModel.RegisterX = calculatorModel.RegisterX == 0
                        ? double.NaN // деление на ноль
                        : calculatorModel.RegisterY / calculatorModel.RegisterX;
                    break;
            }
        }

        private static void SetInputText(CalculatorModel calculatorModel, string inputText)
        {
            calculatorModel.InputText = inputText;
            calculatorModel.RegisterX = double.Parse(inputText, CultureInfo.InvariantCulture);
            calculatorModel.IsLastDigitPressed = true;
        }

        /// <summary>
        /// Факториал определен только для целых чисел от 0 до 170 (171! не помещается в double)
        /// </summary>
        private static double Factorial(double value)
        {
            if (value < 0 || value > 170 || Math.Truncate(value) != value)
            {
                return double.NaN;
            }

            double result = 1;
            for (var i = 2; i <= value; i++)
            {
                result *= i;
            }

            return result;
        }
    }
}
