part of 'email_bloc.dart';

abstract class EmailState {}

class EmailInitial extends EmailState {}

class EmailLoading extends EmailState {}

class EmailSuccess extends EmailState {
  final String email;
  EmailSuccess(this.email);
}

class EmailError extends EmailState {
  final String message;
  EmailError(this.message);
}