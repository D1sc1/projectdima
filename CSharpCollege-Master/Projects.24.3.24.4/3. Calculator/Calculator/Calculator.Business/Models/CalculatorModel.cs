using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Calculator.Business.Models
{
    public class CalculatorModel
    {
        public double RegisterX { get; internal set; }

        internal double RegisterY { get; set; }

        internal string OperationCode { get; set; }

        internal bool IsLastDigitPressed { get; set; }

        /// <summary>
        /// Набираемое число в виде строки (разделитель дробной части - точка)
        /// </summary>
        internal string InputText { get; set; }

        /// <summary>
        /// Текст для индикатора: во время набора числа - набранная строка, иначе - значение регистра X.
        /// Недопустимый результат (деление на ноль, n! от дробного числа, переполнение) выводится как "Ошибка"
        /// </summary>
        public string DisplayText
        {
            get
            {
                if (IsLastDigitPressed)
                {
                    return InputText.Replace(".", CultureInfo.CurrentCulture.NumberFormat.NumberDecimalSeparator);
                }

                return double.IsNaN(RegisterX) || double.IsInfinity(RegisterX) ? "Ошибка" : RegisterX.ToString();
            }
        }
    }
}
