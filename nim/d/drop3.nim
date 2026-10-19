const MaxInput = 4096
const Offsets: array[8, int] = [0, 5, 2, 7, 4, 1, 6, 3]

proc drop3*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "drop3".} =
  if length > csize_t(MaxInput + 1): return -1
  if length != 0 and values == nil: return -1
  for i in 0 ..< int(length):
    if values[i] < 0 or values[i] > 255: return -1
  if length > csize_t(MaxInput): return -1

  var outputSize = 0'i64
  for iteration in 0 ..< 20:
    var inputIndex = 0
    var remainingBits = int(length) * 8
    var phase = 0
    var bitBuffer = 0'u16
    var outputBits = 0
    while remainingBits >= 3:
      remainingBits -= 3
      let offset = Offsets[phase]
      if offset < 3:
        bitBuffer = bitBuffer or (uint16(values[inputIndex]) shl (8 - offset))
        inc inputIndex
      let code = (bitBuffer shr 13) and 7
      if code >= 4: outputBits += 3
      bitBuffer = bitBuffer shl 3
      phase = (phase + 1) and 7
    outputSize = int64(outputBits shr 3)
  outputSize
