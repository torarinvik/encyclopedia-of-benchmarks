const MaxCount = 32
const MaxWords = 66

proc positiveUnits(code: uint8): uint64 =
  var cursor = 6
  let regimeBit = (code shr 6) and 1
  var run = 0
  while cursor >= 0 and ((code shr cursor) and 1) == regimeBit:
    inc run
    dec cursor
  let regime = if regimeBit != 0: run - 1 else: -run
  if cursor >= 0: dec cursor
  var exponent = 0
  for _ in 0 ..< 2:
    exponent = exponent shl 1
    if cursor >= 0:
      exponent = exponent or int((code shr cursor) and 1)
      dec cursor
  let width = cursor + 1
  let fraction = if width == 0: 0 else: int(code) and ((1 shl width) - 1)
  let significand = (1 shl width) + fraction
  let shift = 4 * regime + exponent + 24 - width
  uint64(significand) shl shift

proc compareRatioToUnit(scaled, denominator, unit: uint64): int =
  let quotient = scaled div denominator
  let remainder = scaled mod denominator
  if quotient < unit: return -1
  if quotient > unit: return 1
  if remainder == 0: return 0
  1

proc encodeOne(numerator, denominator: int64): uint8 =
  if numerator == 0: return 0
  let negative = numerator < 0
  let magnitude = uint64(if negative: -numerator else: numerator)
  let scaled = magnitude shl 24
  var chosen: uint8
  if compareRatioToUnit(scaled, uint64(denominator), 1) <= 0:
    chosen = 1
  elif compareRatioToUnit(scaled, uint64(denominator), positiveUnits(127)) >= 0:
    chosen = 127
  else:
    var low = 1
    var high = 127
    while low < high:
      let middle = low + (high - low) div 2
      if compareRatioToUnit(scaled, uint64(denominator), positiveUnits(uint8(middle))) > 0:
        low = middle + 1
      else:
        high = middle
    let upper = uint8(low)
    let lower = upper - 1
    let midpoint = positiveUnits(lower) + positiveUnits(upper)
    let midpointComparison = compareRatioToUnit(scaled shl 1, uint64(denominator), midpoint)
    if midpointComparison < 0: chosen = lower
    elif midpointComparison > 0: chosen = upper
    else: chosen = if (lower and 1) == 0: lower else: upper
  if negative: uint8(256 - int(chosen)) else: chosen

proc posit8_rational_encoder*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc.} =
  if input.isNil or length < 1 or length > MaxWords: return -1
  let countWord = input[0]
  if countWord < 0 or countWord > MaxCount or length != csize_t(1 + countWord * 2): return -1
  let count = int(countWord)
  for index in 0 ..< count:
    let numerator = input[1 + 2 * index]
    let denominator = input[2 + 2 * index]
    if numerator < -2147483648'i64 or numerator > 2147483648'i64 or denominator < 1 or denominator > 2147483648'i64: return -1
  if output.isNil or capacity < csize_t(count): return -2
  var staged: array[MaxCount, uint8]
  for index in 0 ..< count: staged[index] = encodeOne(input[1 + 2 * index], input[2 + 2 * index])
  for index in 0 ..< count: output[index] = staged[index]
  int64(count)
