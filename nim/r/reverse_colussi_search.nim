const MaxText = 4096
const MaxPattern = 128
const MaxInputLength = 4227

proc reverse_colussi_search*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "reverse_colussi_search".} =
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
    let value = input[2 + q]
    if value < 0 or value > 3: return -1
    text[q] = uint8(value)
  for q in 0 ..< m:
    let value = input[2 + n + q]
    if value < 0 or value > 3: return -1
    pattern[q] = uint8(value)
  if n < m: return 0

  var hmin: array[MaxPattern + 1, int]
  var kmin: array[MaxPattern, int]
  var rmin: array[MaxPattern, int]
  var order: array[MaxPattern, int]
  var goodSuffix: array[MaxPattern + 1, int]
  var badCharacter: array[4 * (MaxPattern + 1), int]
  for shift in 1 .. m:
    var lastMismatch = shift - 1
    for pos in shift ..< m:
      if pattern[pos] != pattern[pos - shift]: lastMismatch = pos
    hmin[shift] = lastMismatch
  var shift = m
  while shift > 0:
    let end = hmin[shift]
    if end != m - 1: kmin[end] = shift
    dec shift

  var nextBoundary = m
  var end = m - 1
  while end >= 0:
    if hmin[end + 1] == end: nextBoundary = end + 1
    rmin[end] = nextBoundary
    dec end

  order[0] = m - 1
  var cursor = 0
  for shift in 1 .. m:
    let hEnd = hmin[shift]
    if hEnd != m - 1 and kmin[hEnd] == shift:
      inc cursor
      order[cursor] = hEnd
      goodSuffix[cursor] = shift
  cursor = m - 1
  end = m - 2
  while end >= 0:
    if kmin[end] == 0:
      order[cursor] = end
      goodSuffix[cursor] = rmin[end]
      dec cursor
    dec end
  goodSuffix[m] = rmin[0]

  for symbol in 0 ..< 4:
    for priorShift in 1 .. m:
      let boundary = m - priorShift - 1
      for candidate in 1 .. m:
        if candidate < m and int(pattern[m - candidate - 1]) != symbol: continue
        if candidate <= boundary and
            pattern[m - candidate - priorShift - 1] != pattern[boundary]: continue
        badCharacter[symbol * (MaxPattern + 1) + priorShift] = candidate
        break

  var count = 0'i64
  var offsetSum = 0'i64
  var offsetXor = 0'i64
  var start = 0
  var shiftState = m
  let lastStart = n - m
  while start <= lastStart:
    while start <= lastStart and pattern[m - 1] != text[start + m - 1]:
      shiftState = badCharacter[int(text[start + m - 1]) * (MaxPattern + 1) + shiftState]
      start += shiftState
    if start > lastStart: break
    var index = 1
    while index < m and pattern[order[index]] == text[start + order[index]]: inc index
    if index == m:
      inc count
      offsetSum += int64(start)
      offsetXor = offsetXor xor int64(start)
    shiftState = goodSuffix[index]
    start += shiftState
  (count shl 36) or (offsetSum shl 12) or offsetXor
