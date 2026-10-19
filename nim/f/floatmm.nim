const Side = 40
const MaxPasses = 40
const MaxOutputBytes = 14 * Side

proc roundedAdd(left, right: float32): float32 {.noinline.} = float32(left + right)
proc roundedMul(left, right: float32): float32 {.noinline.} = float32(left * right)
proc roundedDiv(left, right: float32): float32 {.noinline.} = float32(left / right)

proc nextRandom(seed: var uint32): uint32 =
  seed = (seed * 1309'u32 + 13849'u32) and 65535'u32
  seed

proc computeDiagonalCell(selected: int): float32 =
  var left: array[Side * Side, float32]
  var right: array[Side * Side, float32]
  var productMatrix: array[Side * Side, float32]
  var seed = 74755'u32
  for row in 0 ..< Side:
    for column in 0 ..< Side:
      let temp = nextRandom(seed)
      let remainder = int32(temp - (temp div 120'u32) * 120'u32)
      left[row * Side + column] = roundedDiv(float32(remainder - 60), 3.0'f32)
  for row in 0 ..< Side:
    for column in 0 ..< Side:
      let temp = nextRandom(seed)
      let remainder = int32(temp - (temp div 120'u32) * 120'u32)
      right[row * Side + column] = roundedDiv(float32(remainder - 60), 3.0'f32)
  for row in 0 ..< Side:
    for column in 0 ..< Side:
      var total = 0.0'f32
      for inner in 0 ..< Side:
        let product = roundedMul(left[row * Side + inner], right[inner * Side + column])
        total = roundedAdd(total, product)
      productMatrix[row * Side + column] = total
  productMatrix[selected * Side + selected]

proc writeUnsigned(value: uint64, output: ptr UncheckedArray[uint8], offset: int): int =
  var reversed: array[24, uint8]
  var count = 0
  var remaining = value
  while true:
    reversed[count] = uint8(48'u64 + remaining mod 10'u64)
    inc count
    remaining = remaining div 10'u64
    if remaining == 0'u64: break
  for index in 0 ..< count:
    output[offset + index] = reversed[count - index - 1]
  count

proc writeFixedSix(value: float32, output: ptr UncheckedArray[uint8], offset: int): int =
  let bits = cast[uint32](value)
  let exponentBits = (bits shr 23) and 255'u32
  let fractionBits = bits and 0x7fffff'u32
  let significand = if exponentBits == 0'u32: uint64(fractionBits)
                    else: uint64((1'u32 shl 23) or fractionBits)
  let shift = if exponentBits == 0'u32: -149 else: int(exponentBits) - 150
  let numerator = significand * 1_000_000'u64
  var micros: uint64
  if shift >= 0:
    micros = numerator shl shift
  else:
    let denominatorShift = -shift
    if denominatorShift >= 64:
      micros = 0'u64
    else:
      micros = numerator shr denominatorShift
      let mask = (1'u64 shl denominatorShift) - 1'u64
      let remainder = numerator and mask
      let halfway = 1'u64 shl (denominatorShift - 1)
      if remainder > halfway or (remainder == halfway and (micros and 1'u64) != 0'u64):
        inc micros
  var position = offset
  if (bits shr 31) != 0'u32:
    output[position] = uint8(ord('-'))
    inc position
  position += writeUnsigned(micros div 1_000_000'u64, output, position)
  output[position] = uint8(ord('.'))
  inc position
  let fractional = uint32(micros mod 1_000_000'u64)
  var place = 100_000'u32
  while place > 0'u32:
    output[position] = uint8(48'u32 + (fractional div place) mod 10'u32)
    inc position
    place = place div 10'u32
  output[position] = uint8(ord('\n'))
  inc position
  position - offset

proc floatmm*(passes: int64, output: ptr UncheckedArray[uint8],
              outputCapacity: csize_t): int64 {.cdecl, exportc: "floatmm".} =
  if passes < 0 or passes > MaxPasses: return -1
  if passes == 0: return 0
  if output.isNil: return -2
  var formatted: array[MaxOutputBytes, uint8]
  let buffer = cast[ptr UncheckedArray[uint8]](addr formatted[0])
  var required = 0
  for run in 0 ..< int(passes):
    let diagonal = computeDiagonalCell(run)
    required += writeFixedSix(diagonal, buffer, required)
  if outputCapacity < csize_t(required): return -2
  for index in 0 ..< required: output[index] = formatted[index]
  int64(required)
