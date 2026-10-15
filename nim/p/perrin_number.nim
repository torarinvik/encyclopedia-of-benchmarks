proc perrin_number*(index: int64): int64 {.cdecl, exportc: "perrin_number".} =
  if index < 0 or index > 155: return -1
  if index == 0: return 3
  if index == 1: return 0
  if index == 2: return 2
  var a = 3'i64
  var b = 0'i64
  var c = 2'i64
  var result = 0'i64
  var i = 3'i64
  while i <= index:
    result = a + b
    a = b
    b = c
    c = result
    inc i
  return result
