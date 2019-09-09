import 'dart:async';
import 'package:form_bloc/form_bloc.dart';
import 'package:rxdart/rxdart.dart';

class ProgressFormBloc extends FormBloc<String, String> {
  final imageField = FileFieldBloc();
  final nameField = TextFieldBloc<String>(initialValue: '🔥 GiancarloCode 🔥');

  List<FakeUpload> _fakeUploads = List();
  List<StreamSubscription<double>> _fakeUploadProgressSubscriptions = List();

  @override
  List<FieldBloc> get fieldBlocs => [imageField, nameField];

  @override
  Stream<FormBlocState<String, String>> onCancelSubmission() async* {
    _fakeUploads.last.cancel();
    yield currentState.toSubmitting(0.0);
    await Future<void>.delayed(Duration(milliseconds: 400));
    updateState(currentState.toSubmissionCancelled());
  }

  @override
  Stream<FormBlocState<String, String>> onSubmitting() async* {
    // for get the image
    // final File image = imageField.currentState.value;

    final int _currentUploadIndex = _fakeUploads.length;
    _fakeUploads.add(FakeUpload());
    _fakeUploadProgressSubscriptions.add(
      _fakeUploads[_currentUploadIndex].uploadProgress.listen(
        (progress) {
          if (!_fakeUploads[_currentUploadIndex].isCancelled) {
            updateState(currentState.toSubmitting(progress));
          }
        },
        onDone: () async {
          if (!_fakeUploads[_currentUploadIndex]._isCancelled) {
            await Future<void>.delayed(Duration(milliseconds: 400));
            updateState(currentState.toSuccess());
          }
        },
      ),
    );
  }
}

class FakeUpload {
  final BehaviorSubject<double> _subject = BehaviorSubject.seeded(0.0);
  bool _isCancelled = false;
  bool get isCancelled => _isCancelled;

  Stream<double> get uploadProgress => _subject.stream;

  FakeUpload() {
    _subject.doOnDone(() {
      _subject.close();
    });
    _initUpload();
  }

  void _initUpload() async {
    int milliseconds = 400;
    while (_subject.value < 1) {
      await Future.delayed(Duration(milliseconds: milliseconds));

      if (!_isCancelled) {
        _subject.add(_subject.value + 0.2);
        milliseconds += 400;
      } else {
        break;
      }
    }
    _subject.close();
  }

  void cancel() {
    _isCancelled = true;
    _subject.close();
  }
}