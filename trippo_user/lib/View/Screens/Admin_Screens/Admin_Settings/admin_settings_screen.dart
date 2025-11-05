import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../Container/Repositories/app_config_repo.dart';
import '../../../../config/app_config.dart';

/// Admin Settings Screen
/// Manage all app configuration (API keys, pricing, etc.)

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final AppConfigRepository _configRepo = AppConfigRepository();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _openAiKeyController;
  late TextEditingController _claudeKeyController;
  late TextEditingController _geminiKeyController;
  late TextEditingController _checkrKeyController;
  late TextEditingController _stripePublicKeyController;
  late TextEditingController _stripeSecretKeyController;
  late TextEditingController _paypalClientIdController;
  late TextEditingController _paypalSecretController;
  late TextEditingController _serviceRadiusController;
  late TextEditingController _commissionController;
  late TextEditingController _emergencySurchargeController;

  // State
  AppConfig? _currentConfig;
  AIProvider? _selectedAiProvider;
  PricingModel? _selectedPricingModel;
  bool _emergencySurchargeEnabled = true;
  bool _backgroundCheckRequired = true;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _showApiKeys = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadConfig();
  }

  void _initializeControllers() {
    _openAiKeyController = TextEditingController();
    _claudeKeyController = TextEditingController();
    _geminiKeyController = TextEditingController();
    _checkrKeyController = TextEditingController();
    _stripePublicKeyController = TextEditingController();
    _stripeSecretKeyController = TextEditingController();
    _paypalClientIdController = TextEditingController();
    _paypalSecretController = TextEditingController();
    _serviceRadiusController = TextEditingController();
    _commissionController = TextEditingController();
    _emergencySurchargeController = TextEditingController();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);

    try {
      final config = await _configRepo.getConfig();

      setState(() {
        _currentConfig = config;
        _openAiKeyController.text = config.openAiApiKey;
        _claudeKeyController.text = config.claudeApiKey;
        _geminiKeyController.text = config.geminiApiKey;
        _checkrKeyController.text = config.checkrApiKey;
        _stripePublicKeyController.text = config.stripePublishableKey;
        _stripeSecretKeyController.text = config.stripeSecretKey;
        _paypalClientIdController.text = config.paypalClientId;
        _paypalSecretController.text = config.paypalSecret;
        _serviceRadiusController.text = config.serviceRadiusMiles.toString();
        _commissionController.text = config.platformCommissionPercentage.toString();
        _emergencySurchargeController.text = config.emergencySurchargePercentage.toString();
        _selectedAiProvider = config.defaultAiProvider;
        _selectedPricingModel = config.pricingModel;
        _emergencySurchargeEnabled = config.emergencySurchargeEnabled;
        _backgroundCheckRequired = config.backgroundCheckRequired;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading config: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updatedConfig = AppConfig(
        openAiApiKey: _openAiKeyController.text.trim(),
        claudeApiKey: _claudeKeyController.text.trim(),
        geminiApiKey: _geminiKeyController.text.trim(),
        defaultAiProvider: _selectedAiProvider!,
        serviceRadiusMiles: double.parse(_serviceRadiusController.text),
        pricingModel: _selectedPricingModel!,
        platformCommissionPercentage: double.parse(_commissionController.text),
        emergencySurchargeEnabled: _emergencySurchargeEnabled,
        emergencySurchargePercentage: double.parse(_emergencySurchargeController.text),
        stripePublishableKey: _stripePublicKeyController.text.trim(),
        stripeSecretKey: _stripeSecretKeyController.text.trim(),
        paypalClientId: _paypalClientIdController.text.trim(),
        paypalSecret: _paypalSecretController.text.trim(),
        googleCalendarClientId: _currentConfig?.googleCalendarClientId ?? '',
        googleCalendarClientSecret: _currentConfig?.googleCalendarClientSecret ?? '',
        checkrApiKey: _checkrKeyController.text.trim(),
        backgroundCheckRequired: _backgroundCheckRequired,
      );

      await _configRepo.updateConfig(updatedConfig);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Configuration saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving config: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _openAiKeyController.dispose();
    _claudeKeyController.dispose();
    _geminiKeyController.dispose();
    _checkrKeyController.dispose();
    _stripePublicKeyController.dispose();
    _stripeSecretKeyController.dispose();
    _paypalClientIdController.dispose();
    _paypalSecretController.dispose();
    _serviceRadiusController.dispose();
    _commissionController.dispose();
    _emergencySurchargeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('App Settings'),
        actions: [
          IconButton(
            icon: Icon(_showApiKeys ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() => _showApiKeys = !_showApiKeys);
            },
            tooltip: _showApiKeys ? 'Hide API Keys' : 'Show API Keys',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader('AI Configuration', Icons.smart_toy),
            const SizedBox(height: 12),
            _buildAISection(),
            const SizedBox(height: 24),

            _buildSectionHeader('Background Check', Icons.security),
            const SizedBox(height: 12),
            _buildBackgroundCheckSection(),
            const SizedBox(height: 24),

            _buildSectionHeader('Payment Configuration', Icons.payment),
            const SizedBox(height: 12),
            _buildPaymentSection(),
            const SizedBox(height: 24),

            _buildSectionHeader('Service Settings', Icons.settings),
            const SizedBox(height: 12),
            _buildServiceSection(),
            const SizedBox(height: 24),

            _buildSectionHeader('Pricing Configuration', Icons.attach_money),
            const SizedBox(height: 12),
            _buildPricingSection(),
            const SizedBox(height: 100), // Space for save button
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveConfig,
        icon: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAISection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _openAiKeyController,
            label: 'OpenAI API Key',
            hint: 'sk-...',
            obscureText: !_showApiKeys,
            icon: Icons.key,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'OpenAI API key is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _claudeKeyController,
            label: 'Claude API Key',
            hint: 'sk-ant-...',
            obscureText: !_showApiKeys,
            icon: Icons.key,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _geminiKeyController,
            label: 'Gemini API Key',
            hint: 'AIza...',
            obscureText: !_showApiKeys,
            icon: Icons.key,
          ),
          const SizedBox(height: 16),
          _buildDropdown<AIProvider>(
            label: 'Default AI Provider',
            value: _selectedAiProvider,
            items: AIProvider.values,
            itemLabel: (provider) => provider.displayName,
            onChanged: (value) {
              setState(() => _selectedAiProvider = value);
            },
            icon: Icons.psychology,
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundCheckSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _checkrKeyController,
            label: 'Checkr API Key',
            hint: 'test_...',
            obscureText: !_showApiKeys,
            icon: Icons.verified_user,
            validator: (value) {
              if (_backgroundCheckRequired && (value == null || value.isEmpty)) {
                return 'Checkr API key is required when background checks are enabled';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text(
              'Require Background Checks',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'All provider applicants must pass background check',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            value: _backgroundCheckRequired,
            onChanged: (value) {
              setState(() => _backgroundCheckRequired = value);
            },
            activeColor: Colors.blue,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stripe',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _stripePublicKeyController,
            label: 'Stripe Publishable Key',
            hint: 'pk_...',
            obscureText: !_showApiKeys,
            icon: Icons.credit_card,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _stripeSecretKeyController,
            label: 'Stripe Secret Key',
            hint: 'sk_...',
            obscureText: !_showApiKeys,
            icon: Icons.lock,
          ),
          const SizedBox(height: 20),
          const Text(
            'PayPal',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _paypalClientIdController,
            label: 'PayPal Client ID',
            hint: 'AZ...',
            obscureText: !_showApiKeys,
            icon: Icons.paypal,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _paypalSecretController,
            label: 'PayPal Secret',
            hint: 'EC...',
            obscureText: !_showApiKeys,
            icon: Icons.lock,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _serviceRadiusController,
            label: 'Service Radius (miles)',
            hint: '15',
            icon: Icons.circle,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Service radius is required';
              }
              final number = double.tryParse(value);
              if (number == null || number <= 0) {
                return 'Enter a valid radius';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Providers will be matched within this radius',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDropdown<PricingModel>(
            label: 'Pricing Model',
            value: _selectedPricingModel,
            items: PricingModel.values,
            itemLabel: (model) => model.displayName,
            onChanged: (value) {
              setState(() => _selectedPricingModel = value);
            },
            icon: Icons.monetization_on,
          ),
          const SizedBox(height: 8),
          Text(
            _selectedPricingModel?.description ?? '',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _commissionController,
            label: 'Platform Commission (%)',
            hint: '20',
            icon: Icons.percent,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Commission percentage is required';
              }
              final number = double.tryParse(value);
              if (number == null || number < 0 || number > 100) {
                return 'Enter a valid percentage (0-100)';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            title: const Text(
              'Emergency Surcharge',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Add surcharge for on-demand emergency services',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            value: _emergencySurchargeEnabled,
            onChanged: (value) {
              setState(() => _emergencySurchargeEnabled = value);
            },
            activeColor: Colors.blue,
            contentPadding: EdgeInsets.zero,
          ),
          if (_emergencySurchargeEnabled) ...[
            const SizedBox(height: 12),
            _buildTextField(
              controller: _emergencySurchargeController,
              label: 'Emergency Surcharge (%)',
              hint: '50',
              icon: Icons.warning,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (_emergencySurchargeEnabled) {
                  if (value == null || value.isEmpty) {
                    return 'Surcharge percentage is required';
                  }
                  final number = double.tryParse(value);
                  if (number == null || number < 0 || number > 200) {
                    return 'Enter a valid percentage (0-200)';
                  }
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscureText = false,
    IconData? icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
        labelStyle: const TextStyle(color: Colors.grey),
        hintStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: const Color(0xFF121212),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
    IconData? icon,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF121212),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue),
        ),
      ),
      dropdownColor: const Color(0xFF1E1E1E),
      style: const TextStyle(color: Colors.white),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(itemLabel(item)),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null) {
          return 'Please select an option';
        }
        return null;
      },
    );
  }
}
