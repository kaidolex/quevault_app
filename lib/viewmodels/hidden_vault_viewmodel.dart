import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/foundation.dart';

/// Hidden vault state class
class HiddenVaultState {
  final bool showHiddenVaults;
  final int tapCount;

  const HiddenVaultState({this.showHiddenVaults = false, this.tapCount = 0});

  HiddenVaultState copyWith({bool? showHiddenVaults, int? tapCount}) {
    return HiddenVaultState(showHiddenVaults: showHiddenVaults ?? this.showHiddenVaults, tapCount: tapCount ?? this.tapCount);
  }
}

/// Hidden Vault ViewModel using Riverpod StateNotifier
class HiddenVaultViewModel extends StateNotifier<HiddenVaultState> {
  static const int _requiredTaps = 10;

  HiddenVaultViewModel() : super(const HiddenVaultState());

  /// Handle tap on app bar title
  void handleTitleTap() {
    final newTapCount = state.tapCount + 1;

    if (kDebugMode) {
      print('HiddenVaultViewModel: Title tapped - count: $newTapCount');
    }

    state = state.copyWith(tapCount: newTapCount);

    // Check if we've reached the required number of taps
    if (newTapCount >= _requiredTaps && !state.showHiddenVaults) {
      _revealHiddenVaults();
    }
  }

  /// Reveal hidden vaults
  void _revealHiddenVaults() {
    if (kDebugMode) {
      print('HiddenVaultViewModel: Revealing hidden vaults');
    }

    state = state.copyWith(showHiddenVaults: true);
  }

  /// Hide hidden vaults again
  void hideHiddenVaults() {
    if (kDebugMode) {
      print('HiddenVaultViewModel: Hiding hidden vaults');
    }

    state = state.copyWith(showHiddenVaults: false);
  }

  /// Reset tap count (for testing or manual reset)
  void resetTapCount() {
    if (kDebugMode) {
      print('HiddenVaultViewModel: Resetting tap count');
    }

    state = state.copyWith(tapCount: 0);
  }

  /// Get remaining taps needed
  int get remainingTaps => _requiredTaps - state.tapCount;
}

/// Provider for HiddenVaultViewModel
final hiddenVaultViewModelProvider = StateNotifierProvider<HiddenVaultViewModel, HiddenVaultState>((ref) {
  return HiddenVaultViewModel();
});
