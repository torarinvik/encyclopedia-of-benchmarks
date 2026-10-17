import std/math

const MaxEquations = 5
const MaxInputLength = 31
const MaxOutputBytes = 48
const HalfStepLimit = 4_503_599_627_370_496.0
const MaxTickMagnitude = 2_251_799_813_685_248'i64

proc fma(first, second, third: float64): float64 {.importc: "fma", header: "<math.h>".}

proc finiteValue(value: float64): bool =
  value == value and value < 1.7976931348623157e308 and value > -1.7976931348623157e308

proc writeI64Le(output: var array[MaxOutputBytes, uint8], offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255'u64)
    bits = bits shr 8

proc simultaneous_linear_equation_solver*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "simultaneous_linear_equation_solver".} =
  if input == nil or length < 2 or length > MaxInputLength: return -1
  let nValue = input[0]
  if nValue < 1 or nValue > MaxEquations: return -1
  let n = int(nValue)
  if int(length) != 1 + n * (n + 1): return -1

  var matrix: array[30, float64]
  var hasZero = false
  for row in 0 ..< n:
    for col in 0 .. n:
      let raw = input[1 + row * (n + 1) + col]
      if raw < -100_000 or raw > 100_000: return -1
      matrix[row * 6 + col] = float64(raw) / 1_000.0
      hasZero = hasZero or raw == 0

  if n == 1:
    if matrix[0] == 0.0: return -1
  else:
    if hasZero:
      var fullRow = n
      for row in 0 ..< n:
        var allNonzero = true
        for col in 0 .. n:
          if matrix[row * 6 + col] == 0.0: allNonzero = false
        if allNonzero:
          fullRow = row
          break
      if fullRow == n: return -1
      if fullRow != 0:
        for col in 0 .. n:
          let saved = matrix[fullRow * 6 + col]
          for row in countdown(fullRow, 1):
            matrix[row * 6 + col] = matrix[(row - 1) * 6 + col]
          matrix[col] = saved

    var level = 0
    while level + 2 <= n:
      if matrix[level * 6 + level] == 0.0: return -1
      for row in level ..< n:
        let magnitude = matrix[row * 6 + level]
        if magnitude != 0.0:
          for col in level .. n:
            matrix[row * 6 + col] /= magnitude
      var firstRow: array[6, float64]
      for col in level .. n: firstRow[col] = matrix[level * 6 + col]
      for row in level + 1 ..< n:
        if matrix[row * 6 + level] != 0.0:
          for col in level .. n:
            matrix[row * 6 + col] = firstRow[col] - matrix[row * 6 + col]
      inc level

  for row in 0 ..< n:
    for col in row .. n:
      if not finiteValue(matrix[row * 6 + col]): return -1

  var solutions: array[5, float64]
  for row in countdown(n - 1, 0):
    if matrix[row * 6 + row] == 0.0: return -1
    var value = matrix[row * 6 + n]
    for col in row + 1 ..< n: value -= matrix[row * 6 + col] * solutions[col]
    value /= matrix[row * 6 + row]
    if not finiteValue(value): return -1
    solutions[row] = value

  var buffer: array[MaxOutputBytes, uint8]
  writeI64Le(buffer, 0, nValue)
  for row in 0 ..< n:
    let scaled = solutions[row] * 100_000.0
    if not finiteValue(scaled) or scaled <= -HalfStepLimit or scaled >= HalfStepLimit: return -1
    let lower = floor(scaled)
    let midpoint = lower + 0.5
    let exactSide = fma(solutions[row], 100_000.0, -midpoint)
    if not finiteValue(exactSide): return -1
    var rounded = int64(lower)
    if exactSide > 0.0 or (exactSide == 0.0 and rounded mod 2 != 0): inc rounded
    if rounded < -MaxTickMagnitude or rounded > MaxTickMagnitude: return -1
    let roundedValue = float64(rounded) / 100_000.0
    let projected = roundedValue * 100_000.0
    if not finiteValue(projected): return -1
    let projectedLower = floor(projected)
    let projectedMidpoint = projectedLower + 0.5
    var ticks = int64(projectedLower)
    if projected > projectedMidpoint or
        (projected == projectedMidpoint and ticks mod 2 != 0): inc ticks
    if ticks < -MaxTickMagnitude or ticks > MaxTickMagnitude: return -1
    writeI64Le(buffer, 8 + row * 8, ticks)

  let needed = 8 + 8 * n
  if output == nil or int(capacity) < needed: return -2
  for index in 0 ..< needed: output[index] = buffer[index]
  int64(needed)
