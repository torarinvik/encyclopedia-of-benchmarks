type
  I64Input = ptr UncheckedArray[int64]

proc zhu_takaoka_search*(values: I64Input, length: csize_t): int64
    {.cdecl, exportc: "zhu_takaoka_search".} =
  const Alphabet = 16
  const MaxPattern = 16
  if values == nil or length < 2 or length > 274: return -2
  if values[0] < 0 or values[0] > 256 or values[1] < 2 or values[1] > MaxPattern: return -2
  let n = int(values[0])
  let m = int(values[1])
  if length != csize_t(2 + n + m): return -2
  for i in 0 ..< n + m:
    if values[2 + i] < 0 or values[2 + i] >= Alphabet: return -2
  if m > n: return -1

  let p = 2 + n
  var pairShift: array[256, int]
  for i in 0 ..< pairShift.len: pairShift[i] = m
  for a in 0 ..< Alphabet: pairShift[a * Alphabet + int(values[p])] = m - 1
  for i in 1 ..< (m - 1):
    pairShift[int(values[p + i - 1]) * Alphabet + int(values[p + i])] = m - 1 - i

  var goodSuffix: array[MaxPattern, int]
  for mismatch in 0 ..< m:
    goodSuffix[mismatch] = m
    for shift in 1 ..< (m + 1):
      let firstKnown = max(mismatch + 1, shift)
      var position = firstKnown
      while position < m and values[p + position] == values[p + position - shift]: inc position
      if position < m: continue
      if mismatch + 1 < m and shift <= mismatch and values[p + mismatch - shift] == values[p + mismatch]: continue
      goodSuffix[mismatch] = shift
      break

  var start = 0
  while start <= n - m:
    var mismatch = m
    while mismatch > 0 and values[p + mismatch - 1] == values[2 + start + mismatch - 1]: dec mismatch
    if mismatch == 0: return int64(start)
    dec mismatch
    let first = int(values[2 + start + m - 2])
    let second = int(values[2 + start + m - 1])
    start += max(goodSuffix[mismatch], pairShift[first * Alphabet + second])
  -1
