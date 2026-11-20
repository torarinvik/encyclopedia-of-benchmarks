const MaxPoints = 32
const MaxWords = 34
const MaxOutput = 320

proc adaptBias(initialDelta, pointCount: int64, firstTime: bool): int64 =
  var delta = initialDelta div (if firstTime: 700 else: 2)
  delta += delta div pointCount
  var k = 0'i64
  while delta > ((36 - 1) * 26) div 2:
    delta = delta div 35
    k += 36
  k + (36 * delta) div (delta + 38)

proc encodeDigit(digit: int64): uint8 =
  if digit < 26: uint8(ord('a') + int(digit))
  else: uint8(ord('0') + int(digit) - 26)

proc isScalar(point: int64): bool =
  point >= 0 and point <= 0x10ffff and not (point >= 0xd800 and point <= 0xdfff)

proc encodePayload(input: ptr UncheckedArray[int64], count: int,
                   staged: var array[MaxOutput, uint8]): int =
  var basicCount = 0
  for i in 0 ..< count:
    if input[i + 1] < 0x80:
      staged[basicCount] = uint8(input[i + 1])
      inc basicCount
  result = basicCount
  if basicCount != 0:
    staged[result] = uint8(ord('-'))
    inc result
  var n = 128'i64
  var delta = 0'i64
  var bias = 72'i64
  var handled = basicCount
  while handled < count:
    var minimum = 0x110000'i64
    for i in 0 ..< count:
      if input[i + 1] >= n and input[i + 1] < minimum: minimum = input[i + 1]
    delta += (minimum - n) * int64(handled + 1)
    n = minimum
    for i in 0 ..< count:
      let point = input[i + 1]
      if point < n: inc delta
      if point == n:
        var q = delta
        var k = 36'i64
        while true:
          let threshold = if k <= bias: 1'i64 elif k >= bias + 26: 26'i64 else: k - bias
          if q < threshold:
            staged[result] = encodeDigit(q)
            inc result
            break
          staged[result] = encodeDigit(threshold + (q - threshold) mod (36 - threshold))
          inc result
          q = (q - threshold) div (36 - threshold)
          k += 36
        bias = adaptBias(delta, int64(handled + 1), handled == basicCount)
        delta = 0
        inc handled
    inc delta
    inc n

proc punycode_codepoint_sequence_encode*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "punycode_codepoint_sequence_encode".} =
  if input.isNil or length < 1 or length > csize_t(MaxWords): return -1
  let countWord = input[0]
  if countWord < 0 or countWord > int64(MaxPoints) or length != csize_t(countWord + 1): return -1
  let count = int(countWord)
  for i in 0 ..< count:
    if not isScalar(input[i + 1]): return -1
  var staged: array[MaxOutput, uint8]
  let written = encodePayload(input, count, staged)
  if written > MaxOutput: return -1
  if written > 0 and (output.isNil or capacity < csize_t(written)): return -2
  for i in 0 ..< written: output[i] = staged[i]
  int64(written)
