const MaxLength = 7
proc putI32(output: ptr UncheckedArray[uint8], offset: int, value: int32) =
  let bits = cast[uint32](value)
  for b in 0 ..< 4: output[offset+b] = uint8((bits shr (8*b)) and 255)
proc generate(values: var array[MaxLength, int32], n, k: int, output: ptr UncheckedArray[uint8], rows: var int) =
  if k == 1:
    let start = rows*n*4
    for j in 0 ..< n: putI32(output, start+j*4, values[j])
    inc rows
    return
  for i in 0 ..< k:
    let swapIndex = if k mod 2 == 0: i else: 0
    swap(values[swapIndex], values[k-1])
    generate(values, n, k-1, output, rows)
proc heap_permutation*(input: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "heap_permutation".} =
  if input.isNil or length < 1 or length > MaxLength+1: return -1
  let nValue = input[0]
  if nValue < 0 or nValue > MaxLength or int(length) != int(nValue)+1: return -1
  let n = int(nValue)
  var values: array[MaxLength, int32]
  for i in 0 ..< n:
    let v = input[i+1]
    if v < int64(low(int32)) or v > int64(high(int32)): return -1
    values[i] = int32(v)
  var permutations = 1
  for factor in 2 .. n: permutations *= factor
  let required = permutations*n*4
  if int(capacity) < required or (required != 0 and output.isNil): return -2
  if n == 0: return 1
  var rows = 0
  generate(values, n, n, output, rows)
  int64(rows)
