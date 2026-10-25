const MaxN = 48
const MaxInputLength = 1 + MaxN
const MaxValue = 2'i64

proc tsvc_s312_array_product*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "tsvc_s312_array_product".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  if nValue < 0 or nValue > MaxN: return -1
  let n = int(nValue)
  if int(length) != 1 + n: return -1

  var product: int64 = 1
  for i in 0 ..< n:
    let value = input[i + 1]
    if value < 0 or value > MaxValue: return -1
    product *= value
  product
