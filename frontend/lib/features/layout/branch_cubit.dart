import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/storage_service.dart';

class BranchState {
  final bool isLoading;
  final List<dynamic> branches;
  final String? activeBranchId;
  final String activeBranchName;
  final String? activeBranchCode;
  final String? activeBranchDistrict;
  final bool isLocked;
  final String? userRole;

  const BranchState({
    this.isLoading = false,
    this.branches = const [],
    this.activeBranchId,
    this.activeBranchName = 'All Branches',
    this.activeBranchCode,
    this.activeBranchDistrict,
    this.isLocked = false,
    this.userRole,
  });

  bool get isAllBranches => activeBranchId == null || activeBranchId!.isEmpty;

  BranchState copyWith({
    bool? isLoading,
    List<dynamic>? branches,
    String? activeBranchId,
    bool clearActiveBranchId = false,
    String? activeBranchName,
    String? activeBranchCode,
    String? activeBranchDistrict,
    bool? isLocked,
    String? userRole,
  }) {
    return BranchState(
      isLoading: isLoading ?? this.isLoading,
      branches: branches ?? this.branches,
      activeBranchId: clearActiveBranchId ? null : (activeBranchId ?? this.activeBranchId),
      activeBranchName: activeBranchName ?? this.activeBranchName,
      activeBranchCode: activeBranchCode ?? this.activeBranchCode,
      activeBranchDistrict: activeBranchDistrict ?? this.activeBranchDistrict,
      isLocked: isLocked ?? this.isLocked,
      userRole: userRole ?? this.userRole,
    );
  }
}

class BranchCubit extends Cubit<BranchState> {
  final ApiClient _apiClient = ApiClient();
  final StorageService _storageService = StorageService();

  BranchCubit() : super(const BranchState());

  /// Synchronize branch state with user role and assigned branch
  Future<void> syncWithUser({
    required Map<String, dynamic> user,
    required String role,
  }) async {
    final isAgent = role.toUpperCase() == 'AGENT';
    
    if (isAgent) {
      String? agentBranchId;
      String agentBranchName = 'Assigned Branch';
      String? agentBranchCode;
      String? agentDistrict;

      final branchData = user['branchId'] ?? user['branch'];
      if (branchData is Map<String, dynamic>) {
        agentBranchId = branchData['_id']?.toString();
        agentBranchName = branchData['name']?.toString() ?? 'Branch Office';
        agentBranchCode = branchData['branchCode']?.toString();
        agentDistrict = branchData['address']?['district']?.toString();
      } else if (branchData != null) {
        agentBranchId = branchData.toString();
      }

      // If branches are already loaded, match the branch details
      if (agentBranchId != null && state.branches.isNotEmpty) {
        final found = state.branches.firstWhere(
          (b) => b['_id']?.toString() == agentBranchId,
          orElse: () => null,
        );
        if (found != null) {
          agentBranchName = found['name']?.toString() ?? agentBranchName;
          agentBranchCode = found['branchCode']?.toString() ?? agentBranchCode;
          agentDistrict = found['address']?['district']?.toString() ?? agentDistrict;
        }
      }

      await _storageService.saveActiveBranch(branchId: agentBranchId, branchName: agentBranchName);

      emit(state.copyWith(
        activeBranchId: agentBranchId,
        clearActiveBranchId: agentBranchId == null,
        activeBranchName: agentBranchName,
        activeBranchCode: agentBranchCode,
        activeBranchDistrict: agentDistrict,
        isLocked: true,
        userRole: role,
      ));
    } else {
      emit(state.copyWith(
        isLocked: false,
        userRole: role,
      ));
    }
  }

