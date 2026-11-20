const MaxText = 4096
const MaxPattern = 128
const MaxInput = 4227

proc morris_pratt_search*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "morris_pratt_search".} =
  if input.isNil or length < 2 or length > MaxInput: return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 0 or n64 > MaxText or m64 < 1 or m64 > MaxPattern: return -1
  let n = int(n64)
  let m = int(m64)
  if length != csize_t(2 + n + m): return -1
  let patternStart = 2 + n
  for q in 0 ..< n + m:
    if input[2 + q] < 0 or input[2 + q] > 3: return -1

  var mpNext: array[0..MaxPattern, int64]
  mpNext[0] = -1
  for index in 0 ..< m:
    var border = mpNext[index]
    while border >= 0 and input[patternStart + index] != input[patternStart + int(border)]:
      border = mpNext[int(border)]
    mpNext[index + 1] = border + 1

  var matched = 0
  var count = 0'i64
  var offsetSum = 0'i64
  var offsetXor = 0'i64
  for textIndex in 0 ..< n:
    while matched >= 0 and input[patternStart + matched] != input[2 + textIndex]:
      matched = int(mpNext[matched])
    inc matched
    if matched == m:
      let start = int64(textIndex + 1 - matched)
      inc count
      offsetSum += start
      offsetXor = offsetXor xor start
      matched = int(mpNext[m])
  (count shl 36) or (offsetSum shl 12) or offsetXor
