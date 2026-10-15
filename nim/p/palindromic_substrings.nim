## Count all palindromic substrings by expanding around odd and even centers.
proc palindromic_substrings*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "palindromic_substrings".} =
  if length == 0 or length > 1000 or values == nil: return -1
  for index in 0'u64 ..< uint64(length):
    if values[csize_t(index)] < ord('a').int64 or values[csize_t(index)] > ord('z').int64:
      return -1

  var count = 0'i64
  for center_value in 0'u64 ..< uint64(length):
    let center = csize_t(center_value)
    inc count
    var left = center
    var right = center
    while left > 0 and right + 1 < length and values[left - 1] == values[right + 1]:
      inc count
      dec left
      inc right

    left = center
    right = center + 1
    while right < length and values[left] == values[right]:
      inc count
      if left == 0 or right + 1 == length: break
      dec left
      inc right
  count
