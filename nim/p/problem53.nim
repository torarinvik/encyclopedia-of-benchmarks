proc problem53*(unused: int64): int64 {.cdecl, exportc: "problem53".} =
  if unused != 0: return -1
  var total = 0'i64
  for n in 1 .. 100:
    var coefficient = 1'i64
    for r in 1 .. (n div 2):
      coefficient = coefficient * int64(n-r+1) div int64(r)
      if coefficient > 1_000_000:
        total += int64(n-2*r+1)
        break
  total
