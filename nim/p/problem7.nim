proc isPrime(value: int64): bool =
  if value < 2: return false
  var factor = 2'i64
  while factor <= value div factor:
    if value mod factor == 0: return false
    inc factor
  true

proc problem7*(index: int64): int64 {.cdecl, exportc: "problem7".} =
  if index < 1 or index > 10001: return -1
  var count = 0'i64
  var candidate = 1'i64
  while count < index:
    inc candidate
    if isPrime(candidate): inc count
  candidate
