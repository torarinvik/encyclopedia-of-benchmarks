proc sourceSieveFlag(value: int64): bool =
  if value < 2: return true
  var divisor = 2'i64
  while divisor <= value div divisor:
    if value mod divisor == 0: return false
    inc divisor
  true

proc sphenic_number*(value: int64): int64 {.cdecl, exportc: "sphenic_number".} =
  if value < 0 or value > 1000: return -1
  var first: array[3, int64]
  var count = 0'i64
  var divisor = 1'i64
  while divisor <= value:
    if value mod divisor == 0 and count < 9:
      if count < 3: first[int(count)] = divisor
      inc count
    inc divisor
  if count == 8 and sourceSieveFlag(first[0]) and sourceSieveFlag(first[1]) and sourceSieveFlag(first[2]): 1 else: 0
