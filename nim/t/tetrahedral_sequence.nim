const MaxIndex = 3_810_777'i64

proc tetrahedral_sequence*(index: int64): int64 {.cdecl, exportc: "tetrahedral_sequence".} =
  if index < 0 or index > MaxIndex: return -1
  var a = index
  var b = index + 1
  var c = index + 2
  if a mod 2 == 0: a = a div 2
  elif b mod 2 == 0: b = b div 2
  else: c = c div 2
  if a mod 3 == 0: a = a div 3
  elif b mod 3 == 0: b = b div 3
  else: c = c div 3
  return a * b * c
