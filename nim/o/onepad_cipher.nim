const MaxTextLength = 1024

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc onepad_cipher*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "onepad_cipher".} =
  if input == nil or length < 2 or length > csize_t(2 + 2 * MaxTextLength): return -1
  let mode = input[0]
  let countValue = input[1]
  if (mode != 0 and mode != 1) or countValue < 0 or countValue > MaxTextLength: return -1
  let count = int(countValue)
  if int(length) != 2 + 2 * count: return -1
  let needed = if mode == 0: 8 * count else: count
  if int(outputCapacity) < needed: return -2
  for index in 0 ..< count:
    let data = input[2 + index]
    let key = input[2 + count + index]
    if key < 1 or key > 300: return -1
    if mode == 0:
      if data < 32 or data > 126: return -1
      storeI64Le(output, 8 * index, (data + key) * key)
    else:
      let keySquare = key * key
      if data < keySquare or (data - keySquare) mod key != 0: return -1
      let plain = (data - keySquare) div key
      if plain < 32 or plain > 126: return -1
      output[index] = uint8(plain)
  int64(needed)
