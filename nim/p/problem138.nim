proc problem138*(count: int64): int64 {.cdecl, exportc: "problem138".} =
  if count > 14: return -1
  if count <= 0: return 0
  var m = 2'i64
  var l = 1'i64
  var total = 0'i64
  for i in 0..<int(count):
    let nextM = 9 * m + 20 * l
    let nextL = 4 * m + 9 * l
    m = nextM
    l = nextL
    total += l
  total
