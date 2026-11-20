import std/math

const
  PiValue = 3.14159265358979323846264338327950288
  TauValue = 6.28318530717958647692528676655900576
  MaxN = 64
  CutoffScale = 0.0000000037252902984619140625

proc cmdWrap(angle: float64): float64 =
  result = angle - floor((angle + PiValue) / TauValue) * TauValue
  if result >= PiValue: result -= TauValue
  if result < -PiValue: result += TauValue

proc circular_mean_direction*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64 {.cdecl, exportc.} =
  if input.isNil or length < csize_t(2) or length > csize_t(66): return -1
  let countValue = input[0]
  if not countValue.isFinite or floor(countValue) != countValue or
      countValue < 1.0 or countValue > float64(MaxN): return -1
  let count = int(countValue)
  if length != csize_t(count + 1): return -1

  var sumCos = 0.0
  var sumSin = 0.0
  var correctionCos = 0.0
  var correctionSin = 0.0
  for index in 0 ..< count:
    let raw = input[index + 1]
    if not raw.isFinite or abs(raw) > 8.0 * PiValue: return -1
    let angle = cmdWrap(raw)
    let adjustedCos = cos(angle) - correctionCos
    let nextCos = sumCos + adjustedCos
    correctionCos = (nextCos - sumCos) - adjustedCos
    sumCos = nextCos
    let adjustedSin = sin(angle) - correctionSin
    let nextSin = sumSin + adjustedSin
    correctionSin = (nextSin - sumSin) - adjustedSin
    sumSin = nextSin
  let resultant = sqrt(sumCos * sumCos + sumSin * sumSin)
  if not resultant.isFinite or
      resultant <= float64(count) * CutoffScale: return -1
  if output.isNil or capacity < csize_t(1): return -2
  output[0] = cmdWrap(arctan2(sumSin, sumCos))
  1
