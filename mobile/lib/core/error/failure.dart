import 'package:equatable/equatable.dart';

class Failure extends Equatable {
  final String error;
  final int? statusCode;

  const Failure({required this.error,  this.statusCode=500});

  @override
  List<Object?> get props => [error, statusCode];
}