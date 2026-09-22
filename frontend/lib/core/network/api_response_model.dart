class ApiResponseModel<T> {
  final bool success;
  final String message;
  final T? data;
  final PaginationModel? pagination;
  final List<dynamic>? errors;

  ApiResponseModel({
    required this.success,
    required this.message,
    this.data,
    this.pagination,
    this.errors,
  });

  factory ApiResponseModel.fromJson(Map<String, dynamic> json, T Function(dynamic)? fromJsonT) {
    return ApiResponseModel<T>(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : json['data'] as T?,
      pagination: json['pagination'] != null ? PaginationModel.fromJson(json['pagination']) : null,
      errors: json['errors'] as List<dynamic>?,
    );
  }
}

class PaginationModel {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  PaginationModel({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      page: json['page'] is int ? json['page'] : int.tryParse(json['page']?.toString() ?? '1') ?? 1,
      limit: json['limit'] is int ? json['limit'] : int.tryParse(json['limit']?.toString() ?? '10') ?? 10,
      total: json['total'] is int ? json['total'] : int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      totalPages: json['totalPages'] is int ? json['totalPages'] : int.tryParse(json['totalPages']?.toString() ?? '1') ?? 1,
      hasNext: json['hasNext'] == true,
      hasPrevious: json['hasPrevious'] == true,
    );
  }
}
