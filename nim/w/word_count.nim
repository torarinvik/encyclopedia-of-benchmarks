## Count literal-space-delimited words and requested-word matches.
proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc word_count*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "word_count".} =
  if values == nil or length < 2 or length > 1050 or values[0] < 0 or values[0] > 999: return -1
  let textLength = int(values[0])
  let queryIndex = 1 + textLength
  if queryIndex >= int(length) or values[queryIndex] < 0 or values[queryIndex] > 49: return -1
  let queryLength = int(values[queryIndex])
  if int(length) != queryIndex + 1 + queryLength: return -1
  for index in 1 ..< queryIndex:
    if values[index] < 1 or values[index] > 127: return -1
  for index in queryIndex + 1 ..< int(length):
    if values[index] < 1 or values[index] > 127: return -1
  var total = 0
  var matches = 0
  var start = 0
  for finish in 0 .. textLength:
    if finish == textLength or values[1 + finish] == 32:
      let tokenLength = finish - start
      if tokenLength > 49: return -1
      if total >= 20: return -2
      if tokenLength == queryLength:
        var offset = 0
        while offset < tokenLength and values[1 + start + offset] == values[queryIndex + 1 + offset]: inc offset
        if offset == tokenLength: inc matches
      inc total
      start = finish + 1
  if output == nil or outputCapacity < 16: return -2
  storeI64Le(output, 0, int64(total)); storeI64Le(output, 8, int64(matches))
  16
