import std/math

const InvalidResult = -1.0e300
type I64Input = ptr UncheckedArray[int64]

proc roundedSix(value: float64): float64 =
  if value < 0.0 or value > 1.0e6: return InvalidResult
  let scaled = value * 1_000_000.0
  var lower = floor(scaled)
  let fraction = scaled - lower
  if fraction >= 0.499 and fraction <= 0.501: return InvalidResult
  if fraction > 0.5: lower += 1.0
  lower / 1_000_000.0

proc decodePositive(values: I64Input, index: int): float64 =
  let result = cast[float64](values[index])
  if result.isNaN or result.isInf or result < 1.0e-6 or result > 1.0e6: return 0.0
  result

proc grahams_law*(values: I64Input, length: csize_t): float64
    {.cdecl, exportc: "grahams_law".} =
  if values.isNil or length < 3 or length > 4 or values[0] < 0 or values[0] > 4: return InvalidResult
  let operation = values[0]
  if (operation == 0 and length != 3) or (operation != 0 and length != 4): return InvalidResult
  let first = decodePositive(values, 1)
  let second = decodePositive(values, 2)
  if first == 0.0 or second == 0.0: return InvalidResult
  var result: float64
  if operation == 0:
    result = sqrt(second / first)
  else:
    let third = decodePositive(values, 3)
    if third == 0.0: return InvalidResult
    if operation == 1: result = first * sqrt(third / second)
    elif operation == 2: result = first / sqrt(third / second)
    elif operation == 3: result = first / pow(second / third, 2.0)
    else: result = pow(second / third, 2.0) / first
  if result.isNaN or result.isInf: return InvalidResult
  roundedSix(result)
