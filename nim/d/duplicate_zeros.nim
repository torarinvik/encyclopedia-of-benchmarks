## Duplicate each zero while retaining the fixed output length.
proc writeI32(output: ptr UncheckedArray[uint8], position: int, value: int64) =
  let encoded = uint32(int32(value))
  output[position] = uint8(encoded and 255)
  output[position + 1] = uint8((encoded shr 8) and 255)
  output[position + 2] = uint8((encoded shr 16) and 255)
  output[position + 3] = uint8(encoded shr 24)

proc duplicate_zeros*(values: ptr UncheckedArray[int64], length: csize_t,
                      output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "duplicate_zeros".} =
  if length > 64: return -1
  for index in 0 ..< int(length):
    if values[index] < 0 or values[index] > 1000: return -1
  let required = 4 * int(length)
  if outputCapacity < csize_t(required) or (required > 0 and output.isNil): return -2
  var source = 0
  var destination = 0
  while destination < int(length):
    let value = values[source]
    inc source
    writeI32(output, 4 * destination, value)
    inc destination
    if value == 0 and destination < int(length):
      writeI32(output, 4 * destination, 0)
      inc destination
  int64(length)
