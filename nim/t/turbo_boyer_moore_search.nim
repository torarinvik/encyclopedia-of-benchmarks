const MaxText = 255
const MaxPattern = 64
const MaxFrame = 322

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc turbo_boyer_moore_search*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "turbo_boyer_moore_search".} =
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
    var bad: array[128, int]
    var suffix: array[MaxPattern, int]
    var good: array[MaxPattern, int]
    for byte in 0 ..< 128: bad[byte] = m
    for i in 0 ..< m - 1: bad[int(input[2 + n + i])] = m - i - 1

    suffix[m - 1] = m
    var g = m - 1
    var f = 0
    var i = m - 2
    while i >= 0:
      if i > g and suffix[i + m - 1 - f] < i - g:
        suffix[i] = suffix[i + m - 1 - f]
      else:
        if i < g: g = i
        f = i
        while g >= 0 and input[2 + n + g] == input[2 + n + g + m - 1 - f]: dec g
        suffix[i] = f - g
      dec i
    for j in 0 ..< m: good[j] = m
    var border = 0
    i = m - 1
    while i >= 0:
      if suffix[i] == i + 1:
        while border < m - 1 - i:
          if good[border] == m: good[border] = m - 1 - i
          inc border
      dec i
    for j in 0 ..< m - 1: good[m - 1 - suffix[j]] = m - 1 - j

    var alignment = 0
    var remembered = 0
    var shift = m
    while alignment <= n - m:
      i = m - 1
      while i >= 0 and input[2 + n + i] == input[2 + alignment + i]:
        dec i
        if remembered != 0 and i == m - 1 - shift: i -= remembered
      if i < 0:
        positions[matchCount] = int64(alignment)
        inc matchCount
        shift = good[0]
        remembered = m - shift
      else:
        let matched = m - 1 - i
        let turboShift = remembered - matched
        let badShift = bad[int(input[2 + alignment + i])] - m + 1 + i
        let gs = good[i]
        shift = max(turboShift, max(badShift, gs))
        if shift == gs:
          remembered = min(m - shift, matched)
        else:
          if turboShift < badShift and shift < remembered + 1: shift = remembered + 1
          remembered = 0
      alignment += shift

  let outputBytes = matchCount * 8
  if output.isNil or outputCapacity < csize_t(outputBytes): return -2
  for i in 0 ..< matchCount: storeI64Le(output, i * 8, positions[i])
  int64(outputBytes)
