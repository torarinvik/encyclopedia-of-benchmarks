## Pack triangular, tetrahedral, and pentatope membership bits.
proc isTriangular(n: int64): bool =
  var i = 0'i64
  while i <= n:
    let term = i * (i + 1) div 2
    if term == n: return true
    if term > n: return false
    inc i
  return false

proc isTetrahedral(n: int64): bool =
  var i = 1'i64
  while i <= n:
    let term = i * (i + 1) * (i + 2) div 6
    if term == n: return true
    if term > n: return false
    inc i
  return false

proc isPentatope(n: int64): bool =
  var i = 1'i64
  while i <= n:
    let term = i * (i + 1) * (i + 2) * (i + 3) div 24
    if term == n: return true
    if term > n: return false
    inc i
  return false

proc figurate_number*(n: int64): int64 {.cdecl, exportc: "figurate_number".} =
  if n < 0 or n > 1_000_000: return -1
  return (if isTriangular(n): 1'i64 else: 0'i64) +
    (if isTetrahedral(n): 2'i64 else: 0'i64) +
    (if isPentatope(n): 4'i64 else: 0'i64)
