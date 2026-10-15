proc tetranacci_numbers_sequence*(index: int64): int64 {.cdecl, exportc: "tetranacci_numbers_sequence".} =
  if index < 0 or index > 68: return -1
  var a = 1'i64
  var b = 1'i64
  var c = 1'i64
  var d = 1'i64
  if index <= 3: return 1
  var i = 4'i64
  while i <= index:
    let next = a + b + c + d
    a = b
    b = c
    c = d
    d = next
    i += 1
  return d
