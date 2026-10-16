proc isBouncy(value: int64): bool =
  var increasing = false
  var decreasing = false
  var previous = value mod 10
  var current = value div 10
  while current > 0:
    let digit = current mod 10
    if digit < previous: increasing = true
    if digit > previous: decreasing = true
    previous = digit
    current = current div 10
  increasing and decreasing

proc problem112*(percent: int64): int64 {.cdecl, exportc: "problem112".} =
  if percent < 1 or percent > 99: return -1
  var bouncy = 0'i64
  var n = 1'i64
  while true:
    if isBouncy(n): inc bouncy
    if bouncy * 100 >= percent * n: return n
    inc n
