## Apply updates in order and emit the running even sum as little-endian i32s.
const MaxNumbers = 1000
const MaxQueries = 1000

proc sum_even_after_queries*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "sum_even_after_queries".} =
  if length < 5 or length > 4002 or values.isNil: return -1
  if values[0] < 1 or values[0] > MaxNumbers or values[1] < 1 or values[1] > MaxQueries: return -1
  let numberCount = int(values[0])
  let queryCount = int(values[1])
  if int(length) != 2 + numberCount + 2 * queryCount: return -1

  var working: array[MaxNumbers, int64]
  var evenSum = 0'i64
  for index in 0 ..< numberCount:
    let value = values[2 + index]
    if value < 1 or value > 1000: return -1
    working[index] = value
    if value mod 2 == 0: evenSum += value
  for query in 0 ..< queryCount:
    let offset = 2 + numberCount + 2 * query
    if values[offset] < -1000 or values[offset] > 1000 or
        values[offset + 1] < 0 or values[offset + 1] >= numberCount: return -1
  if outputCapacity < csize_t(queryCount * 4) or output.isNil: return -2

  for query in 0 ..< queryCount:
    let offset = 2 + numberCount + 2 * query
    let delta = values[offset]
    let index = int(values[offset + 1])
    if working[index] mod 2 == 0: evenSum -= working[index]
    working[index] += delta
    if working[index] mod 2 == 0: evenSum += working[index]
    let bits = cast[uint32](int32(evenSum))
    for byte in 0 ..< 4:
      output[query * 4 + byte] = uint8((bits shr (byte * 8)) and 0xFF'u32)
  int64(queryCount)
