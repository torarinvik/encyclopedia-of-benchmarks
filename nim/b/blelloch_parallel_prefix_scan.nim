const MaxItems = 64
const MaxInputWords = 66

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc blelloch_parallel_prefix_scan*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64
    {.cdecl, exportc: "blelloch_parallel_prefix_scan".} =
  if input.isNil or length < 2 or length > MaxInputWords:
    return -1
  let n64 = input[0]
  if n64 < 1 or n64 > MaxItems:
    return -1
  let n = int(n64)
  if length != csize_t(n + 1):
    return -1

  var tree: array[MaxItems, int64]
  var padded = 1
  while padded < n:
    padded = padded shl 1
  for i in 0 ..< n:
    let value = input[i + 1]
    if value < -1_000_000'i64 or value > 1_000_000'i64:
      return -1
    tree[i] = value
  if output.isNil or outputCapacity < csize_t(n * 8):
    return -2

  var stride = 2
  while stride <= padded:
    let half = stride shr 1
    var right = stride - 1
    while right < padded:
      tree[right] += tree[right - half]
      right += stride
    stride = stride shl 1
  tree[padded - 1] = 0
  stride = padded
  while stride >= 2:
    let half = stride shr 1
    var right = stride - 1
    while right < padded:
      let left = right - half
      let partial = tree[left]
      tree[left] = tree[right]
      tree[right] += partial
      right += stride
    stride = stride shr 1
  for i in 0 ..< n:
    storeI64Le(output, i * 8, tree[i])
  int64(n * 8)
