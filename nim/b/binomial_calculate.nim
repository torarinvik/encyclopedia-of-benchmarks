proc binomial_calculate*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "binomial_calculate".} =
  if input.isNil or length != 2: return -1
  let n = input[0]
  var k = input[1]
  if n < 0 or n > 62 or k < 0 or k > n: return -1
  if k > n div 2: k = n - k
  var result = 1'u64
  for i in 1'i64 .. k:
    result *= uint64(n - k + i)
    result = result div uint64(i)
  int64(result)
