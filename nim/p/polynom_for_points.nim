import math

const MinPoints = 2
const MaxPoints = 8
const MinX = -4'i64
const MaxX = 4'i64
const MinY = -25000'i64
const MaxY = 25000'i64
const MaxCoefficient = 1_000_000.0
const MaxContractBytes = 124
const ScratchBytes = 125

proc appendText(buffer: var array[ScratchBytes, uint8], position: var int, text: string) =
  for byte in text:
    buffer[position] = uint8(ord(byte))
    inc position

proc appendI64(buffer: var array[ScratchBytes, uint8], position: var int, valueValue: int64) =
  var value = valueValue
  var digits: array[24, uint8]
  var count = 0
  if value < 0:
    buffer[position] = uint8(ord('-'))
    inc position
    value = -value
  while true:
    digits[count] = uint8(ord('0') + int(value mod 10))
    inc count
    value = value div 10
    if value == 0: break
  while count > 0:
    dec count
    buffer[position] = digits[count]
    inc position

proc appendCoefficient(buffer: var array[ScratchBytes, uint8], position: var int, value: float64) =
  if value == 0.0:
    if (cast[uint64](value) shr 63) != 0:
      buffer[position] = uint8(ord('-'))
      inc position
    appendText(buffer, position, "0.0")
  else:
    appendI64(buffer, position, int64(value))
    appendText(buffer, position, ".0")

proc polynom_for_points*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "polynom_for_points".} =
  if values == nil or length < 1 or length > csize_t(1 + 2 * MaxPoints): return -1
  let rawN = values[0]
  if rawN < int64(MinPoints) or rawN > int64(MaxPoints) or length != csize_t(1 + 2 * rawN): return -1
  let n = int(rawN)
  var xs: array[MaxPoints, int64]
  var matrix: array[MaxPoints, array[MaxPoints, float64]]
  var vector: array[MaxPoints, float64]
  for row in 0 ..< n:
    let x = values[1 + 2 * row]
    let y = values[2 + 2 * row]
    if x < MinX or x > MaxX or y < MinY or y > MaxY: return -1
    for previous in 0 ..< row:
      if xs[previous] == x: return -1
    xs[row] = x
    for column in 0 ..< n:
      var power = 1'i64
      for _ in 0 ..< (n - column - 1): power *= x
      matrix[row][column] = float64(power)
    vector[row] = float64(y)

  for count in 0 ..< n:
    if matrix[count][count] == 0.0:
      var pivotRow = count + 1
      for row in (count + 2) ..< n:
        if abs(matrix[row][count]) > abs(matrix[pivotRow][count]): pivotRow = row
      if pivotRow >= n or matrix[pivotRow][count] == 0.0: return -1
      for column in 0 ..< n:
        let temporary = matrix[count][column]
        matrix[count][column] = matrix[pivotRow][column]
        matrix[pivotRow][column] = temporary
      let temporary = vector[count]
      vector[count] = vector[pivotRow]
      vector[pivotRow] = temporary
    for row in 0 ..< n:
      if row == count: continue
      let fraction = matrix[row][count] / matrix[count][count]
      for column in 0 ..< n:
        let product = matrix[count][column] * fraction
        matrix[row][column] = matrix[row][column] - product
      let product = vector[count] * fraction
      vector[row] = vector[row] - product

  var coefficients: array[MaxPoints, float64]
  for index in 0 ..< n:
    let value = vector[index] / matrix[index][index]
    if value != value or value < -MaxCoefficient or value > MaxCoefficient or float64(int64(value)) != value: return -1
    coefficients[index] = value

  var buffer: array[ScratchBytes, uint8]
  var position = 0
  appendText(buffer, position, "f(x)=")
  for index in 0 ..< n:
    if index != 0:
      buffer[position] = uint8(ord('+'))
      inc position
    appendText(buffer, position, "x^")
    appendI64(buffer, position, int64(n - index - 1))
    buffer[position] = uint8(ord('*'))
    inc position
    appendCoefficient(buffer, position, coefficients[index])
  if position > MaxContractBytes: return -1
  if output == nil or csize_t(position) > outputCapacity: return -2
  for index in 0 ..< position: output[index] = buffer[index]
  int64(position)
