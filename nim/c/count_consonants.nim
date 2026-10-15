const MaxLength = 4096

proc count_consonants*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "count_consonants".} =
  if length == 0 or length > csize_t(MaxLength) or values == nil: return -1
  if length == 1 and values[0] == 48: return -1
  var count = 0'i64
  for index in 0 ..< int(length):
    var value = values[index]
    if value < 32 or value > 126: return -1
    if value >= 65 and value <= 90: value += 32
    if value >= 97 and value <= 122 and value notin [97'i64, 101'i64, 105'i64, 111'i64, 117'i64]: inc count
  count
