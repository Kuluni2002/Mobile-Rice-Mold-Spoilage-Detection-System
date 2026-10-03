import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_colors.dart';

class PinLoginScreen extends StatefulWidget {
  const PinLoginScreen({super.key});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  String _enteredPin = '';
  String _errorMessage = '';
  int _attempts = 0;
  
  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }
  
  Future<void> _checkBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    final useBiometric = prefs.getBool(AppConstants.keyUseBiometric) ?? false;
    
    if (useBiometric) {
      // TODO: Implement biometric authentication in future
      // For now, just show the PIN entry
    }
  }
  
  void _onNumberPressed(String number) {
    setState(() {
      _errorMessage = '';
      
      if (_enteredPin.length < 4) {
        _enteredPin += number;
        
        if (_enteredPin.length == 4) {
          _verifyPin();
        }
      }
    });
  }
  
  void _onBackspace() {
    setState(() {
      _errorMessage = '';
      
      if (_enteredPin.isNotEmpty) {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      }
    });
  }
  
  Future<void> _verifyPin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString(AppConstants.keyPinCode);
    
    if (_enteredPin == savedPin) {
      // Success
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } else {
      // Failed
      _attempts++;
      
      setState(() {
        _errorMessage = 'Incorrect PIN. ${3 - _attempts} attempts remaining.';
        _enteredPin = '';
      });
      
      if (_attempts >= 3) {
        setState(() {
          _errorMessage = 'Too many attempts. Please try again later.';
        });
        
        // TODO: Implement lockout mechanism
        await Future.delayed(const Duration(seconds: 30));
        
        setState(() {
          _attempts = 0;
          _errorMessage = '';
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            
            // App logo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.grain,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Welcome Back',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 8),
            
            Text(
              'Enter your PIN to continue',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 48),
            
            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _enteredPin.length;
                
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
            ),
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
            
            // Number pad (reuse from PIN setup)
            _buildNumberPad(),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
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