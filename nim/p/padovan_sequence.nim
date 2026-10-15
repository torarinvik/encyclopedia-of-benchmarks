proc padovan_sequence*(index: int64): int64 {.cdecl, exportc: "padovan_sequence".} =
  if index < 0 or index > 156: return -1
  if index <= 2: return 1

  var a = 1'i64
  var b = 1'i64
  var c = 1'i64
  var result = 0'i64
  var i = 3'i64
  while i <= index:
    result = a + b
    a = b
    b = c
    c = result
    inc i
  return result
