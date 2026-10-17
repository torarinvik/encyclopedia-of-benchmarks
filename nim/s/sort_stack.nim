const MaxItems = 64

proc insertSorted(stack: var array[MaxItems, int32], size: var int, value: int32) =
  if size == 0 or value > stack[size - 1]:
    stack[size] = value
    inc size
    return
  dec size
  let top = stack[size]
  insertSorted(stack, size, value)
  stack[size] = top
  inc size

proc sortRecursively(stack: var array[MaxItems, int32], size: var int) =
  if size == 0: return
  dec size
  let top = stack[size]
  sortRecursively(stack, size)
  insertSorted(stack, size, top)

proc sortStack*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "sort_stack".} =
  if input == nil or length < 1 or length > 65: return -1
  if input[0] < 0 or input[0] > MaxItems or length != csize_t(1 + int(input[0])): return -1
  let count = int(input[0])
  var stack: array[MaxItems, int32]
  for i in 0 ..< count:
    if input[i + 1] < int64(low(int32)) or input[i + 1] > int64(high(int32)): return -1
    stack[i] = int32(input[i + 1])
  var size = count
  sortRecursively(stack, size)
  let bytes = size * 4
  if output == nil or outputCapacity < csize_t(bytes): return -2
  for i in 0 ..< size:
    let bits = cast[uint32](stack[i])
    for b in 0 ..< 4: output[4 * i + b] = uint8((bits shr (8 * b)) and 255'u32)
  int64(bytes)
