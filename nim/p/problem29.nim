## Count distinct powers using maximal perfect-power roots.
proc problem29*(limit: int64): int64 {.cdecl, exportc: "problem29".} =
  if limit < 1 or limit > 100: return -1
  if limit == 1: return 0
  var roots: array[101, int64]
  var exponents: array[101, int64]
  var seen: array[60701, bool]
  var distinct = 0'i64
  for a in 2 .. int(limit):
    roots[a] = int64(a)
    exponents[a] = 1
    for candidateExponent in 2 .. 6:
      for candidateRoot in 2 .. a:
        var power = 1'i64
        for step in 0 ..< candidateExponent:
          power *= int64(candidateRoot)
          if power > int64(a): break
        if power == int64(a) and int64(candidateExponent) > exponents[a]:
          roots[a] = int64(candidateRoot)
          exponents[a] = int64(candidateExponent)
    for b in 2 .. int(limit):
      let key = int(roots[a] * 601 + exponents[a] * int64(b))
      if not seen[key]:
        seen[key] = true
        inc distinct
  distinct
