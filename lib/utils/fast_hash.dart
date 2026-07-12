/// FNV-1a hash used to derive an Isar [Id] (int) from a String id.
/// See: https://isar.dev/recipes/string_ids.html
int fastHash(String string) {
  var hash = 0xcbf29ce484222325;

  var i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xff;
    hash *= 0x100000001b3;
  }

  return hash;
}
