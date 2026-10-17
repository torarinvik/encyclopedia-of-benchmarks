const MaxNodes = 128
const MaxInputLength = MaxNodes + 1

type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

proc putI32Le(output: U8Output, offset: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u32)

proc median_search2*(input: I64Input, length: csize_t, output: U8Output,
    capacity: csize_t): int64
    {.cdecl, exportc: "median_search2".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  if input[0] < 0 or input[0] > int64(MaxNodes): return -1
  let count = int(input[0])
  if int(length) != count + 1: return -1
  for i in 0 ..< count:
    if input[i + 1] < int64(low(int32)) or input[i + 1] > int64(high(int32)): return -1

  var next: array[MaxNodes, int32]
  for i in 0 ..< count:
    next[i] = if i + 1 < count: int32(i + 1) else: -1
  var found = 0'i32
  var medianIndex = -1'i32
  if count > 0:
    var slow = 0'i32
    var fast = 0'i32
    while next[int(fast)] >= 0 and next[int(next[int(fast)])] >= 0:
      slow = next[int(slow)]
      fast = next[int(next[int(fast)])]
    medianIndex = if next[int(fast)] >= 0: next[int(slow)] else: slow
    found = 1
  if output == nil or capacity < 8: return -2
  var buffer: array[8, uint8]
  putI32Le(cast[U8Output](addr buffer[0]), 0, found)
  putI32Le(cast[U8Output](addr buffer[0]), 4, medianIndex)
  for i in 0 ..< 8: output[i] = buffer[i]
  8
