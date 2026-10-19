const MaxInput = 12'i64

proc tak(x, y, z: int64): int64 =
  if y < x:
    return tak(tak(x - 1, y, z), tak(y - 1, z, x), tak(z - 1, x, y))
  z

proc takeuchi*(x, y, z: int64): int64 {.cdecl, exportc: "takeuchi".} =
  if x < 0 or x > MaxInput or y < 0 or y > MaxInput or z < 0 or z > MaxInput: return -1
  tak(x, y, z)
