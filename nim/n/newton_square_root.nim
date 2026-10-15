import std/math

proc newton_square_root*(value: int64): int64 {.cdecl, exportc: "newton_square_root".} =
  if value < 0 or value > 4611686018427387903'i64: return -1
  if value == 0: return 0

  let bitLength = int(ceil(log2(float64(value))))
  var root = 1'i64 shl (bitLength div 2)
  while not (value >= root * root and value <= root * root + root + root):
    root += value div root
    root = root div 2
  return root
