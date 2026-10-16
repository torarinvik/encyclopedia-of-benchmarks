type I64Input = ptr UncheckedArray[int64]
type U8Output = ptr UncheckedArray[uint8]

proc storeI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc convolution*(values: I64Input, length: csize_t, output: U8Output, capacity: csize_t): int64
    {.cdecl, exportc: "convolution".} =
  if values == nil or length < 4 or length > 130: return -1
  let aRaw = values[0]
  let bRaw = values[1]
  if aRaw < 1 or aRaw > 64 or bRaw < 1 or bRaw > 64: return -1
  let aCount = int(aRaw)
  let bCount = int(bRaw)
  if length != csize_t(aCount + bCount + 2): return -1
  for j in 0..<aCount + bCount:
    let value = values[j + 2]
    if value < -1_000_000 or value > 1_000_000: return -1
  let resultCount = aCount + bCount - 1
  let byteCount = resultCount * 8
  if output == nil or capacity < csize_t(byteCount): return -2
  for i in 0..<resultCount:
    let kStart = if i >= bCount - 1: i - (bCount - 1) else: 0
    let kEnd = if i < aCount: i else: aCount - 1
    var sum = 0'i64
    for k in kStart..kEnd:
      sum += values[k + 2] * values[aCount + (i - k) + 2]
    storeI64Le(output, i * 8, sum)
  int64(byteCount)
