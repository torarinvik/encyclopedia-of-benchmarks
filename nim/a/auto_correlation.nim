type I64Input = ptr UncheckedArray[int64]
type U8Output = ptr UncheckedArray[uint8]

proc storeI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc auto_correlation*(values: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "auto_correlation".} =
  if values == nil or length < 2 or length > 65: return -1
  let rawCount = values[0]
  if rawCount < 1 or rawCount > 64: return -1
  let count = int(rawCount)
  if length != csize_t(count + 1): return -1
  for index in 0 ..< count:
    if values[index + 1] < -1_000_000 or values[index + 1] > 1_000_000: return -1
  let resultCount = 2 * count - 1
  let byteCount = 8 * resultCount
  if output == nil or outputCapacity < csize_t(byteCount): return -2

  var yStart = count
  for index in 0 ..< resultCount:
    if index < count: dec yStart
    let kMin = if index >= count - 1: index - (count - 1) else: 0
    let kMax = if index < count: index else: count - 1
    var offset = 0
    var sum = 0'i64
    for k in kMin .. kMax:
      sum += values[k + 1] * values[yStart + offset + 1]
      inc offset
    storeI64Le(output, index * 8, sum)
  int64(byteCount)
