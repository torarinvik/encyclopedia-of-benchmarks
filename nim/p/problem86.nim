const MaxLimit = 1_000_000

proc isSquare(value: int64): bool =
  var root = value
  var next = (root + 1) div 2
  while next < root:
    root = next
    next = (root + value div root) div 2
  root * root == value

proc problem86*(limit: int64): int64 {.cdecl, exportc: "problem86".} =
  if limit > MaxLimit: return -1
  if limit < 0: return 0
  var cuboidCount = 0'i64
  var maxSide = 0'i64
  while cuboidCount <= limit:
    inc maxSide
    for sumSides in 2'i64..(2 * maxSide):
      if not isSquare(sumSides * sumSides + maxSide * maxSide): continue
      let high = min(maxSide, sumSides div 2)
      let low = max(1'i64, sumSides - maxSide)
      cuboidCount += high - low + 1
  maxSide
