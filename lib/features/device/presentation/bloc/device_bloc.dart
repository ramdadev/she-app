import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'device_event.dart';
part 'device_state.dart';

class DeviceBloc extends Bloc<DeviceEvent, DeviceState> {
  DeviceBloc() : super(DeviceInitial()) {
    on<DeviceEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
