type I64Input = ptr UncheckedArray[int64]
type U8Output = ptr UncheckedArray[uint8]

proc storeI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc farey_approximation*(values: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "farey_approximation".} =
  if values == nil or length != 2: return -1
  let decimalMillionths = values[0]
  let repeat = values[1]
  if decimalMillionths < 1 or decimalMillionths > 999999 or repeat < 1 or repeat > 20: return -1
  if output == nil or outputCapacity < 16: return -2

  let decimal = float64(decimalMillionths) / 1_000_000.0
  var a = 0'i64
  var b = 1'i64
  var c = 1'i64
  var d = 1'i64
  var numerator = 0'i64
  var denominator = 0'i64
  for _ in 0'i64 ..< repeat:
    numerator = a + c
    denominator = b + d
    if decimal > float64(numerator) / float64(denominator):
      a = numerator
      b = denominator
    else:
      c = numerator
      d = denominator
  storeI64Le(output, 0, numerator)
  storeI64Le(output, 8, denominator)
  16
