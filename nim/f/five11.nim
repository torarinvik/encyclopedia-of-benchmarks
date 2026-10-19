const MaxInput = 13523
const MaxParseableInput = 13524
const MaxPackets = 451

proc readBits(values: ptr UncheckedArray[int64], length, bitOffset, width: int): int64 =
  let bitLength = length * 8
  if bitOffset < 0 or bitOffset > bitLength or width > bitLength - bitOffset: return -1
  let byteOffset = bitOffset shr 3
  let start = bitOffset and 7
  let byteCount = (start + width + 7) shr 3
  var window = 0'u32
  for index in 0 ..< byteCount:
    window = (window shl 8) or uint32(values[byteOffset + index])
  let shift = byteCount * 8 - start - width
  let mask = (1'u32 shl width) - 1'u32
  int64((window shr shift) and mask)

proc decodeSum(values: ptr UncheckedArray[int64], length: int): int64 =
  let packetCount = readBits(values, length, 0, 16)
  if packetCount < 0 or packetCount > MaxPackets: return -1
  var bitOffset = 16
  var total = 0'i64
  for _ in 0 ..< int(packetCount):
    let channels = readBits(values, length, bitOffset, 5)
    if channels < 0: return -1
    bitOffset += 5
    for _ in 0 ..< int(channels):
      let channel = readBits(values, length, bitOffset, 11)
      if channel < 0: return -1
      total += channel
      bitOffset += 11
    let packetBits = 5 + 11 * int(channels)
    bitOffset += (8 - (packetBits and 7)) and 7
    if bitOffset > length * 8: return -1
  total

proc five11*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "five11".} =
  if values == nil or length < 2 or length > csize_t(MaxParseableInput) or length > csize_t(MaxInput): return -1
  let inputLength = int(length)
  for index in 0 ..< inputLength:
    if values[index] < 0 or values[index] > 255: return -1
  var result = 0'i64
  for _ in 0 ..< 10000:
    result = decodeSum(values, inputLength)
    if result < 0: return -1
  result
