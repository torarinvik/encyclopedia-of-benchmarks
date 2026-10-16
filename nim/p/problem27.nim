proc problem27IsPrime(value: int64): bool =
  if value < 2: return false
  if value mod 2 == 0: return value == 2
  if value mod 3 == 0: return value == 3
  var factor = 5'i64
  while factor <= value div factor:
    if value mod factor == 0 or value mod (factor + 2) == 0: return false
    factor += 6
  true

proc problem27*(limit: int64): int64 {.cdecl, exportc: "problem27".} =
  if limit < 1 or limit > 1000: return -1
  var bestLength = 0'i64
  var bestA = 0'i64
  var bestB = 0'i64
  var a = 1 - limit
  while a < limit:
    var b = 2'i64
    while b < limit:
      if problem27IsPrime(b):
        var n = 0'i64
        while problem27IsPrime(n * n + a * n + b):
          inc n
        if n > bestLength:
          bestLength = n
          bestA = a
          bestB = b
      inc b
    inc a
  bestA * bestB
