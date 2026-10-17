const MaxInputLength = 67

type I64Input = ptr UncheckedArray[int64]
type U8Output = ptr UncheckedArray[uint8]

proc writeI32Le(output: U8Output, index: int, value: int32) =
  let bits = cast[uint32](value)
  let offset = index * 4
  for byte in 0 ..< 4: output[offset + byte] = uint8((bits shr (byte * 8)) and 0xFF'u32)

proc shuf*(input: I64Input, length: csize_t, output: U8Output, capacity: csize_t): int64 {.cdecl, exportc: "shuf".} =
  if input == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  let countRaw = input[0]
  let sampleSizeRaw = input[1]
  if countRaw < 0 or countRaw > 32 or sampleSizeRaw < 1 or sampleSizeRaw > 32: return -1
  let count = int(countRaw)
  let sampleSize = int(sampleSizeRaw)
  if int64(length) != 2 + 2 * countRaw: return -1

  var items: array[32, int32]
  var sample: array[32, int32]
  var occupied: array[32, bool]
  for index in 0 ..< count:
    let value = input[2 + index]
    if value < int64(low(int32)) or value > int64(high(int32)): return -1
    items[index] = int32(value)
  let initialCount = min(count, sampleSize)
  for index in 0 ..< initialCount:
    let draw = input[2 + count + index]
    if draw < 0 or draw >= int64(sampleSize): return -1
    var slot = int(draw)
    while occupied[slot]:
      inc slot
      if slot == sampleSize: slot = 0
    sample[slot] = items[index]
    occupied[slot] = true
  if count >= sampleSize:
    for index in sampleSize ..< count:
      let draw = input[2 + count + index]
      if draw < 0 or draw > int64(index): return -1
      if draw < int64(sampleSize): sample[int(draw)] = items[index]

  let outputBytes = initialCount * 4
  if output == nil or capacity < csize_t(outputBytes): return -2
  var outputCount = 0
  for slot in 0 ..< sampleSize:
    if occupied[slot]:
      writeI32Le(output, outputCount, sample[slot])
      inc outputCount
  int64(outputCount)
