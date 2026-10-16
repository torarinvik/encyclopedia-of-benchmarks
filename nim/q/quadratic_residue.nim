proc quadratic_residue*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "quadratic_residue".} =
  if input == nil or length != 2: return -1
  let a = input[0]
  let p = input[1]
  if p notin [3'i64,5,7,11,13,17,19,23,29,31,37,41,43,47,53] or a < 0 or a >= p: return -1
  if a == 0: return 0
  var r = 1'i64
  var b = a
  var e = (p - 1) div 2
  while e > 0:
    if (e and 1) != 0: r = (r * b) mod p
    b = (b * b) mod p
    e = e shr 1
  return (if r == 1: 1 else: -1)
