const MaxLength = 100000
const MaxSafeInteger = 9007199254740991'i64

proc is_sorted_array*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "is_sorted_array".} =
  if length > csize_t(MaxLength) or (length != 0 and values == nil): return -1
  for index in 0 ..< int(length):
    if values[index] < -MaxSafeInteger or values[index] > MaxSafeInteger: return -1
  if length > 1:
    for index in 0 ..< int(length) - 1:
      if values[index] >= values[index + 1]: return 0
  1
