const MaxCount = 16
const MaxInputLength = 1 + 8 * MaxCount

proc writeI64Le(output: ptr UncheckedArray[byte], index: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[index * 8 + b] = byte((bits shr (8 * b)) and 255)

proc versabench_dbms_keys_union*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[byte], outputCapacity: csize_t): int64
    {.cdecl, exportc: "versabench_dbms_keys_union".} =
  if values == nil or length < 1 or length > csize_t(MaxInputLength + 1): return -1
  let rawCount = values[0]
  if rawCount < 1 or rawCount > MaxCount or length != csize_t(1 + 8 * int(rawCount)): return -1
  var bounds: array[8, int64]
  for d in 0 ..< 4: bounds[d] = values[1+d]; bounds[4+d] = values[5+d]
  for i in 0 ..< int(rawCount):
    let at = 1 + 8 * i
    for d in 0 ..< 4:
      let lo = values[at+d]; let hi = values[at+4+d]
      if lo < -8 or lo > 8 or hi < -8 or hi > 8 or lo > hi: return -1
      bounds[d] = min(bounds[d], lo); bounds[4+d] = max(bounds[4+d], hi)
  if output == nil or outputCapacity < 64: return -2
  for i in 0 ..< 8: writeI64Le(output, i, bounds[i])
  64
