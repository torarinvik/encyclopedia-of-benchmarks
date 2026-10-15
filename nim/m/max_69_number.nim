proc max_69_number*(value: int64): int64 {.cdecl, exportc: "max_69_number".} =
  if value < 1 or value > 999999999999999999'i64: return -1
  var place = 1'i64
  while place <= value div 10: place *= 10
  while place > 0:
    let digit = (value div place) mod 10
    if digit == 6: return value + 3 * place
    if digit != 9: return -1
    place = place div 10
  return -1
