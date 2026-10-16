proc problem72*(limit: int64): int64 {.cdecl, exportc: "problem72".} =
  if limit < 0 or limit > 1_000_000: return -1
  if limit < 2: return 0
  var phi: array[1_000_001, uint32]
  if limit >= 1: phi[1] = 1'u32
  for value in 2 .. int(limit): phi[value] = value.uint32
  for prime in 2 .. int(limit):
    if phi[prime] == prime.uint32:
      var multiple = prime
      while multiple <= int(limit):
        phi[multiple] -= phi[multiple] div prime.uint32
        multiple += prime
  var total = 0'i64
  for denominator in 2 .. int(limit): total += phi[denominator].int64
  total
