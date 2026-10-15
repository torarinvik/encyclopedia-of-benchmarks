type I64Input = ptr UncheckedArray[int64]
type U8Output = ptr UncheckedArray[uint8]

proc storeI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc cross_correlation*(values: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "cross_correlation".} =
  if values == nil or length < 4 or length > 66: return -1
  let rawXCount = values[0]
  let rawYCount = values[1]
  if rawXCount < 1 or rawXCount > 32 or rawYCount < 1 or rawYCount > 32: return -1
  let xCount = int(rawXCount)
  let yCount = int(rawYCount)
  if length != csize_t(xCount + yCount + 2): return -1
  for index in 0 ..< xCount + yCount:
    let sample = values[index + 2]
    if sample < -1_000_000 or sample > 1_000_000: return -1
  let resultCount = xCount + yCount - 1
  let byteCount = 8 * resultCount
  if output == nil or outputCapacity < csize_t(byteCount): return -2

  var yStart = yCount
  for index in 0 ..< resultCount:
    if index < yCount: dec yStart
    let kMin = if index >= yCount - 1: index - (yCount - 1) else: 0
    let kMax = if index < xCount: index else: xCount - 1
    var sum = 0'i64
    for k in kMin .. kMax:
      let yIndex = yStart + (k - kMin)
      sum += values[k + 2] * values[xCount + yIndex + 2]
    storeI64Le(output, index * 8, sum)
  int64(byteCount)
