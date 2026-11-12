const MaxTextLength = 64
const MaxPatternLength = 32
const MaxInputLength = 99

proc maximalSuffix(pattern: openArray[int64], reverseOrder: bool): tuple[critical, period: int] =
  var maximal = -1
  var candidate = 0
  var offset = 1
  var period = 1
  let length = pattern.len
  while candidate + offset < length:
    let a = pattern[candidate + offset]
    let b = pattern[maximal + offset]
    let precedes = if reverseOrder: a > b else: a < b
    if precedes:
      candidate += offset
      offset = 1
      period = candidate - maximal
    elif a == b:
      if offset != period: inc offset
      else:
        candidate += period
        offset = 1
    else:
      maximal = candidate
      candidate = maximal + 1
      offset = 1
      period = 1
  (maximal, period)

proc twoWay(text, pattern: openArray[int64]): seq[int64] =
  let n = text.len
  let m = pattern.len
  if m == 0:
    result = newSeq[int64](n + 1)
    for i in 0 .. n: result[i] = int64(i)
    return
  if m > n: return @[]

  let first = maximalSuffix(pattern, false)
  let second = maximalSuffix(pattern, true)
  let chosen = if first.critical > second.critical: first else: second
  let critical = chosen.critical
  let period = chosen.period
  var periodic = period + critical + 1 <= m
  if periodic and critical >= 0:
    for i in 0 .. critical:
      if pattern[i] != pattern[i + period]:
        periodic = false
        break
  let shift = if periodic: period else: max(critical, m - critical - 1) + 1
  var memory = -1
  var start = 0
  while start <= n - m:
    var index = if periodic: max(critical, memory) + 1 else: critical + 1
    while index < m and pattern[index] == text[start + index]: inc index
    if index >= m:
      index = critical
      while index > memory and pattern[index] == text[start + index]: dec index
      if index <= memory: result.add(int64(start))
      start += shift
      memory = if periodic: m - period - 1 else: -1
    else:
      start += index - critical
      memory = -1

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = uint64(value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc crochemore_perrin_two_way*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "crochemore_perrin_two_way".} =
  if values == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  if values[0] < 0 or values[0] > int64(MaxTextLength)
      or values[1] < 0 or values[1] > int64(MaxPatternLength): return -1
  let textLength = int(values[0])
  let patternLength = int(values[1])
  if length != csize_t(2 + textLength + patternLength): return -1
  var text = newSeq[int64](textLength)
  var pattern = newSeq[int64](patternLength)
  for i in 0 ..< textLength:
    let value = values[2 + i]
    if value < 0 or value > 255: return -1
    text[i] = value
  for i in 0 ..< patternLength:
    let value = values[2 + textLength + i]
    if value < 0 or value > 255: return -1
    pattern[i] = value
  let matches = twoWay(text, pattern)
  let outputBytes = matches.len * 8
  if output == nil or outputCapacity < csize_t(outputBytes): return -2
  for i, position in matches: storeI64Le(output, i * 8, position)
  int64(outputBytes)
