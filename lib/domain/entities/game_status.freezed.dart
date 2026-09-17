// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GameStatus {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is GameStatus);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'GameStatus()';
}


}

/// @nodoc
class $GameStatusCopyWith<$Res>  {
$GameStatusCopyWith(GameStatus _, $Res Function(GameStatus) __);
}


/// Adds pattern-matching-related methods to [GameStatus].
extension GameStatusPatterns on GameStatus {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( InProgress value)?  inProgress,TResult Function( Win value)?  win,TResult Function( Draw value)?  draw,required TResult orElse(),}){
final _that = this;
switch (_that) {
case InProgress() when inProgress != null:
return inProgress(_that);case Win() when win != null:
return win(_that);case Draw() when draw != null:
return draw(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( InProgress value)  inProgress,required TResult Function( Win value)  win,required TResult Function( Draw value)  draw,}){
final _that = this;
switch (_that) {
case InProgress():
return inProgress(_that);case Win():
return win(_that);case Draw():
return draw(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( InProgress value)?  inProgress,TResult? Function( Win value)?  win,TResult? Function( Draw value)?  draw,}){
final _that = this;
switch (_that) {
case InProgress() when inProgress != null:
return inProgress(_that);case Win() when win != null:
return win(_that);case Draw() when draw != null:
return draw(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  inProgress,TResult Function( Mark winner,  List<int> line)?  win,TResult Function()?  draw,required TResult orElse(),}) {final _that = this;
switch (_that) {
case InProgress() when inProgress != null:
return inProgress();case Win() when win != null:
return win(_that.winner,_that.line);case Draw() when draw != null:
return draw();case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  inProgress,required TResult Function( Mark winner,  List<int> line)  win,required TResult Function()  draw,}) {final _that = this;
switch (_that) {
case InProgress():
return inProgress();case Win():
return win(_that.winner,_that.line);case Draw():
return draw();}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  inProgress,TResult? Function( Mark winner,  List<int> line)?  win,TResult? Function()?  draw,}) {final _that = this;
switch (_that) {
case InProgress() when inProgress != null:
return inProgress();case Win() when win != null:
return win(_that.winner,_that.line);case Draw() when draw != null:
return draw();case _:
  return null;

}
}

}

/// @nodoc


class InProgress implements GameStatus {
  const InProgress();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is InProgress);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'GameStatus.inProgress()';
}


}




/// @nodoc


class Win implements GameStatus {
  const Win(this.winner,  List<int> line): _line = line;
  

 final  Mark winner;
 final  List<int> _line;
 List<int> get line {
  if (_line is EqualUnmodifiableListView) return _line;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_line);
}


/// Create a copy of GameStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WinCopyWith<Win> get copyWith => _$WinCopyWithImpl<Win>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is Win&&(identical(other.winner, winner) || other.winner == winner)&&const DeepCollectionEquality().equals(other.line, _line));
}


@override
int get hashCode {
    return Object.hash(runtimeType,winner,const DeepCollectionEquality().hash(_line));
}

@override
String toString() {
    return 'GameStatus.win(winner: $winner, line: $line)';
}


}

/// @nodoc
abstract mixin class $WinCopyWith<$Res> implements $GameStatusCopyWith<$Res> {
  factory $WinCopyWith(Win value, $Res Function(Win) _then) = _$WinCopyWithImpl;
@useResult
$Res call({
 Mark winner, List<int> line
});




}
/// @nodoc
class _$WinCopyWithImpl<$Res>
    implements $WinCopyWith<$Res> {
  _$WinCopyWithImpl(this._self, this._then);

  final Win _self;
  final $Res Function(Win) _then;

/// Create a copy of GameStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? winner = null,Object? line = null,}) {
  return _then(Win(
null == winner ? _self.winner : winner // ignore: cast_nullable_to_non_nullable
as Mark,null == line ? _self._line : line // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}


}

/// @nodoc


class Draw implements GameStatus {
  const Draw();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is Draw);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'GameStatus.draw()';
}


}




// dart format on
