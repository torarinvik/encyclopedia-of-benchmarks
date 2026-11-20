const MaxText = 255
const MaxPattern = 64
const MaxFrame = 322

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc raita_search*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "raita_search".} =
  if input.isNil or length < 2 or length > MaxFrame: return -1
  if input[0] < 0 or input[0] > MaxText or input[1] < 1 or input[1] > MaxPattern: return -1
  let n = int(input[0])
  let m = int(input[1])
  if int(length) != 2 + n + m: return -1
  for i in 0 ..< n + m:
    if input[2 + i] < 0 or input[2 + i] > 127: return -1

  var positions: array[MaxText, int64]
  var matchCount = 0
  if m <= n:
    var shifts: array[128, int]
    for byte in 0 ..< 128: shifts[byte] = m
    for i in 0 ..< m - 1: shifts[int(input[2 + n + i])] = m - i - 1
    let middle = m div 2
    var alignment = 0
    while alignment <= n - m:
      let last = int(input[2 + alignment + m - 1])
      var matches = input[2 + n + m - 1] == int64(last)
      if matches: matches = input[2 + n] == input[2 + alignment]
      if matches: matches = input[2 + n + middle] == input[2 + alignment + middle]
      if matches:
        var index = 1
        while index + 1 < m and matches:
          if input[2 + n + index] != input[2 + alignment + index]: matches = false
          inc index
        if matches:
          positions[matchCount] = int64(alignment)
          inc matchCount
      alignment += shifts[last]

  let outputBytes = matchCount * 8
  if output.isNil or outputCapacity < csize_t(outputBytes): return -2
  for i in 0 ..< matchCount: storeI64Le(output, i * 8, positions[i])
  int64(outputBytes)
