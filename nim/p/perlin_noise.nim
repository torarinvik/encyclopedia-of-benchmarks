const MaxDimension = 8
const MaxInputElements = 5
const MaxParseableInputElements = 6
const MaxOutputElements = MaxDimension * MaxDimension
const JavaMultiplier = 0x5DEECE66D'u64
const JavaAddend = 0xB'u64
const JavaMask = (1'u64 shl 48) - 1

proc roundedAdd(a, b: float32): float32 = float32(a + b)
proc roundedSub(a, b: float32): float32 = float32(a - b)
proc roundedMul(a, b: float32): float32 = float32(a * b)
proc roundedDiv(a, b: float32): float32 = float32(a / b)

proc javaNext(state: var uint64, bits: int): uint32 =
  state = (state *% JavaMultiplier +% JavaAddend) and JavaMask
  uint32(state shr (48 - bits))

proc interpolate(a, b, alpha: float32): float32 =
  let oneMinusAlpha = roundedSub(1.0'f32, alpha)
  let left = roundedMul(a, oneMinusAlpha)
  let right = roundedMul(alpha, b)
  roundedAdd(left, right)

proc exactInteger(value, minimum, maximum: float64): bool =
  value == value and value >= minimum and value <= maximum and float64(int64(value)) == value

proc perlin_noise*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "perlin_noise".} =
  if input == nil or length < 4 or length > csize_t(MaxParseableInputElements): return -1
  if length != csize_t(MaxInputElements): return -1
  if not exactInteger(input[0], 1.0, 8.0) or not exactInteger(input[1], 1.0, 8.0) or
      not exactInteger(input[2], 1.0, 4.0) or not exactInteger(input[4], 0.0, 2147483647.0) or
      (input[3] != 0.5 and input[3] != 0.75 and input[3] != 1.0): return -1

  let width = int(input[0])
  let height = int(input[1])
  let octaveCount = int(input[2])
  let seed = uint64(input[4])
  let count = width * height
  var base: array[MaxOutputElements, float32]
  var layers: array[4 * MaxOutputElements, float32]
  var result: array[MaxOutputElements, float32]

  var state = (seed xor JavaMultiplier) and JavaMask
  for x in 0 ..< width:
    for y in 0 ..< height:
      base[x * height + y] = roundedDiv(float32(javaNext(state, 24)), 16777216.0'f32)

  for octave in 0 ..< octaveCount:
    let period = 1 shl octave
    let frequency = roundedDiv(1.0'f32, float32(period))
    let offset = octave * MaxOutputElements
    for x in 0 ..< width:
      let x0 = (x div period) * period
      let x1 = (x0 + period) mod width
      let horizontal = roundedMul(float32(x - x0), frequency)
      for y in 0 ..< height:
        let y0 = (y div period) * period
        let y1 = (y0 + period) mod height
        let vertical = roundedMul(float32(y - y0), frequency)
        let top = interpolate(base[x0 * height + y0], base[x1 * height + y0], horizontal)
        let bottom = interpolate(base[x0 * height + y1], base[x1 * height + y1], horizontal)
        layers[offset + x * height + y] = interpolate(top, bottom, vertical)

  let persistence = float32(input[3])
  var amplitude = 1.0'f32
  var totalAmplitude = 0.0'f32
  for octave in countdown(octaveCount - 1, 0):
    amplitude = roundedMul(amplitude, persistence)
    totalAmplitude = roundedAdd(totalAmplitude, amplitude)
    let offset = octave * MaxOutputElements
    for i in 0 ..< count:
      result[i] = roundedAdd(result[i], roundedMul(layers[offset + i], amplitude))
  let inverseTotal = roundedDiv(1.0'f32, totalAmplitude)
  for i in 0 ..< count: result[i] = roundedMul(result[i], inverseTotal)

  if output == nil or outputCapacity < csize_t(count): return -2
  for i in 0 ..< count: output[i] = float64(result[i])
  int64(count)
