const MaxKeys = 64
const Width = 4

proc siftDown(a: var array[MaxKeys, uint32], rootValue, ending: int) =
  var root = rootValue
  while root < ending div 2:
    var child = 2 * root + 1
    if child + 1 < ending and a[child] < a[child + 1]: inc child
    if a[root] >= a[child]: break
    swap(a[root], a[child])
    root = child

proc string_heap_sort*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "string_heap_sort".} =
  if values == nil or length < 1 or length > csize_t(257): return -1
  let rawCount = values[0]
  if rawCount < 0 or rawCount > MaxKeys or length != csize_t(1 + Width * rawCount): return -1
  let count = int(rawCount)
  var keys: array[MaxKeys, uint32]
  for i in 0 ..< count:
    var key = 0'u32
    for b in 0 ..< Width:
      let x = values[1 + Width*i + b]
      if x < 0 or x > 127: return -1
      key = (key shl 8) or uint32(x)
    keys[i] = key
  for start in countdown(count div 2 - 1, 0):
    if count > 1: siftDown(keys, start, count)
  if count > 1:
    for endIndex in countdown(count - 1, 1):
      swap(keys[0], keys[endIndex])
      siftDown(keys, 0, endIndex)
  let byteCount = count * Width
  if output == nil or outputCapacity < csize_t(byteCount): return -2
  for i in 0 ..< count:
    for b in 0 ..< Width: output[i*Width+b] = uint8((keys[i] shr (24-8*b)) and 255)
  int64(byteCount)
