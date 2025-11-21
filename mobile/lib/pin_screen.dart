import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'localization.dart';

enum PinMode { setup, verify, change }

class PinScreen extends StatefulWidget {
  final PinMode mode;
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;

  const PinScreen({
    super.key,
    required this.mode,
    this.onSuccess,
    this.onCancel,
  });

  @override
  State<PinScreen> createState() => _PinScreenState();

  // Статический метод для проверки, установлен ли PIN-код
  static Future<bool> isPinSet() async {
    const String pinKey = 'app_pin_code';
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString(pinKey);
    return pin != null && pin.isNotEmpty;
  }
}

class _PinScreenState extends State<PinScreen> {
  String _enteredPin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _oldPinVerified = false; // Флаг для отслеживания проверки старого PIN
  String? _errorMessage;

  static const String _pinKey = 'app_pin_code';
  static const int _pinLength = 4;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F7);
    final textColor = isDark ? Colors.white : Colors.black87;

    return ValueListenableBuilder<Language>(
      valueListenable: AppStrings.languageNotifier,
      builder: (context, language, child) {
        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Иконка
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E3A59).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: Color(0xFF2E3A59),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Заголовок
                  Text(
                    _getTitle(),
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Подзаголовок
                  Text(
                    _getSubtitle(),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: isDark ? Colors.white70 : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Индикаторы PIN-кода
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pinLength,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: index < _getCurrentPin().length
                                  ? const Color(0xFF2E3A59)
                                  : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                              width: 2,
                            ),
                            color: index < _getCurrentPin().length
                                ? const Color(0xFF2E3A59)
                                : Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Сообщение об ошибке
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const Spacer(),

                  // Цифровая клавиатура
                  _buildNumpad(isDark, textColor),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getCurrentPin() {
    return _isConfirming ? _confirmPin : _enteredPin;
  }

  String _getTitle() {
    if (widget.mode == PinMode.setup) {
      return _isConfirming
          ? AppStrings.get('pin_confirm_title')
          : AppStrings.get('pin_setup_title');
    } else if (widget.mode == PinMode.change) {
      if (_isConfirming) {
        return AppStrings.get('pin_confirm_title');
      } else if (_enteredPin.isEmpty) {
        return AppStrings.get('pin_enter_old_title');
      } else {
        return AppStrings.get('pin_setup_title');
      }
    } else {
      return AppStrings.get('pin_verify_title');
    }
  }

  String _getSubtitle() {
    if (widget.mode == PinMode.setup) {
      return _isConfirming
          ? AppStrings.get('pin_confirm_subtitle')
          : AppStrings.get('pin_setup_subtitle');
    } else if (widget.mode == PinMode.change) {
      if (_isConfirming) {
        return AppStrings.get('pin_confirm_subtitle');
      } else if (_enteredPin.isEmpty) {
        return AppStrings.get('pin_enter_old_subtitle');
      } else {
        return AppStrings.get('pin_setup_subtitle');
      }
    } else {
      return AppStrings.get('pin_verify_subtitle');
    }
  }

  Widget _buildNumpad(bool isDark, Color textColor) {
    return Column(
      children: [
        // Строки с цифрами
        for (int row = 0; row < 3; row++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int col = 1; col <= 3; col++)
                  _buildNumberButton(
                    (row * 3 + col).toString(),
                    isDark,
                    textColor,
                  ),
              ],
            ),
          ),

        // Последняя строка: 0 и кнопка удаления
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Отступ слева для центрирования (ширина одной кнопки с отступами: 80 + 12*2 = 104)
              const SizedBox(width: 104),
              _buildNumberButton('0', isDark, textColor),
              _buildDeleteButton(isDark, textColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNumberButton(String number, bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onNumberPressed(number),
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onDeletePressed,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Icon(
              Icons.backspace_outlined,
              size: 28,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  void _onNumberPressed(String number) {
    setState(() {
      _errorMessage = null;
      final currentPin = _getCurrentPin();
      
      if (currentPin.length < _pinLength) {
        if (_isConfirming) {
          _confirmPin += number;
        } else {
          _enteredPin += number;
        }

        // Проверяем, заполнен ли PIN-код
        if (_getCurrentPin().length == _pinLength) {
          _handlePinComplete();
        }
      }
    });
  }

  void _onDeletePressed() {
    setState(() {
      _errorMessage = null;
      if (_isConfirming) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      } else {
        if (_enteredPin.isNotEmpty) {
          _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        }
      }
    });
  }

  Future<void> _handlePinComplete() async {
    if (widget.mode == PinMode.verify) {
      await _verifyPin();
    } else if (widget.mode == PinMode.setup) {
      if (!_isConfirming) {
        // Переходим к подтверждению
        setState(() {
          _isConfirming = true;
        });
      } else {
        await _confirmPinSetup();
      }
    } else if (widget.mode == PinMode.change) {
      if (!_oldPinVerified) {
        // Проверяем старый PIN
        await _verifyOldPin();
      } else if (!_isConfirming) {
        // Переходим к подтверждению нового PIN
        setState(() {
          _isConfirming = true;
        });
      } else {
        await _confirmPinChange();
      }
    }
  }

  Future<void> _verifyPin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString(_pinKey);

    if (!mounted) return;

    if (_enteredPin == savedPin) {
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _errorMessage = AppStrings.get('pin_error_wrong');
          _enteredPin = '';
        });
      }
    }
  }

  Future<void> _verifyOldPin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString(_pinKey);

    if (!mounted) return;

    if (_enteredPin == savedPin) {
      setState(() {
        _oldPinVerified = true;
        _enteredPin = '';
        _errorMessage = null;
      });
    } else {
      if (mounted) {
        setState(() {
          _errorMessage = AppStrings.get('pin_error_wrong');
          _enteredPin = '';
        });
      }
    }
  }

  Future<void> _confirmPinSetup() async {
    if (_enteredPin == _confirmPin) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pinKey, _enteredPin);
      
      if (!mounted) return;
      
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _errorMessage = AppStrings.get('pin_error_mismatch');
          _enteredPin = '';
          _confirmPin = '';
          _isConfirming = false;
        });
      }
    }
  }

  Future<void> _confirmPinChange() async {
    if (_enteredPin == _confirmPin) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pinKey, _enteredPin);
      
      if (!mounted) return;
      
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _errorMessage = AppStrings.get('pin_error_mismatch');
          _enteredPin = '';
          _confirmPin = '';
          _isConfirming = false;
        });
      }
    }
  }
}

