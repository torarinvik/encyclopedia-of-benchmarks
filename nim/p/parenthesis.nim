proc parenthesis*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "parenthesis".} =
  if v.isNil or n < 1 or n > 129 or v[0] < 0 or v[0] > 128 or n != csize_t(v[0] + 1): return -1
  var balance = 0'i64
  for i in 1..<int(n):
    let x = v[i]; if x < 0 or x > 127: return -1
    if x == 40: inc balance
    elif x == 41:
      dec balance
      if balance < 0: return 0
  int64(balance == 0)
