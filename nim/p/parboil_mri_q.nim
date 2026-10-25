import std/math

const MaxK = 4
const MaxInputLength = 24
const OutputBytes = 8
const PiX2 = 6.2831853071795864769252867665590058'f32

proc decodeComponent(raw: int64): float32 = float32(raw) / 1_000_000'f32

proc quantizeQ(value: float32): int32 =
  let scaled = value * 1_000'f32
  let magnitude = abs(scaled)
  var whole = int32(magnitude)
  let fraction = magnitude - float32(whole)
  if fraction >= 0.5'f32: inc whole
  if scaled < 0'f32: return -whole
  whole

proc writeI32Le(output: ptr UncheckedArray[uint8], offset: int, value: int32) =
  let bits = cast[uint32](value)
  output[offset] = uint8(bits and 0xff'u32)
  output[offset + 1] = uint8((bits shr 8) and 0xff'u32)
  output[offset + 2] = uint8((bits shr 16) and 0xff'u32)
  output[offset + 3] = uint8((bits shr 24) and 0xff'u32)

## Clean-room Parboil MRI-Q profile; Illinois Open Source License in package docs.
proc parboil_mri_q*(input: ptr UncheckedArray[int64], inputLength: csize_t,
                    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "parboil_mri_q".} =
  if input == nil or inputLength < 9 or inputLength > MaxInputLength: return -1
  if input[0] < 1 or input[0] > MaxK: return -1
  let count = int(input[0])
  if inputLength != csize_t(4 + 5 * count): return -1
  for i in 1..<int(inputLength):
    if input[i] < -1_000_000 or input[i] > 1_000_000: return -1
  if output == nil or outputCapacity < OutputBytes: return -2

  let x = decodeComponent(input[1])
  let y = decodeComponent(input[2])
  let z = decodeComponent(input[3])
  var phiMagnitudes: array[MaxK, float32]
  for k in 0..<count:
    let offset = 4 + 5 * k
    let phiReal = decodeComponent(input[offset + 3])
    let phiImag = decodeComponent(input[offset + 4])
    let realSquare = phiReal * phiReal
    let imagSquare = phiImag * phiImag
    phiMagnitudes[k] = realSquare + imagSquare
  var qr = 0'f32
  var qi = 0'f32
  for k in 0..<count:
    let offset = 4 + 5 * k
    let kx = decodeComponent(input[offset])
    let ky = decodeComponent(input[offset + 1])
    let kz = decodeComponent(input[offset + 2])
    let kxX = kx * x
    let kyY = ky * y
    let kzZ = kz * z
    let xy = kxX + kyY
    let xyz = xy + kzZ
    let phase = PiX2 * xyz
    let cosPhase = float32(cos(float64(phase)))
    let sinPhase = float32(sin(float64(phase)))
    let qrTerm = phiMagnitudes[k] * cosPhase
    let qiTerm = phiMagnitudes[k] * sinPhase
    qr = qr + qrTerm
    qi = qi + qiTerm
  writeI32Le(output, 0, quantizeQ(qr))
  writeI32Le(output, 4, quantizeQ(qi))
  OutputBytes