  Future<void> loadBranches({Map<String, dynamic>? user, String? role}) async {
    emit(state.copyWith(isLoading: true));

    try {
      final res = await _apiClient.get(ApiEndpoints.branches);
      if (res.success && res.data is List) {
        final branches = res.data as List<dynamic>;

        // Determine if user is Agent
        final currentRole = role ?? state.userRole ?? (user?['role']?.toString());
        final isAgent = currentRole?.toUpperCase() == 'AGENT';

        if (isAgent) {
          String? agentBranchId;
          String agentBranchName = 'Assigned Branch';
          String? agentBranchCode;
          String? agentDistrict;

          final branchData = user?['branchId'] ?? user?['branch'];
          if (branchData is Map<String, dynamic>) {
            agentBranchId = branchData['_id']?.toString();
            agentBranchName = branchData['name']?.toString() ?? 'Branch Office';
            agentBranchCode = branchData['branchCode']?.toString();
            agentDistrict = branchData['address']?['district']?.toString();
          } else if (branchData != null) {
            agentBranchId = branchData.toString();
          } else if (state.activeBranchId != null) {
            agentBranchId = state.activeBranchId;
          }

          if (agentBranchId != null) {
            final found = branches.firstWhere(
              (b) => b['_id']?.toString() == agentBranchId,
              orElse: () => null,
            );
            if (found != null) {
              agentBranchName = found['name']?.toString() ?? agentBranchName;
              agentBranchCode = found['branchCode']?.toString() ?? agentBranchCode;
              agentDistrict = found['address']?['district']?.toString() ?? agentDistrict;
            }
          }

          await _storageService.saveActiveBranch(branchId: agentBranchId, branchName: agentBranchName);

          emit(state.copyWith(
            isLoading: false,
            branches: branches,
            activeBranchId: agentBranchId,
            clearActiveBranchId: agentBranchId == null,
            activeBranchName: agentBranchName,
            activeBranchCode: agentBranchCode,
            activeBranchDistrict: agentDistrict,
            isLocked: true,
            userRole: currentRole,
          ));
          return;
        }

        // For Company Admin / Manager: restore saved branch or 'All Branches'
        final savedBranchId = _storageService.getActiveBranchId();
        final savedBranchName = _storageService.getActiveBranchName() ?? 'All Branches';

        String? validBranchId = savedBranchId;
        String validBranchName = savedBranchName;
        String? validCode;
        String? validDistrict;

        if (savedBranchId != null) {
          final found = branches.firstWhere(
            (b) => b['_id']?.toString() == savedBranchId,
            orElse: () => null,
          );
          if (found != null) {
            validBranchName = found['name']?.toString() ?? savedBranchName;
            validCode = found['branchCode']?.toString();
            validDistrict = found['address']?['district']?.toString();
          } else {
            validBranchId = null;
            validBranchName = 'All Branches';
            await _storageService.saveActiveBranch(branchId: null, branchName: 'All Branches');
          }
        }

        emit(state.copyWith(
          isLoading: false,
          branches: branches,
          activeBranchId: validBranchId,
          clearActiveBranchId: validBranchId == null,
          activeBranchName: validBranchName,
          activeBranchCode: validCode,
          activeBranchDistrict: validDistrict,
          isLocked: false,
          userRole: currentRole,
        ));
      } else {
        emit(state.copyWith(isLoading: false));
      }
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> selectBranch({
    String? branchId,
    required String branchName,
    String? code,
    String? district,
  }) async {
    // If locked (e.g. Agent), ignore switching
    if (state.isLocked) return;

    await _storageService.saveActiveBranch(branchId: branchId, branchName: branchName);

    emit(state.copyWith(
      activeBranchId: branchId,
      clearActiveBranchId: branchId == null || branchId.isEmpty,
      activeBranchName: branchName,
      activeBranchCode: code,
      activeBranchDistrict: district,
    ));
  }

  void selectBranchById(String? branchId) {
    if (state.isLocked) return;

    if (branchId == null || branchId.isEmpty) {
      selectBranch(branchId: null, branchName: 'All Branches');
      return;
    }

    final found = state.branches.firstWhere(
      (b) => b['_id']?.toString() == branchId,
      orElse: () => null,
    );

    if (found != null) {
      selectBranch(
        branchId: branchId,
        branchName: found['name']?.toString() ?? 'Branch',
        code: found['branchCode']?.toString(),
        district: found['address']?['district']?.toString(),
      );
    }
  }

  Future<void> resetOnLogout() async {
    await _storageService.saveActiveBranch(branchId: null, branchName: 'All Branches');
    emit(const BranchState());
  }
}
