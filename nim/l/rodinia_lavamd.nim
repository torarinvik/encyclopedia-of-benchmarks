## Rodinia source-order screened pair interactions over a home and one neighbor box.
import std/math

const Scale = 1_000_000.0
const Bias = 1_000_000_000_000'i64

proc roundMicro(value: float64): int64 =
  let scaled = value * Scale
  if scaled < 0.0: -int64(floor(-scaled + 0.5))
  else: int64(floor(scaled + 0.5))

proc rodinia_lavamd*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "rodinia_lavamd".} =
  if input.isNil or length < 12 or length > 42: return -1
  if input[0] < 1 or input[0] > 4 or input[1] < 1 or input[1] > 4: return -1
  let homeN = int(input[0]); let neighborN = int(input[1])
  if length != csize_t(2 + 5 * (homeN + neighborN)): return -1
  var particles: array[2, array[4, array[5, float64]]]
  let counts = [homeN, neighborN]
  var cursor = 2
  for box in 0 ..< 2:
    for p in 0 ..< counts[box]:
      for component in 0 ..< 5:
        let raw = input[cursor]; inc cursor
        if raw < 0 or raw > 1_000_000: return -1
        particles[box][p][component] = float64(raw) / Scale
  var total = 0.0
  for i in 0 ..< homeN:
    var fv = 0.0; var fx = 0.0; var fy = 0.0; var fz = 0.0
    for box in 0 ..< 2:
      for j in 0 ..< counts[box]:
        let a = particles[0][i]; let b = particles[box][j]
        let dot = a[1] * b[1] + a[2] * b[2] + a[3] * b[3]
        let r2 = a[0] + b[0] - dot
        let vij = exp(-(0.5 * r2)); let fs = 2.0 * vij
        let dx = a[1] - b[1]; let dy = a[2] - b[2]; let dz = a[3] - b[3]
        fv += b[4] * vij
        fx += b[4] * (fs * dx); fy += b[4] * (fs * dy); fz += b[4] * (fs * dz)
    total += float64(i + 1) * ((fv + fx) + fy + fz)
  Bias + roundMicro(total)
