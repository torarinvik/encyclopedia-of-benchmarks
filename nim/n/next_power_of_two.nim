## Bit spreading for the pinned positive 32-bit source domain.
proc next_power_of_two*(number: int64): int64 {.cdecl, exportc: "next_power_of_two".} =
  if number < 1 or number > 1_073_741_824:
    return -1
  if (number and (number - 1)) == 0:
    return number

  var value = number - 1
  value = value or (value shr 1)
  value = value or (value shr 2)
  value = value or (value shr 4)
  value = value or (value shr 8)
  value = value or (value shr 16)
  return value + 1
