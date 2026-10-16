proc sameDigits(left, right: int64): bool =
  var a: array[10, int]
  var b: array[10, int]
  var x = left
  var y = right
  while x > 0: inc a[int(x mod 10)]; x = x div 10
  while y > 0: inc b[int(y mod 10)]; y = y div 10
  a == b

proc problem52*(unused: int64): int64 {.cdecl, exportc: "problem52".} =
  if unused != 0: return -1
  var value = 1'i64
  while true:
    var matches = true
    for multiplier in 2 .. 6:
      if not sameDigits(value, value * multiplier): matches = false
    if matches: return value
    inc value
