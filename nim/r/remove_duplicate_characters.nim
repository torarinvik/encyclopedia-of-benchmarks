const MaxInputLength = 4096

proc remove_duplicate_characters*(values: ptr UncheckedArray[int64], length: csize_t,
                                  output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "remove_duplicate_characters".} =
  if values.isNil or length < 1 or values[0] < 0 or values[0] > MaxInputLength: return -1
  let textLength = int(values[0])
  if length != csize_t(textLength + 1): return -1
  for index in 0 ..< textLength:
    if values[index + 1] < 0 or values[index + 1] > 127: return -1

  var seen: array[128, bool]
  var outputLength = 0
  for index in 0 ..< textLength:
    let byte = int(values[index + 1])
    if not seen[byte]:
      seen[byte] = true
      inc outputLength
  if outputLength > int(outputCapacity) or (outputLength > 0 and output.isNil): return -2

  for index in 0 ..< seen.len: seen[index] = false
  var written = 0
  for index in 0 ..< textLength:
    let byte = int(values[index + 1])
    if not seen[byte]:
      seen[byte] = true
      output[written] = uint8(byte)
      inc written
  int64(written)
