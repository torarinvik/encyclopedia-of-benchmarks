import std/math

const MaxN = 10000
const OutputCount = 9

proc partialsums*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "partialsums".} =
  if input.isNil or length != csize_t(1): return -1
  let nValue = input[0]
  if not nValue.isFinite or nValue != floor(nValue) or nValue < 1.0 or nValue > float64(MaxN): return -1
  let n = int(nValue)
  var geometric = 0.0
  var inverseSqrt = 0.0
  var flint = 0.0
  var cookson = 0.0
  var telescoping, harmonic, zeta, alternating, gregory: array[2, float64]
  var term = 1.0
  let vectorLimit = n + (n and 1)
  for k in 1 .. vectorLimit:
    let kd = float64(k)
    let lane = (k - 1) and 1
    if k <= n:
      let k3 = kd * kd * kd
      let s = sin(kd)
      let c = cos(kd)
      geometric += term
      term *= 2.0 / 3.0
      inverseSqrt += 1.0 / sqrt(kd)
      flint += 1.0 / (k3 * s * s)
      cookson += 1.0 / (k3 * c * c)
    telescoping[lane] += 1.0 / (kd * (kd + 1.0))
    harmonic[lane] += 1.0 / kd
    zeta[lane] += 1.0 / (kd * kd)
    alternating[lane] += (if lane == 0: 1.0 else: -1.0) / kd
    gregory[lane] += (if lane == 0: 1.0 else: -1.0) / (2.0 * kd - 1.0)
  if output.isNil or capacity < csize_t(OutputCount): return -2
  output[0] = geometric
  output[1] = inverseSqrt
  output[2] = telescoping[0] + telescoping[1]
  output[3] = flint
  output[4] = cookson
  output[5] = harmonic[0] + harmonic[1]
  output[6] = zeta[0] + zeta[1]
  output[7] = alternating[0] + alternating[1]
  output[8] = gregory[0] + gregory[1]
  int64(OutputCount)
