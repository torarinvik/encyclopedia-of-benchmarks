proc format_phone_number*(values: ptr UncheckedArray[int64], length: csize_t,
                          output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "format_phone_number".} =
  if values.isNil or length != 10: return -1
  for i in 0 ..< 10:
    if values[i] < 48 or values[i] > 57: return -1
  if output.isNil or outputCapacity < 14: return -2

  output[0] = 40
  for i in 0 ..< 3: output[i + 1] = uint8(values[i])
  output[4] = 41
  output[5] = 32
  for i in 0 ..< 3: output[i + 6] = uint8(values[i + 3])
  output[9] = 45
  for i in 0 ..< 4: output[i + 10] = uint8(values[i + 6])
  14
