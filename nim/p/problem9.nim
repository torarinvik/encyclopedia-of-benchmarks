proc problem9*(total: int64): int64 {.cdecl, exportc: "problem9".} =
  if total < 3 or total > 1000: return -1
  var a = 1'i64
  while a <= total div 3:
    var b = a + 1
    while 2 * b < total - a:
      let c = total - a - b
      if a * a + b * b == c * c: return a * b * c
      inc b
    inc a
  -1
