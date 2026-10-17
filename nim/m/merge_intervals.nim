const MaxIntervals = 256
const MaxInputLength = 1 + 2 * MaxIntervals

proc storeI32Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint32](int32(value))
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc merge_intervals*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "merge_intervals".} =
  if values == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  let rawCount = values[0]
  if rawCount < 0 or rawCount > int64(MaxIntervals) or
      length != csize_t(1 + 2 * rawCount): return -1

  let count = int(rawCount)
  var starts: array[MaxIntervals, int64]
  var ends: array[MaxIntervals, int64]
  for index in 0 ..< count:
    let start = values[1 + 2 * index]
    let ending = values[2 + 2 * index]
    if start < int64(low(int32)) or start > int64(high(int32)) or
        ending < int64(low(int32)) or ending > int64(high(int32)) or start > ending:
      return -1
    starts[index] = start
    ends[index] = ending

  for index in 1 ..< count:
    let start = starts[index]
    let ending = ends[index]
    var position = index
    while position > 0 and starts[position - 1] > start:
      starts[position] = starts[position - 1]
      ends[position] = ends[position - 1]
      dec position
    starts[position] = start
    ends[position] = ending

  var merged = 0
  for index in 0 ..< count:
    if merged > 0 and starts[index] <= ends[merged - 1]:
      if ends[index] > ends[merged - 1]:
        ends[merged - 1] = ends[index]
    else:
      starts[merged] = starts[index]
      ends[merged] = ends[index]
      inc merged

  let byteCount = merged * 8
  if output == nil or outputCapacity < csize_t(byteCount): return -2
  for index in 0 ..< merged:
    storeI32Le(output, index * 8, starts[index])
    storeI32Le(output, index * 8 + 4, ends[index])
  int64(byteCount)
