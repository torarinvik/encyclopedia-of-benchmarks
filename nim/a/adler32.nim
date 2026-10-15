## Compute Adler-32 over byte values without modifying the input.
const MaxLength = 100001
const ModAdler = 65521'i64

proc adler32*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "adler32".} =
  if length > csize_t(MaxLength) or (length != 0 and values == nil): return -1
  var a = 1'i64
  var b = 0'i64
  for index in 0 ..< int(length):
    let value = values[index]
    if value < 0 or value > 255: return -1
    a = (a + value) mod ModAdler
    b = (b + a) mod ModAdler
  (b shl 16) or a
