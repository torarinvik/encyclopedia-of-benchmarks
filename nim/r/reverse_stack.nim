type I64Input = ptr UncheckedArray[int64]
type U8Output = ptr UncheckedArray[uint8]

const MaxElements = 16

proc insertAtBottom(items: var array[MaxElements, int64], size: int, value: int64) =
  if size == 0:
    items[0] = value
    return
  let top = items[size - 1]
  insertAtBottom(items, size - 1, value)
  items[size] = top

proc reverseRecursive(items: var array[MaxElements, int64], size: int) =
  if size == 0: return
  let top = items[size - 1]
  reverseRecursive(items, size - 1)
  insertAtBottom(items, size - 1, top)

proc putI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc reverse_stack*(input: I64Input, length: csize_t, output: U8Output, capacity: csize_t): int64
    {.cdecl, exportc: "reverse_stack".} =
  if input == nil or length < 1: return -1
  let rawCount = input[0]
  if rawCount < 0 or rawCount > MaxElements or length != csize_t(rawCount + 1): return -1
  let count = int(rawCount)
  var items: array[MaxElements, int64]
  for i in 0..<count:
    if input[i + 1] < -1_000_000 or input[i + 1] > 1_000_000: return -1
    items[i] = input[i + 1]
  let bytes = (count + 1) * 8
  if output == nil or capacity < csize_t(bytes): return -2
  reverseRecursive(items, count)
  putI64Le(output, 0, rawCount)
  for i in 0..<count: putI64Le(output, 8 * (i + 1), items[i])
  int64(bytes)
