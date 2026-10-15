proc check_factorial*(n: int64): int64 {.cdecl, exportc: "check_factorial".} =
  if n <= 0: return 0
  var value = n
  var divisor = 2'i64
  while value mod divisor == 0:
    value = value div divisor
    inc divisor
  if value == 1: 1 else: 0
