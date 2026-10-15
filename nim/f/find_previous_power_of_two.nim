## Repeated-doubling search from the pinned source, bounded to its i32 domain.
proc find_previous_power_of_two*(number: int64): int64 {.cdecl, exportc: "find_previous_power_of_two".} =
  if number < 0 or number > 2_147_483_647:
    return -1
  if number == 0:
    return 0

  var power = 1'i64
  while power <= number:
    power = power shl 1
  if number > 1:
    return power shr 1
  return 1
