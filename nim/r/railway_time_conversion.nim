const
  MaxInputLength = 10
  PackedInputLength = MaxInputLength + 1
  OutputLength = 8

proc isDigit(value: int64): bool =
  value >= 48 and value <= 57

proc railway_time_conversion*(values: ptr UncheckedArray[int64], length: csize_t,
                              output: ptr UncheckedArray[uint8],
                              outputCapacity: csize_t): int64
    {.cdecl, exportc: "railway_time_conversion".} =
  if values.isNil or length != csize_t(PackedInputLength) or
      values[0] != int64(MaxInputLength): return -1

  if values[3] != 58 or values[6] != 58 or
      not ((values[9] == 65 and values[10] == 77) or
           (values[9] == 80 and values[10] == 77)) or
      not isDigit(values[1]) or not isDigit(values[2]) or
      not isDigit(values[4]) or not isDigit(values[5]) or
      not isDigit(values[7]) or not isDigit(values[8]): return -1

  let hour = (values[1] - 48) * 10 + values[2] - 48
  let minute = (values[4] - 48) * 10 + values[5] - 48
  let second = (values[7] - 48) * 10 + values[8] - 48
  if hour < 1 or hour > 12 or minute > 59 or second > 59: return -1
  if output.isNil or outputCapacity < csize_t(OutputLength): return -2

  let hour24 = hour mod 12 + (if values[9] == 80: 12 else: 0)
  output[0] = uint8(48 + hour24 div 10)
  output[1] = uint8(48 + hour24 mod 10)
  output[2] = 58
  output[3] = uint8(values[4])
  output[4] = uint8(values[5])
  output[5] = 58
  output[6] = uint8(values[7])
  output[7] = uint8(values[8])
  int64(OutputLength)
