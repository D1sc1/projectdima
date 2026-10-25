using Calculator.Business.Models;
using Calculator.Business.Services;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Calculator.Wpf.ViewModels
{
    public class MainWindowViewModel : INotifyPropertyChanged
    {
        private readonly CalculatorModel _calculatorModel = new CalculatorModel();

        private readonly CalculatorService _calculatorService = new CalculatorService();

        public event PropertyChangedEventHandler PropertyChanged;

        public string DisplayValue => _calculatorModel.DisplayText;

        public void PressDigit(string digitString)
        {
            _calculatorService.PressDigit(_calculatorModel, digitString);
            OnPropertyChanged(nameof(DisplayValue)); // "DisplayValue"
        }

        public void PressClear()
        {
            _calculatorService.PressClear(_calculatorModel);
            OnPropertyChanged(nameof(DisplayValue));
        }

        public void PressOperatin(string operationCode)
        {
            _calculatorService.PressOperation(_calculatorModel, operationCode);
            OnPropertyChanged(nameof(DisplayValue));
        }

        public void PressEqual()
        {
            _calculatorService.PressEqual(_calculatorModel);
            OnPropertyChanged(nameof(DisplayValue));
        }

        public void PressDecimalPoint()
        {
            _calculatorService.PressDecimalPoint(_calculatorModel);
            OnPropertyChanged(nameof(DisplayValue));
        }

        public void PressChangeSign()
        {
            _calculatorService.PressChangeSign(_calculatorModel);
            OnPropertyChanged(nameof(DisplayValue));
        }

        public void PressBackspace()
        {
            _calculatorService.PressBackspace(_calculatorModel);
            OnPropertyChanged(nameof(DisplayValue));
        }

        public void PressFunction(string functionCode)
        {
            _calculatorService.PressFunction(_calculatorModel, functionCode);
            OnPropertyChanged(nameof(DisplayValue));
        }

        private void OnPropertyChanged(string propertyName)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}
