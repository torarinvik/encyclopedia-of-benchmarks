import std/math

const InvalidResult = -1.0e300

proc transformations_2d*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "transformations_2d".} =
  if values == nil or length != 3: return InvalidResult
  let operation = values[0]
  let parameterMicro = values[1]
  let component = values[2]
  if operation < 0 or operation > 3 or component < 0 or component > 3: return InvalidResult

  var matrix: array[4, float64]
  if operation == 0:
    if parameterMicro < -1_000_000 or parameterMicro > 1_000_000: return InvalidResult
    let factor = float64(parameterMicro) / 1_000_000.0
    matrix = [factor * 1.0, factor * 0.0, factor * 0.0, factor * 1.0]
  else:
    if parameterMicro < -6_283_185 or parameterMicro > 6_283_185: return InvalidResult
    let angle = float64(parameterMicro) / 1_000_000.0
    let c = cos(angle)
    let s = sin(angle)
    if operation == 1:
      matrix = [c, -s, s, c]
    elif operation == 2:
      let cs = c * s
      matrix = [c * c, cs, cs, s * s]
    else:
      let cs = c * s
      matrix = [2.0 * c - 1.0, 2.0 * cs, 2.0 * cs, 2.0 * s - 1.0]
  matrix[int(component)]
