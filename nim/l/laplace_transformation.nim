import math

const MaxSampleCount = 64'i64
const MaxInputLength = 68
const MinSampleMicro = -1_000_000'i64
const MaxSampleMicro = 1_000_000'i64
const InvalidResult = -1.0e300

proc laplace_transformation*(input: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "laplace_transformation".} =
  if input.isNil or length < 3 or length > csize_t(MaxInputLength): return InvalidResult
  let sampleCountValue = input[0]
  let sMilli = input[1]
  let dtMicro = input[2]
  if sampleCountValue < 1 or sampleCountValue > MaxSampleCount: return InvalidResult
  let sampleCount = int(sampleCountValue)
  if length != csize_t(sampleCount + 3) or sMilli < 0 or sMilli > 1000 or
      dtMicro < 1 or dtMicro > 1_000_000: return InvalidResult

  var samples: array[64, float64]
  for index in 0 ..< sampleCount:
    let sample = input[3 + index]
    if sample < MinSampleMicro or sample > MaxSampleMicro: return InvalidResult
    samples[index] = float64(sample) / 1_000_000.0
  if sampleCount == 1: return 0.0

  let sValue = float64(sMilli) / 1000.0
  let deltaT = float64(dtMicro) / 1_000_000.0
  let stop = float64(sampleCount - 1) * deltaT
  let step = stop / float64(sampleCount - 1)
  var integrand: array[64, float64]
  for index in 0 ..< sampleCount:
    let time = if index == sampleCount - 1: stop else: float64(index) * step
    integrand[index] = samples[index] * exp(-sValue * time)

  var result = 0.0
  for index in 0 ..< sampleCount - 1:
    result += (deltaT * (integrand[index] + integrand[index + 1])) / 2.0
  result
