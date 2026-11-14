proc backward_nondeterministic_dawg_match*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "backward_nondeterministic_dawg_match".} =
  if values == nil or length < 2 or values[0] < 0 or values[0] > 4096 or
      values[1] < 0 or values[1] > 63:
    return -2
  let n = int(values[0])
  let m = int(values[1])
  if length != csize_t(2 + n + m): return -2
  for i in 2 ..< int(length):
    if values[i] < 97 or values[i] > 122: return -2
  if m == 0: return 0
  if m > n: return -1

  var masks: array[26, uint64]
  for i in 0 ..< m:
    let letter = int(values[2 + n + i] - 97)
    masks[letter] = masks[letter] or (1'u64 shl (m - 1 - i))
  var start = 0
  while start <= n - m:
    var remaining = m
    var shift = m
    var states = high(uint64)
    while remaining > 0 and states != 0:
      dec remaining
      states = states and masks[int(values[2 + start + remaining] - 97)]
      if states != 0:
        if remaining == 0: return int64(start)
        shift = remaining
      states = states shl 1
    start += shift
  -1
