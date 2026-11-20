const MaxText = 4096
const MaxPattern = 128
const MaxInputLength = 4227

proc advanceSample(text: openArray[uint8], n, m: int, last: array[4, int],
                   sample: var int): int =
  while true:
    sample += m
    if sample >= n: return -1
    let position = last[int(text[sample])]
    if position >= 0: return position

proc kmp_skip_search*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "kmp_skip_search".} =
  if input == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 0 or n64 > int64(MaxText) or m64 < 1 or m64 > int64(MaxPattern): return -1
  let n = int(n64)
  let m = int(m64)
  if length != csize_t(2 + n + m): return -1

  var text: array[MaxText, uint8]
  var pattern: array[MaxPattern, uint8]
  for q in 0 ..< n:
    let symbol = input[2 + q]
    if symbol < 0 or symbol > 3: return -1
    text[q] = uint8(symbol)
  for q in 0 ..< m:
    let symbol = input[2 + n + q]
    if symbol < 0 or symbol > 3: return -1
    pattern[q] = uint8(symbol)
  if n < m: return 0

  var mpNext: array[MaxPattern + 1, int]
  var kmpNext: array[MaxPattern + 1, int]
  var q = 0
  var border = -1
  mpNext[0] = -1
  while q < m:
    while border >= 0 and pattern[q] != pattern[border]: border = mpNext[border]
    inc q
    inc border
    mpNext[q] = border
  q = 0
  border = -1
  kmpNext[0] = -1
  while q < m:
    while border >= 0 and pattern[q] != pattern[border]: border = kmpNext[border]
    inc q
    inc border
    if q < m and pattern[q] == pattern[border]: kmpNext[q] = kmpNext[border]
    else: kmpNext[q] = border

  var last: array[4, int]
  var previous: array[MaxPattern, int]
  for q in 0 ..< 4: last[q] = -1
  for q in 0 ..< m:
    let symbol = int(pattern[q])
    previous[q] = last[symbol]
    last[symbol] = q

  var sample = -1
  var i = advanceSample(text, n, m, last, sample)
  if i < 0: return 0
  var start = sample - i
  var wall = 0
  let period = m - kmpNext[m]
  var count = 0'i64
  var offsetSum = 0'i64
  var offsetXor = 0'i64
  while start <= n - m:
    if start > wall: wall = start
    var k = wall - start
    while k < m and pattern[k] == text[start + k]: inc k
    wall = start + k
    if k == m:
      inc count
      offsetSum += int64(start)
      offsetXor = offsetXor xor int64(start)
      i -= period
    else:
      i = previous[i]
    if i < 0:
      i = advanceSample(text, n, m, last, sample)
      if i < 0: break

    var kmpStart = start + k - kmpNext[k]
    k = kmpNext[k]
    start = sample - i
    while start < kmpStart or (kmpStart < start and start < wall):
      if start < kmpStart:
        i = previous[i]
        if i < 0:
          i = advanceSample(text, n, m, last, sample)
          if i < 0: return (count shl 36) or (offsetSum shl 12) or offsetXor
        start = sample - i
      else:
        kmpStart += k - mpNext[k]
        k = mpNext[k]
  (count shl 36) or (offsetSum shl 12) or offsetXor
