import std/math

proc putF32Le(output: ptr UncheckedArray[uint8], offset: int, value: float32) =
  let bits = cast[uint32](value)
  for b in 0 ..< 4: output[offset + b] = uint8((bits shr (8 * b)) and 0xFF'u32)

proc julia_sets*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "julia_sets".} =
  if input.isNil or length < 4 or length > 68: return -1
  let iterations = input[0]
  let crUnits = input[1]
  let ciUnits = input[2]
  let countValue = input[3]
  if iterations < 0 or iterations > 8 or countValue < 0 or countValue > 32: return -1
  if crUnits < -128 or crUnits > 128 or ciUnits < -128 or ciUnits > 128: return -1
  let count = int(countValue)
  if int(length) != 4 + 2 * count: return -1
  for index in 0 ..< 2 * count:
    if input[4 + index] < -128 or input[4 + index] > 128: return -1
  let needed = 8 * count
  if output.isNil or outputCapacity < csize_t(needed): return -2

  let cr = float32(crUnits) / 16.0'f32
  let ci = float32(ciUnits) / 16.0'f32
  var computed: array[64, float32]
  for point in 0 ..< count:
    var real = float32(input[4 + 2 * point]) / 16.0'f32
    var imag = float32(input[5 + 2 * point]) / 16.0'f32
    for step in 0 ..< int(iterations):
      let realSquare = real * real
      let imagSquare = imag * imag
      let realImag = real * imag
      let imagReal = imag * real
      let nextReal = (realSquare - imagSquare) + cr
      let nextImag = (realImag + imagReal) + ci
      if classify(nextReal) in {fcNan, fcInf, fcNegInf} or classify(nextImag) in {fcNan, fcInf, fcNegInf}: return -1
      real = nextReal
      imag = nextImag
    computed[2 * point] = real
    computed[2 * point + 1] = imag
  for component in 0 ..< 2 * count: putF32Le(output, component * 4, computed[component])
  int64(needed)

