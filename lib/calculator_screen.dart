// IM/2021/004
// Hirun Senarathna

import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'button_values.dart';
import 'history_screen.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  //Variables to store the display value, expression, result, and a flag to show result-only mode
  String _displayValue = '';
  String _expression = '';
  String _result = '';
  bool _showResultOnly = false;
  List<String> _history = []; // List to store calculation history


  @override
  Widget build(BuildContext context) {
    // Get screen size for dynamic button sizing
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,// Black background for calculator
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Calculator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Navigate to history screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryScreen(history: _history
                  , onClearHistory: _clearHistory,),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Display area for the calculator
            Expanded(
              child: Container(
                alignment: Alignment.bottomRight,// Align text to the bottom-right
                padding: const EdgeInsets.all(24),// Padding for text spacing
                color: Colors.black,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Show the input expression if not in result-only mode
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
                    const SizedBox(height: 8),// Spacing between expression and result
                    // Show the result
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
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
                  width: screenSize.width / 4,// 4 buttons per row
                  height: screenSize.width / 5,// Dynamic button size
                  child: buildButton(value),// Create each button
                ),
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Builds a button widget with the given value
  Widget buildButton(value) {
    return Padding(
      padding: const EdgeInsets.all(4.0),// Spacing around the button
      child: Material(
        color: getBtnColor(value),// Assign color based on button type
        clipBehavior: Clip.hardEdge, // Ensures the button edges are clipped
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),// round buttons
        ),
        child: InkWell(
          onTap: () => _onButtonPressed(value),// Handle button press
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

  // Handle button press
  void _onButtonPressed(String value) {
    setState(() {
      // If in result mode after a calculation, start a new expression
      if (_showResultOnly) {
        if (value == Btn.clr) {
          _onClear();// Clear all if "clear" is pressed
          return;
        }
        if (value == Btn.del) {
          _onClearEntry();// Clear last entry if "delete" is pressed
          return;
        }
        if (isOperator(value)) {
          _expression = _result + value;// Start a new expression with the result
          _showResultOnly = false;

        } else if (value == Btn.squareRoot) {
          _expression = 'sqrt($_result';// Begin square root of the result
          _showResultOnly = false;
        } else {
          _expression = value;// Start with the new value
          _showResultOnly = false;
        }
        _result = ''; // Clear result display until = is pressed again
        return;
      }

      // Regular button handling when not in result mode
      if (value == Btn.clr) {
        _onClear();// Clear all
      } else if (value == Btn.del) {

        _onClearEntry();// Delete last character
      } else if (value == Btn.calculate) {
        _onEnter();// Calculate the expression

      } else if (value == Btn.squareRoot) {
        _expression += 'sqrt(';// Add "sqrt(" to the expression
      } else {

        // Prevent invalid numeric formats
        if (value == '.' &&
            (_expression.isEmpty || _expression.endsWith('.') || isOperator(_expression[_expression.length - 1]))) {
          return; // Disallow multiple or misplaced decimal points
        }
        if (value == '.' && _expression.split(RegExp(r'[^0-9.]')).last.contains('.')) {
          return; // Disallow multiple decimals in the same number
        }

        // Avoid consecutive operators
        if (_expression.isNotEmpty && isOperator(value) && isOperator(_expression[_expression.length - 1])) {
          _expression = _expression.substring(0, _expression.length - 1) + value;
        } else {
          _expression += value;// Append the value to the expression
        }
      }
    });
  }

  // Checks if the value is an operator
  bool isOperator(String value) {
    return value == Btn.add || value == Btn.subtract || value == Btn.multiply || value == Btn.divide || value == Btn.per;
  }

  // Evaluates the expression and calculates the result
  void _onEnter() {
    try {
      // Validate the expression
      if (_expression.isEmpty || _expression.trim().split('').every((char) => isOperator(char))) {
        throw Exception('Error');// Handle invalid expressions
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

      // Check for invalid square root arguments
      RegExp sqrtNegativeCheck = RegExp(r'sqrt\((\s*-.*?\s*)\)');
      if (sqrtNegativeCheck.hasMatch(parsedExpression)) {
        print("Negative value under square root detected!");
        throw Exception('Error');
      }

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

      // Format the result for display
      String formattedResult = eval.toStringAsFixed(6);
      if (formattedResult.contains('.')) {
        formattedResult = formattedResult.replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
      }
      if (formattedResult.length > 10) {
        formattedResult = eval.toStringAsExponential(6);
      }

      // Update state with the result
      setState(() {
        _history.add("$_expression = $formattedResult"); // Save both expression and result
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
        _expression = '';        // Clear the expression
        _showResultOnly = true;  // Ensure result mode is activated
      });
    }
  }


  // Clears all input and result
  void _onClear() {
    setState(() {
      _displayValue = '';
      _expression = '';
      _result = '';
      _showResultOnly = false;
    });
  }

  //clear history
  void _clearHistory() {
    setState(() {
      _history.clear();
    });
  }

  // Deletes the last character of the current expression
  void _onClearEntry() {
    setState(() {
      if (_expression.length > 1) {
        _expression = _expression.substring(0, _expression.length - 1);
      } else {
        _onClear();// Clear everything if only one character remains
      }
    });
  }

// Determines button color based on type
  Color getBtnColor(value) {
    return [Btn.del, Btn.clr].contains(value)
        ? Colors.blueGrey
        : [Btn.per, Btn.multiply, Btn.subtract, Btn.divide, Btn.calculate, Btn.add, Btn.squareRoot].contains(value)
        ? Colors.orange
        : Colors.black;
  }
}