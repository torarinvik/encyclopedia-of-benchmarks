## Test ASCII pattern presence with a Rabin-Karp rolling hash.
proc rabin_karp*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "rabin_karp".} =
  if values.isNil or length < 2 or length > 512: return -1
  let textLengthValue = values[0]
  let patternLengthValue = values[1]
  if textLengthValue < 0 or textLengthValue > 255 or patternLengthValue < 0 or patternLengthValue > 255: return -1
  if length != csize_t(2 + textLengthValue + patternLengthValue): return -1
  for index in 0 ..< int(textLengthValue + patternLengthValue):
    if values[2 + index] < 0 or values[2 + index] > 127: return -1

  let textLength = int(textLengthValue)
  let patternLength = int(patternLengthValue)
  if patternLength == 0: return 1
  if patternLength > textLength: return 0

  const base = 256'i64
  const modulus = 1000003'i64
  var patternHash = 0'i64
  var rollingHash = 0'i64
  var highPower = 1'i64
  for index in 0 ..< patternLength:
    patternHash = (patternHash * base + values[2 + textLength + index]) mod modulus
    rollingHash = (rollingHash * base + values[2 + index]) mod modulus
    if index + 1 < patternLength: highPower = (highPower * base) mod modulus

  let lastStart = textLength - patternLength
  for start in 0 .. lastStart:
    if rollingHash == patternHash:
      var offset = 0
      while offset < patternLength and values[2 + start + offset] == values[2 + textLength + offset]: inc offset
      if offset == patternLength: return 1
    if start < lastStart:
      let removed = (values[2 + start] * highPower) mod modulus
      rollingHash = (rollingHash - removed) mod modulus
      if rollingHash < 0: rollingHash += modulus
      rollingHash = (rollingHash * base + values[2 + start + patternLength]) mod modulus
  0
