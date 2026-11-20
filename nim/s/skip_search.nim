const MaxText = 4096
const MaxPattern = 128
const MaxInput = 4227

proc skip_search*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "skip_search".} =
  if input.isNil or length < 2 or length > MaxInput: return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 0 or n64 > MaxText or m64 < 1 or m64 > MaxPattern: return -1
  let n = int(n64)
  let m = int(m64)
  if length != csize_t(2 + n + m): return -1

  var text: array[MaxText, int]
  var pattern: array[MaxPattern, int]
  for q in 0 ..< n:
    let value = input[2 + q]
    if value < 0 or value > 3: return -1
    text[q] = int(value)
  var positions: array[4, array[MaxPattern, int]]
  var bucketSizes: array[4, int]
  for q in 0 ..< m:
    let value = input[2 + n + q]
    if value < 0 or value > 3: return -1
    let symbol = int(value)
    pattern[q] = symbol
    positions[symbol][bucketSizes[symbol]] = q
    inc bucketSizes[symbol]

  var count = 0'i64
  var offsetSum = 0'i64
  var offsetXor = 0'i64
  var sample = m - 1
  while sample < n:
    let symbol = text[sample]
    for item in 0 ..< bucketSizes[symbol]:
      let start = sample - positions[symbol][item]
      if start < 0 or start > n - m: continue
      var matched = 0
      while matched < m and text[start + matched] == pattern[matched]:
        inc matched
      if matched == m:
        inc count
        offsetSum += int64(start)
        offsetXor = offsetXor xor int64(start)
    sample += m
  (count shl 36) or (offsetSum shl 12) or offsetXor
