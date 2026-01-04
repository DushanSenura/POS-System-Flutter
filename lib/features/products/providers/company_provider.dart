import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Provider for managing company names
final companyProvider = StateNotifierProvider<CompanyNotifier, List<String>>((
  ref,
) {
  return CompanyNotifier();
});

/// Notifier for managing company names
class CompanyNotifier extends StateNotifier<List<String>> {
  static const String _boxName = 'companies';
  Box<dynamic>? _box;

  CompanyNotifier() : super([]) {
    _init();
  }

  /// Initialize and load companies from Hive
  Future<void> _init() async {
    // Get the already-opened box
    _box = Hive.box(_boxName);
    final savedCompanies = _box?.get('companyList', defaultValue: <String>[]);
    state = List<String>.from(savedCompanies ?? <String>[]);
  }

  /// Add a new company
  Future<void> addCompany(String company) async {
    final trimmedCompany = company.trim();
    if (trimmedCompany.isEmpty) return;

    // Check if company already exists (case-insensitive)
    if (state.any(
      (comp) => comp.toLowerCase() == trimmedCompany.toLowerCase(),
    )) {
      return;
    }

    state = [...state, trimmedCompany];
    await _saveCompanies();
  }

  /// Remove a company
  Future<void> removeCompany(String company) async {
    state = state.where((comp) => comp != company).toList();
    await _saveCompanies();
  }

  /// Update a company name
  Future<void> updateCompany(String oldName, String newName) async {
    final trimmedNewName = newName.trim();
    if (trimmedNewName.isEmpty) return;

    final index = state.indexOf(oldName);
    if (index == -1) return;

    final updatedList = [...state];
    updatedList[index] = trimmedNewName;
    state = updatedList;
    await _saveCompanies();
  }

  /// Save companies to Hive
  Future<void> _saveCompanies() async {
    await _box?.put('companyList', state);
  }
}

/// Provider for sorted companies
final sortedCompaniesProvider = Provider<List<String>>((ref) {
  final companies = ref.watch(companyProvider);
  return [...companies]..sort();
});
