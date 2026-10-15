const MaxTextLength = 1024

proc one_time_pad_cipher*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "one_time_pad_cipher".} =
  if input == nil or length < 2 or length > csize_t(2 + 2 * MaxTextLength): return -1
  let mode = input[0]
  let countValue = input[1]
  if (mode != 0 and mode != 1) or countValue < 0 or countValue > MaxTextLength: return -1
  let count = int(countValue)
  if int(length) != 2 + 2 * count: return -1
  if int(outputCapacity) < count: return -2
  for index in 0 ..< count:
    let data = input[2 + index]
    let key = input[2 + count + index]
    if data < 0 or data > 255 or key < 0 or key > 255: return -1
    output[index] = uint8(data xor key)
  int64(count)
