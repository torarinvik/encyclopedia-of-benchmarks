## Return the zero-based 5-smooth number at index n.
proc nth_ugly_number*(n: int64): int64 {.cdecl, exportc: "nth_ugly_number".} =
  if n < 0 or n > 12690: return -1
  var values: array[12691, int64]
  values[0] = 1
  var i2 = 0
  var i3 = 0
  var i5 = 0
  var index = 1
  while index <= int(n):
    let c2 = 2 * values[i2]
    let c3 = 3 * values[i3]
    let c5 = 5 * values[i5]
    var next = min(c2, c3)
    if c5 < next: next = c5
    values[index] = next
    if c2 == next: inc i2
    if c3 == next: inc i3
    if c5 == next: inc i5
    inc index
  values[int(n)]
