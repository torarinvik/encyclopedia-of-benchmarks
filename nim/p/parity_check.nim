proc parity_check*(value: int64): int64 {.cdecl, exportc: "parity_check".} =
  if value < int64(low(int32)) or value > int64(high(int32)): return -1
  var number = int32(value)
  var parity = 0'i32
  while number > 0:
    parity = parity xor (number and 1)
    number = number shr 1
  if parity == 0: 1 else: 0
