proc weird_number*(value: int64): int64 {.cdecl, exportc: "weird_number".} =
  if value < 0 or value > 512: return -1
  if value == 0: return 0
  var reachable: array[513, bool]
  reachable[0] = true
  var divisorSum = 0'i64
  var divisor = 1'i64
  while divisor <= value div 2:
    if value mod divisor == 0:
      divisorSum += divisor
      var total = value
      while total >= divisor:
        if reachable[int(total - divisor)]: reachable[int(total)] = true
        dec total
    inc divisor
  if divisorSum > value and not reachable[int(value)]: 1 else: 0
