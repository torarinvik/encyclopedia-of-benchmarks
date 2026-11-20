proc myrvold_ruskey_permutation_unrank*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "myrvold_ruskey_permutation_unrank".} =
  if input.isNil or length < 2 or length > 3: return -1
  if length != 2: return -1
  let nValue = input[0]
  let rankValue = input[1]
  if nValue < 0 or nValue > 8 or rankValue < 0: return -1
  let n = int(nValue)
  var factorial = 1'i64
  var factor = 2
  while factor <= n:
    factorial *= int64(factor)
    inc factor
  if rankValue >= factorial: return -1

  let required = 8 * n
  if output.isNil or capacity < csize_t(required): return -2
  var permutation: array[8, int64]
  for i in 0 ..< n: permutation[i] = int64(i)
  var remainder = rankValue
  var size = n
  while size > 0:
    let choice = int(remainder mod int64(size))
    remainder = remainder div int64(size)
    swap(permutation[size - 1], permutation[choice])
    dec size

  for i in 0 ..< n:
    let value = uint64(permutation[i])
    for byte in 0 ..< 8:
      output[8 * i + byte] = uint8((value shr (8 * byte)) and 255'u64)
  int64(required)
