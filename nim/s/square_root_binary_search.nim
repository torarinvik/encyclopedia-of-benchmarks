## Floor square root by binary search, with division avoiding square overflow.
proc square_root_binary_search*(value: int64): int64 {.cdecl, exportc: "square_root_binary_search".} =
  if value < 0: return -1
  if value < 2: return value
  var low = 1'i64
  var high = value
  var answer = 0'i64
  while low <= high:
    let middle = low + (high - low) div 2
    if middle <= value div middle:
      answer = middle
      low = middle + 1
    else:
      high = middle - 1
  answer
