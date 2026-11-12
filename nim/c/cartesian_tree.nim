const MaxN = 128

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc cartesian_tree*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "cartesian_tree".} =
  if input.isNil or length < 2 or length > csize_t(1 + MaxN): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > int64(MaxN): return -1
  let n = int(nValue)
  if length != csize_t(n + 1): return -1

  var parent: array[MaxN, int64]
  var stack: array[MaxN, int]
  for i in 0 ..< n:
    let key = input[i + 1]
    if key < 0 or key > 1_000_000_000: return -1
    parent[i] = int64(i)

  var stackSize = 0
  for i in 0 ..< n:
    var last = MaxN
    while stackSize > 0 and input[stack[stackSize - 1] + 1] > input[i + 1]:
      dec stackSize
      last = stack[stackSize]
    if stackSize > 0: parent[i] = int64(stack[stackSize - 1])
    if last < MaxN: parent[last] = int64(i)
    stack[stackSize] = i
    inc stackSize

  let outputBytes = n * 8
  if output.isNil or capacity < csize_t(outputBytes): return -2
  for i in 0 ..< n: storeI64Le(output, i * 8, parent[i])
  int64(outputBytes)
