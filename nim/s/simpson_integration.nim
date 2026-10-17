import std/math

const InvalidResult = -1.0e300
const MaxEndpointMicro = 10_000_000'i64

proc integrand(x: float64): float64 =
  exp(-x) * (4.0 - pow(x, 2.0))

proc simpson_integration*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "simpson_integration".} =
  if values == nil or length != 3: return InvalidResult
  let intervals = values[0]
  let aMicro = values[1]
  let bMicro = values[2]
  if intervals < 2 or intervals > 128 or intervals mod 2 != 0 or
      aMicro < -MaxEndpointMicro or aMicro > MaxEndpointMicro or
      bMicro < -MaxEndpointMicro or bMicro > MaxEndpointMicro or aMicro > bMicro:
    return InvalidResult
  let a = float64(aMicro) / 1_000_000.0
  let b = float64(bMicro) / 1_000_000.0
  if a == b: return 0.0
  let h = (b - a) / float64(intervals)
  var xi = a
  var total = 0.0
  for i in 0 .. int(intervals):
    let sample = integrand(xi)
    if i == 0 or i == int(intervals): total += sample
    elif i mod 2 != 0: total += 4.0 * sample
    else: total += 2.0 * sample
    xi += h
  (h / 3.0) * total
