## Composite Simpson quadrature for the source's four sample functions on [1, 3].
import std/math

const InvalidResult = -1.0
const MaxIntervals = 128

proc sample(functionId: int, x: float64): float64 =
  case functionId
  of 0: sqrt(x) + ln(x)
  of 1: exp(-x) * (4.0 - pow(x, 2.0))
  of 2: sqrt(2.0 * pow(x, 3.0) + 3.0)
  else: x + ln(2.0 * x + 1.0)

proc composite_simpson_rule*(intervalsInput, functionIdInput: float64): float64 {.cdecl, exportc: "composite_simpson_rule".} =
  if intervalsInput != intervalsInput or functionIdInput != functionIdInput or
      intervalsInput < 2.0 or intervalsInput > float64(MaxIntervals) or
      functionIdInput < 0.0 or functionIdInput > 3.0 or
      floor(intervalsInput) != intervalsInput or floor(functionIdInput) != functionIdInput:
    return InvalidResult
  let intervals = int(intervalsInput)
  if intervals mod 2 != 0: return InvalidResult
  let functionId = int(functionIdInput)
  let h = 2.0 / float64(intervals)
  var x = 1.0
  var sum = 0.0
  for i in 0..intervals:
    let y = sample(functionId, x)
    let weight = if i == 0 or i == intervals: 1.0 elif i mod 2 == 1: 4.0 else: 2.0
    sum += weight * y
    x += h
  sum * (h / 3.0)
