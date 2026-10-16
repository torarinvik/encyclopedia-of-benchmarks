const MaxLimit = 50_000_000
proc problem87*(limit: int64): int64 {.cdecl, exportc: "problem87".} =
  if limit < 24 or limit > MaxLimit: return -1
  var rootLimit = 0
  while (rootLimit + 1) * (rootLimit + 1) <= int(limit - 24): inc rootLimit
  rootLimit = max(rootLimit, 2)
  var prime = newSeq[bool](rootLimit + 1)
  for p in 2 .. rootLimit: prime[p] = true
  var p = 2
  while p * p <= rootLimit:
    if prime[p]:
      var multiple = p * p
      while multiple <= rootLimit:
        prime[multiple] = false
        multiple += p
    p += 1
  let byteCount = int((limit + 7) div 8)
  var seen = newSeq[uint8](byteCount)
  for p1 in 2 .. rootLimit:
    if not prime[p1]: continue
    let square = int64(p1) * p1
    for p2 in 2 .. rootLimit:
      if not prime[p2]: continue
      let cube = int64(p2) * p2 * p2
      if square + cube >= limit - 16: break
      for p3 in 2 .. rootLimit:
        if not prime[p3]: continue
        let total = square + cube + int64(p3) * p3 * p3 * p3
        if total >= limit: break
        let index = int(total)
        seen[index div 8] = seen[index div 8] or (1'u8 shl (index mod 8))
  var count = 0'i64
  for bits0 in seen:
    var bits = bits0
    while bits != 0: inc count; bits = bits and (bits - 1)
  count
