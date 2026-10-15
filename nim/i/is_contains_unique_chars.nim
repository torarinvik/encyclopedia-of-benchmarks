const MaxLength = 4096

proc is_contains_unique_chars*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "is_contains_unique_chars".} =
  if length > csize_t(MaxLength) or (length != 0 and values == nil): return -1
  for index in 0 ..< int(length):
    if values[index] < 0 or values[index] > 127: return -1

  var seen: array[2, uint64] = [0'u64, 0'u64]
  for index in 0 ..< int(length):
    let value = uint64(values[index])
    let word = int(value div 64)
    let mask = 1'u64 shl int(value mod 64)
    if (seen[word] and mask) != 0: return 0
    seen[word] = seen[word] or mask
  1
