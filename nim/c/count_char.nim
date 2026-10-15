proc count_char*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "count_char".} =
  if length > 4096:
    return -1
  if length > 0 and values == nil:
    return -1
  var count = 0'i64
  for i in 0 ..< int(length):
    let code = values[i]
    if code < 0 or code > 127:
      return -1
    if code != 9 and code != 10 and code != 11 and code != 12 and code != 13 and code != 32:
      inc count
  return count
