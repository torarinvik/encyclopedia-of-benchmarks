const MaxN = 64
const MaxInputLength = 1 + 3 * MaxN
const MaxValue = 2'i64

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc tsvc_s319_coupled_reductions*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s319_coupled_reductions".} =
  if input == nil or length < 4 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > MaxN: return -1
  let n = int(nValue)
  if int(length) != 1 + 3 * n: return -1

  let cStart = 1
  let dStart = cStart + n
  let eStart = dStart + n
  for i in 0 ..< n:
    if input[cStart + i] < -MaxValue or input[cStart + i] > MaxValue or
        input[dStart + i] < -MaxValue or input[dStart + i] > MaxValue or
        input[eStart + i] < -MaxValue or input[eStart + i] > MaxValue: return -1
  let valueCount = 2 * n + 1
  if output == nil or outputCapacity < csize_t(8 * valueCount): return -2

  var total: int64 = 0
  for i in 0 ..< n:
    let aValue = input[cStart + i] + input[dStart + i]
    let bValue = input[cStart + i] + input[eStart + i]
    storeI64Le(output, 8 * i, aValue)
    storeI64Le(output, 8 * (n + i), bValue)
    total += aValue
    total += bValue
  storeI64Le(output, 8 * (2 * n), total)
  int64(valueCount)
