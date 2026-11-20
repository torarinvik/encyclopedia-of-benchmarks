const MaxSteps = 32
const MaxInputValues = MaxSteps + 1
const MaxOutputBytes = MaxSteps * 8

proc storeI64Le(output: var array[MaxOutputBytes, uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc stormer_verlet_position*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "stormer_verlet_position".} =
  if input == nil or length < csize_t(3) or length > csize_t(MaxInputValues): return -1
  let countValue = input[0]
  if countValue < 2 or countValue > MaxSteps: return -1
  if length != csize_t(countValue + 1): return -1
  if input[1] < -1024 or input[1] > 1024 or input[2] < -1024 or input[2] > 1024: return -1
  let count = int(countValue)
  for step in 0 ..< (count - 2):
    if input[3 + step] < -64 or input[3 + step] > 64: return -1

  let byteCount = 8 * count
  if output == nil or outputCapacity < csize_t(byteCount): return -2
  var staged: array[MaxOutputBytes, uint8]
  var previous = input[1]
  var current = input[2]
  storeI64Le(staged, 0, previous)
  storeI64Le(staged, 8, current)
  for index in 2 ..< count:
    let next = 2 * current - previous + input[index + 1]
    storeI64Le(staged, 8 * index, next)
    previous = current
    current = next
  for byte in 0 ..< byteCount: output[byte] = staged[byte]
  int64(byteCount)
