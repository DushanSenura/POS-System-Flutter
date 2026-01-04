import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/employee_change_request_model.dart';

class EmployeeChangeRequestNotifier
    extends StateNotifier<List<EmployeeChangeRequest>> {
  EmployeeChangeRequestNotifier() : super([]);

  void createRequest(EmployeeChangeRequest request) {
    state = [...state, request];
  }

  void approveRequest(String requestId, String reviewerName) {
    state = [
      for (final req in state)
        if (req.id == requestId)
          req.copyWith(
            status: 'approved',
            reviewedBy: reviewerName,
            reviewedAt: DateTime.now(),
          )
        else
          req,
    ];
  }

  void rejectRequest(String requestId, String reviewerName, String reason) {
    state = [
      for (final req in state)
        if (req.id == requestId)
          req.copyWith(
            status: 'rejected',
            reviewedBy: reviewerName,
            reviewedAt: DateTime.now(),
            rejectionReason: reason,
          )
        else
          req,
    ];
  }

  void deleteRequest(String requestId) {
    state = state.where((req) => req.id != requestId).toList();
  }

  List<EmployeeChangeRequest> getPendingRequests() {
    return state.where((req) => req.isPending).toList()
      ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
  }

  List<EmployeeChangeRequest> getRequestsByEmployee(String employeeId) {
    return state.where((req) => req.employeeId == employeeId).toList()
      ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
  }

  bool hasePendingRequest(String employeeId) {
    return state.any((req) => req.employeeId == employeeId && req.isPending);
  }

  void clearAll() {
    state = [];
  }
}

final employeeChangeRequestProvider =
    StateNotifierProvider<
      EmployeeChangeRequestNotifier,
      List<EmployeeChangeRequest>
    >((ref) => EmployeeChangeRequestNotifier());

final pendingRequestsCountProvider = Provider<int>((ref) {
  final requests = ref.watch(employeeChangeRequestProvider);
  return requests.where((req) => req.isPending).length;
});
