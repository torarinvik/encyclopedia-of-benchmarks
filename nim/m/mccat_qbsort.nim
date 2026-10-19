const MaxItems = 32
proc bubble(a: var array[MaxItems, int32], n: int) =
  if n < 2: return
  for endIndex in countdown(n - 1, 1):
    for i in 0 ..< endIndex:
      if a[i + 1] < a[i]: swap(a[i], a[i + 1])
proc quick(a: var array[MaxItems, int32], n: int) =
  if n < 2: return
  let pivot = a[0]
  var lower, upper: array[MaxItems, int32]
  var nl = 0
  var nu = 0
  for i in 1 ..< n:
    if a[i] < pivot: lower[nl] = a[i]; inc nl
    else: upper[nu] = a[i]; inc nu
  quick(upper, nu); quick(lower, nl)
  var k = 0
  for i in 0 ..< nl: a[k] = lower[i]; inc k
  a[k] = pivot; inc k
  for i in 0 ..< nu: a[k] = upper[i]; inc k
proc putLe(output: ptr UncheckedArray[uint8], index: int, value: int32) =
  var bits = cast[uint32](value)
  for b in 0 ..< 4:
    output[index * 4 + b] = uint8(bits and 255)
    bits = bits shr 8
proc mccat_qbsort*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "mccat_qbsort".} =
  if input == nil or length < 3 or length > 34: return -1
  let mode = input[0]
  let countValue = input[1]
  if (mode != 0 and mode != 1) or countValue < 1 or countValue > MaxItems: return -1
  let n = int(countValue)
  if length != csize_t(n + 2): return -1
  var values: array[MaxItems, int32]
  for i in 0 ..< n:
    if input[i + 2] < int64(low(int32)) or input[i + 2] > int64(high(int32)): return -1
    values[i] = int32(input[i + 2])
  for pass in 0 ..< 1000:
    for i in 0 ..< n: values[i] = int32(input[i + 2])
    if mode == 0: bubble(values, n) else: quick(values, n)
  let required = n * 4
  if output == nil or outputCapacity < csize_t(required): return -2
  for i in 0 ..< n: putLe(output, i, values[i])
  int64(required)
