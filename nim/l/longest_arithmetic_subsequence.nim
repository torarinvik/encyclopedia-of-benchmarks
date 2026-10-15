## Length of the longest arithmetic subsequence.
proc longest_arithmetic_subsequence*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "longest_arithmetic_subsequence".} =
  if length > 64 or (length != 0 and values == nil): return -1
  for i in 0 ..< int(length):
    if values[i] < -1_000_000 or values[i] > 1_000_000: return -1
  if length <= 1: return int64(length)

  var keys: array[64, array[127, int64]]
  var sizes: array[64, array[127, int64]]
  var maximum = 2'i64
  for right in 0 ..< int(length):
    for left in 0 ..< right:
      let difference = values[right] - values[left]
      var slot = int((difference mod 127 + 127) mod 127)
      while sizes[left][slot] != 0 and keys[left][slot] != difference: slot = (slot + 1) mod 127
      let candidate = (if sizes[left][slot] == 0: 1'i64 else: sizes[left][slot]) + 1
      slot = int((difference mod 127 + 127) mod 127)
      while sizes[right][slot] != 0 and keys[right][slot] != difference: slot = (slot + 1) mod 127
      if sizes[right][slot] == 0 or candidate > sizes[right][slot]:
        keys[right][slot] = difference
        sizes[right][slot] = candidate
      if candidate > maximum: maximum = candidate
  maximum
