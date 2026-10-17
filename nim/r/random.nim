const MaxCount = 256
const MaxInputLength = 5
const MaxOutputBytes = MaxCount * 4

proc writeU32Le(output: ptr UncheckedArray[uint8], index: int, value: uint32) =
  let offset = index * 4
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((value shr (byte * 8)) and 0xff'u32)

proc rotateRight(value: uint32, rotation: uint32): uint32 =
  let leftShift = (32'u32 - rotation) and 31'u32
  (value shr int(rotation)) or (value shl int(leftShift))

proc pcg32_random*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "pcg32_random".} =
  if values.isNil or length < 4 or length > MaxInputLength: return -1
  if length != 4: return -1

  let seed = cast[uint64](values[0])
  let multiplier = cast[uint64](values[1])
  let streamValue = values[2]
  let countValue = values[3]
  if streamValue < 0 or countValue < 0 or countValue > MaxCount: return -1

  let stream = uint64(streamValue)
  let increment = (stream shl 1) or 1'u64
  var state = seed +% increment
  state = state *% multiplier +% increment
  let count = int(countValue)
  let requiredBytes = count * 4
  if requiredBytes > MaxOutputBytes: return -1
  if output.isNil or outputCapacity < csize_t(requiredBytes): return -2

  for index in 0 ..< count:
    var value = state
    let rotation = uint32(value shr 59)
    state = state *% multiplier +% increment
    value = value xor (value shr 18)
    let xorshifted = uint32(value shr 27)
    writeU32Le(output, index, rotateRight(xorshifted, rotation))
  int64(requiredBytes)
