extension Unique<E, T> on List<E> {
  List<E> unique([T Function(E element)? id, bool inPlace = true]) {
    final ids = <T>{};
    final list = inPlace ? this : List<E>.from(this);
    list.retainWhere((x) => ids.add(id != null ? id(x) : x as T));
    return list;
  }
}
