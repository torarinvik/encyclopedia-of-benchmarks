## Count ASCII vowels in a bounded string represented by byte values.
const MaxLength = 4096

proc count_vowels*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "count_vowels".} =
  if length == 0 or length > csize_t(MaxLength) or values == nil: return -2
  if length == 1 and values[0] == 48: return -2
  var count: int64 = 0
  for index in 0 ..< int(length):
    let value = values[index]
    if value < 0 or value > 127 or value == 44: return -2
    if value in [97'i64, 101, 105, 111, 117, 65, 69, 73, 79, 85]: inc count
  count
