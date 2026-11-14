proc backward_oracle_match*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "backward_oracle_match".} =
  if values == nil or length < 2 or values[0] < 0 or values[0] > 4096 or values[1] < 0 or values[1] > 63: return -2
  let n = int(values[0])
  let m = int(values[1])
  if length != csize_t(2 + n + m): return -2
  for i in 2 ..< int(length):
    if values[i] < 97 or values[i] > 122: return -2
  if m == 0: return 0
  if m > n: return -1
  var next: array[64, array[26, int]]
  var suffix: array[64, int]
  for i in 0 .. 63:
    suffix[i] = -1
    for c in 0 .. 25: next[i][c] = -1
  for i in 0 ..< m:
    let letter = int(values[2 + n + m - 1 - i] - 97)
    next[i][letter] = i + 1
    var k = suffix[i]
    while k >= 0 and next[k][letter] < 0:
      next[k][letter] = i + 1
      k = suffix[k]
    if k < 0: suffix[i + 1] = 0
    else: suffix[i + 1] = next[k][letter]
  var start = 0
  while start <= n - m:
    var state = 0
    var remaining = m
    var shift = m
    while remaining > 0:
      dec remaining
      state = next[state][int(values[2 + start + remaining] - 97)]
      if state < 0:
        shift = remaining + 1
        break
      if remaining == 0: return int64(start)
    start += shift
  -1
