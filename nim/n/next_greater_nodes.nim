## Brute-force next-greater-value search for each node in list order.
proc next_greater_nodes*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "next_greater_nodes".} =
  if length == 0 or length > 4096 or values == nil: return -1
  for index in 0 ..< int(length):
    if values[index] < 1 or values[index] > 1_000_000_000: return -1
  let required = 4 * length
  if outputCapacity < required or output == nil: return -2
  for index in 0 ..< int(length):
    var nextGreater = int64(0)
    for later in (index + 1) ..< int(length):
      if values[later] > values[index]:
        nextGreater = values[later]
        break
    let encoded = uint32(nextGreater)
    output[4 * index] = uint8(encoded and 0xff'u32)
    output[4 * index + 1] = uint8((encoded shr 8) and 0xff'u32)
    output[4 * index + 2] = uint8((encoded shr 16) and 0xff'u32)
    output[4 * index + 3] = uint8((encoded shr 24) and 0xff'u32)
  int64(length)
