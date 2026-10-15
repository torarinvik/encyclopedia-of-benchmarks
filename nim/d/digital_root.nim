proc digital_root*(n: int64): int64 {.cdecl, exportc: "digital_root".} =
  if n < 0:
    return -1
  var value = n
  while value >= 10:
    var digits = value
    var total = 0'i64
    while digits > 0:
      total += digits mod 10
      digits = digits div 10
    value = total
  return value
