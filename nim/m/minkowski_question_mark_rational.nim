type
  I64Input = ptr UncheckedArray[int64]
  ByteOutput = ptr UncheckedArray[uint8]

const
  MaxDenominator = 1_000_000'i64
  MaxCfSum = 60'i64

proc storeI64Le(output: ByteOutput, offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255)
    bits = bits shr 8

proc cfSum(numerator, denominator: int64): int64 =
  var n = numerator
  var d = denominator
  var total = 0'i64
  while n != 0:
    let quotient = d div n
    if quotient > MaxCfSum - total: return -1
    total += quotient
    let remainder = d mod n
    d = n
    n = remainder
  total

proc alternatingNumerator(numerator, denominator, total: int64): int64 =
  var n = numerator
  var d = denominator
  var prefix = 0'i64
  var index = 1'i64
  var result = 0'i64
  while n != 0:
    let quotient = d div n
    prefix += quotient
    let shift = int(total - prefix)
    let term = 1'i64 shl shift
    if (index and 1) == 1: result += term
    else: result -= term
    let remainder = d mod n
    d = n
    n = remainder
    inc index
  result

proc minkowski_question_mark_rational*(input: I64Input, length: csize_t,
    output: ByteOutput, capacity: csize_t): int64
    {.cdecl, exportc: "minkowski_question_mark_rational".} =
  if input.isNil or length < 1 or length > 3: return -1
  if length != 2: return -1
  let p = input[0]
  let q = input[1]
  if p < 0 or q < 1 or q > MaxDenominator or p > q: return -1
  let total = cfSum(p, q)
  if total < 0: return -1
  if output.isNil or capacity < 16: return -2
  let value = alternatingNumerator(p, q, total)
  let exponent = if total == 0: 0'i64 else: total - 1
  storeI64Le(output, 0, value)
  storeI64Le(output, 8, exponent)
  16'i64
