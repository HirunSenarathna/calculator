import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'button_values.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _displayValue = '';
  String _expression = '';
  String _result = '';
  bool _showResultOnly = false;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.all(24),
                color: Colors.black,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!_showResultOnly)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true, // Ensures focus remains at the end of the expression
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _expression.isEmpty ? " " : _expression,
                              style: const TextStyle(fontSize: 36, color: Colors.white54),
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true, // Ensures focus remains at the end of the result
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _displayValue.isNotEmpty ? _displayValue : _result,
                            style: TextStyle(
                              fontSize: _showResultOnly ? 64 : 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Wrap(
              children: Btn.buttonValues.map(
                    (value) => SizedBox(
                  width: screenSize.width / 4,
                  height: screenSize.width / 5,
                  child: buildButton(value),
                ),
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildButton(value) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Material(
        color: getBtnColor(value),
        clipBehavior: Clip.hardEdge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
        child: InkWell(
          onTap: () => _onButtonPressed(value),
          child: Center(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onButtonPressed(String value) {
    setState(() {
      // If in result mode after a calculation, start a new expression
      if (_showResultOnly) {
        if (value == Btn.clr) {
          _onClear();
          return;
        }
        if (value == Btn.del) {
          _onClearEntry();
          return;
        }
        if (isOperator(value)) {
          _expression = _result + value;
          _showResultOnly = false;
        } else if (value == Btn.squareRoot) {
          _expression = 'sqrt($_result';
          _showResultOnly = false;
        } else {
          _expression = value;
          _showResultOnly = false;
        }
        _result = ''; // Clear result display until = is pressed again
        return;
      }

      // Regular button handling when not in result mode
      if (value == Btn.clr) {
        _onClear();
      } else if (value == Btn.del) {
        _onClearEntry();
      } else if (value == Btn.calculate) {
        _onEnter();
      } else if (value == Btn.squareRoot) {
        _expression += 'sqrt(';
      } else {
        if (isOperator(value) && isOperator(_expression[_expression.length - 1])) {
          _expression = _expression.substring(0, _expression.length - 1) + value;
        } else {
          _expression += value;
        }
      }
    });
  }

  bool isOperator(String value) {
    return value == Btn.add || value == Btn.subtract || value == Btn.multiply || value == Btn.divide || value == Btn.per;
  }

  void _onEnter() {
    try {
      // Validate the expression
      if (_expression.isEmpty || _expression.trim().split('').every((char) => isOperator(char))) {
        throw Exception('Error');
      }

      // Balance any open parentheses in the expression
      int openParens = 'sqrt('.allMatches(_expression).length;
      int closeParens = ')'.allMatches(_expression).length;
      _expression += ')' * (openParens - closeParens);

      // Replace custom operators with valid math symbols
      String parsedExpression = _expression
          .replaceAll(Btn.multiply, '*')
          .replaceAll(Btn.divide, '/')
          .replaceAll(Btn.per, '/100');


      // Check for division by zero
      if (RegExp(r'/\s*0(\s|$|\))').hasMatch(parsedExpression)) {
        print("Division by zero detected!");
        throw Exception('Division by zero');
      }

      // Parse and evaluate the expression
      Parser parser = Parser();
      Expression exp = parser.parse(parsedExpression);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      String formattedResult = eval.toStringAsFixed(6);

      if (formattedResult.contains('.')) {
        formattedResult = formattedResult.replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
      }
      if (formattedResult.length > 10) {
        formattedResult = eval.toStringAsExponential(6);
      }


      // Update state with the result
      setState(() {
        _result = formattedResult;  // Show result in the display value
        _displayValue = _result;    // Display the result
        _expression = '';           // Clear the expression
        _showResultOnly = true;
      });
    } catch (e) {
      print("Error caught: $e");
      // Handle errors
      setState(() {
        _displayValue = 'Error'; // Display "Error"
        _result = '';            // Clear any previous result
        _expression = '';        // Clear the
        _showResultOnly = true;  // Ensure result mode is activated
      });
    }
  }


  void _onClear() {
    setState(() {
      _displayValue = '';
      _expression = '';
      _result = '';
      _showResultOnly = false;
    });
  }

  void _onClearEntry() {
    setState(() {
      if (_expression.length > 1) {
        _expression = _expression.substring(0, _expression.length - 1);
      } else {
        _onClear();
      }
    });
  }


  Color getBtnColor(value) {
    return [Btn.del, Btn.clr].contains(value)
        ? Colors.blueGrey
        : [Btn.per, Btn.multiply, Btn.subtract, Btn.divide, Btn.calculate, Btn.add, Btn.squareRoot].contains(value)
        ? Colors.orange
        : Colors.black;
  }
}