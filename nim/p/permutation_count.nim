proc permutation_count*(input: ptr UncheckedArray[int64], inputLength: csize_t): int64 {.cdecl, exportc: "permutation_count".} =
  if input == nil or inputLength != 2: return -1
  let n = input[0]
  let r = input[1]
  if n < 0 or n > 18 or r < 0 or r > 18: return -1
  var result = 1'i64
  if r > n:
    for factor in 2'i64 .. n: result *= factor
  else:
    var i = 0'i64
    while i < r:
      result *= n - i
      inc i
  result
