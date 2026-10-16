proc uint53_is*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "uint53_is".} =
  if v.isNil or n != 1: return -1
  if v[0] >= 0 and v[0] < 9007199254740992: 1 else: 0
