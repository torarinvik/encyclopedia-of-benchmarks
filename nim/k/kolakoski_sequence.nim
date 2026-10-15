proc kolakoski_sequence*(index: int64): int64 {.cdecl, exportc: "kolakoski_sequence".} =
  if index < 0 or index > 63: return -1
  if index == 0: return 1
  if index <= 2: return 2

  var encoded = 6'u64
  var readBit = 4'u64
  var writeBit = 8'u64
  let target = uint64(index)
  var currentIndex = 3'u64
  var nextElement = 1'i64

  while currentIndex <= target:
    let runLength = 1'u64 + (encoded div readBit) mod 2'u64
    var emitted = 0'u64
    while emitted < runLength:
      if nextElement == 2: encoded += writeBit
      if currentIndex == target: return nextElement
      currentIndex += 1'u64
      writeBit *= 2'u64
      emitted += 1'u64
    readBit *= 2'u64
    nextElement = 3 - nextElement
  return -1
