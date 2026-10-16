proc permutation_and_combination*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "permutation_and_combination".} =
  if v.isNil or n != 3: return -1
  let op = v[0]; let a = v[1]; var r = v[2]
  if op < 0 or op > 2 or a < 0 or a > 18: return -1
  if op != 0 and (r < 0 or r > a): return -1
  var result = 1'i64
  if op == 0:
    for i in 2'i64..a: result *= i
  elif op == 1:
    for i in (a - r + 1)..a: result *= i
  else:
    if r > a - r: r = a - r
    for i in 1'i64..r: result = result * (a - r + i) div i
  result
