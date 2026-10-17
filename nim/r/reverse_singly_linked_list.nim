const MaxLength = 256

proc writeI32Le(output: ptr UncheckedArray[uint8], index: int, value: int32) =
  let bits = cast[uint32](value)
  let offset = index * 4
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u32)

proc reverse_singly_linked_list*(values: ptr UncheckedArray[int32], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "reverse_singly_linked_list".} =
  if values == nil or length > csize_t(MaxLength): return -1
  let n = int(length)
  let outputBytes = n * 4
  if output == nil or outputCapacity < csize_t(outputBytes): return -2
  for index in 0 ..< n:
    writeI32Le(output, index, values[n - 1 - index])
  int64(outputBytes)
