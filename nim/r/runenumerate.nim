const MaxN = 24
const MaxRuns = 144
type I64Input = ptr UncheckedArray[int64]
type U8Output = ptr UncheckedArray[uint8]

proc storeI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc runenumerate*(input: I64Input, length: csize_t, output: U8Output,
                   capacity: csize_t): int64 {.cdecl, exportc: "runenumerate".} =
  if input == nil or length < 2 or length > MaxN + 1: return -1
  let nValue = input[0]
  if nValue < 1 or nValue > MaxN or length != csize_t(nValue + 1): return -1
  let n = int(nValue)
  var text: array[MaxN, int]
  for i in 0 ..< n:
    if input[i + 1] < 0 or input[i + 1] >= 26: return -1
    text[i] = int(input[i + 1])
  if output == nil: return -2

  var lcp: array[MaxN + 1, array[MaxN + 1, int]]
  for i in countdown(n - 1, 0):
    if i + 1 < n:
      for j in countdown(n - 1, i + 1):
        if text[i] == text[j]: lcp[i][j] = 1 + lcp[i + 1][j + 1]
  var periods, lefts, rights: array[MaxRuns, int]
  var count = 0
  for period in 1 .. (n div 2):
    var i = period
    while i < n:
      if text[i] != text[i - period]:
        inc i
        continue
      let first = i
      while i < n and text[i] == text[i - period]: inc i
      let left = first - period
      let right = i
      if right - left < 2 * period: continue
      var minimal = true
      for smaller in 1 ..< period:
        if lcp[left][left + smaller] >= right - left - smaller:
          minimal = false
          break
      if minimal and count < MaxRuns:
        periods[count] = period
        lefts[count] = left
        rights[count] = right
        inc count

  for i in 1 ..< count:
    let p = periods[i]
    let l = lefts[i]
    let r = rights[i]
    var j = i
    while j > 0 and (periods[j - 1] > p or
        (periods[j - 1] == p and lefts[j - 1] > l) or
        (periods[j - 1] == p and lefts[j - 1] == l and rights[j - 1] > r)):
      periods[j] = periods[j - 1]
      lefts[j] = lefts[j - 1]
      rights[j] = rights[j - 1]
      dec j
    periods[j] = p
    lefts[j] = l
    rights[j] = r

  let needed = 8 + 24 * count
  if capacity < csize_t(needed): return -2
  storeI64Le(output, 0, int64(count))
  for i in 0 ..< count:
    let offset = 8 + 24 * i
    storeI64Le(output, offset, int64(periods[i]))
    storeI64Le(output, offset + 8, int64(lefts[i]))
    storeI64Le(output, offset + 16, int64(rights[i]))
  int64(needed)
