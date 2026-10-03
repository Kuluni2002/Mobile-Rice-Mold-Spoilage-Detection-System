import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_colors.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String _errorMessage = '';
  
  void _onNumberPressed(String number) {
    setState(() {
      _errorMessage = '';
      
      if (!_isConfirming) {
        if (_pin.length < 4) {
          _pin += number;
          
          if (_pin.length == 4) {
            // Move to confirmation
            Future.delayed(const Duration(milliseconds: 300), () {
              setState(() {
                _isConfirming = true;
              });
            });
          }
        }
      } else {
        if (_confirmPin.length < 4) {
          _confirmPin += number;
          
          if (_confirmPin.length == 4) {
            _verifyAndSavePin();
          }
        }
      }
    });
  }
  
  void _onBackspace() {
    setState(() {
      _errorMessage = '';
      
      if (!_isConfirming) {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      }
    });
  }
  
  Future<void> _verifyAndSavePin() async {
    if (_pin != _confirmPin) {
      setState(() {
        _errorMessage = 'PINs do not match. Please try again.';
        _confirmPin = '';
      });
      return;
    }
    
    // Save PIN
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyPinCode, _pin);
    
    if (!mounted) return;
    
    // Show success and navigate
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PIN setup successful!'),
        backgroundColor: AppColors.healthy,
      ),
    );
    
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }
  
  void _reset() {
    setState(() {
      _pin = '';
      _confirmPin = '';
      _isConfirming = false;
      _errorMessage = '';
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup PIN'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            
            // Title
            Text(
              _isConfirming ? 'Confirm Your PIN' : 'Create Your PIN',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            
            Text(
              _isConfirming 
                  ? 'Re-enter your 4-digit PIN'
                  : 'Enter a 4-digit PIN to secure your app',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            
            // PIN dots display
            _buildPinDots(),
            const SizedBox(height: 16),
            
            // Error message
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _errorMessage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.spoiled,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            
            const Spacer(),
            
            // Number pad
            _buildNumberPad(),
            
            // Reset button (only in confirmation mode)
            if (_isConfirming)
              TextButton(
                onPressed: _reset,
                child: const Text('Start Over'),
              ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPinDots() {
    final currentPin = _isConfirming ? _confirmPin : _pin;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = index < currentPin.length;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? AppColors.primary : Colors.transparent,
            border: Border.all(
              color: isFilled ? AppColors.primary : AppColors.divider,
              width: 2,
            ),
          ),
        );
      }),
    );
  }
  
  Widget _buildNumberPad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          _buildNumberRow(['1', '2', '3']),
          const SizedBox(height: 16),
          _buildNumberRow(['4', '5', '6']),
          const SizedBox(height: 16),
          _buildNumberRow(['7', '8', '9']),
          const SizedBox(height: 16),
          _buildNumberRow(['', '0', 'backspace']),
        ],
      ),
    );
  }
  
  Widget _buildNumberRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) {
        if (number.isEmpty) {
          return const SizedBox(width: 70, height: 70);
        }
        
        if (number == 'backspace') {
          return _buildNumberButton(
            icon: Icons.backspace_outlined,
            onPressed: _onBackspace,
          );
        }
        
        return _buildNumberButton(
          text: number,
          onPressed: () => _onNumberPressed(number),
        );
      }).toList(),
    );
  }
  
  Widget _buildNumberButton({
    String? text,
    IconData? icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(35),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.divider),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, size: 28, color: AppColors.textPrimary)
              : Text(
                  text!,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
        ),
      ),
    );
  }
}