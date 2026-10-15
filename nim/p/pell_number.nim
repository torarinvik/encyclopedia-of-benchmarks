proc pell_number*(index: int64): int64 {.cdecl, exportc: "pell_number".} =
  if index < 0 or index > 50: return -1
  if index == 0: return 0
  var previous = 0'i64
  var current = 1'i64
  var i = 2'i64
  while i <= index:
    let next = 2 * current + previous
    previous = current
    current = next
    inc i
  return current
