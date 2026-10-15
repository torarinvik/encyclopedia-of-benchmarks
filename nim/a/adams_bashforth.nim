## Bounded Adams-Bashforth methods for y' = x + y on a quarter-step grid.
proc coefficient(order: int64, offset: int): int64 =
  case order
  of 2: (if offset == 0: 3'i64 else: -1'i64)
  of 3: (if offset == 0: 23'i64 elif offset == 1: -16'i64 else: 5'i64)
  of 4: (if offset == 0: 55'i64 elif offset == 1: -59'i64 elif offset == 2: 37'i64 else: -9'i64)
  else: (if offset == 0: 1901'i64 elif offset == 1: -2774'i64 elif offset == 2: -2616'i64 elif offset == 3: -1274'i64 else: 251'i64)

proc appendInteger(valueInput: int64, output: var array[256, uint8], positionInput: int): int =
  var value = valueInput
  var digits: array[24, uint8]
  var count = 0
  var position = positionInput
  if value < 0:
    output[position] = uint8(ord('-'))
    inc position
    value = -value
  while true:
    digits[count] = uint8(value mod 10)
    inc count
    value = value div 10
    if value == 0: break
  while count > 0:
    dec count
    output[position] = uint8(ord('0')) + digits[count]
    inc position
  position

proc adams_bashforth*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "adams_bashforth".} =
  if values.isNil or length < 4: return -1
  let order = values[0]
  let steps = values[1]
  if order < 2 or order > 5 or steps < 1 or steps > 4 or length != csize_t(order + 2): return -1
  var x, y: array[14, float64]
  for i in 0 ..< int(order):
    if values[i + 2] < -100000 or values[i + 2] > 100000: return -1
    x[i] = float64(i) * 0.25
    y[i] = float64(values[i + 2]) / 100000.0
  let denominator = if order == 2: 2.0 elif order == 3: 12.0 elif order == 4: 24.0 else: 720.0
  var iterations = int(steps)
  if order == 3 or order == 5: inc iterations
  var count = int(order)
  for _ in 0 ..< iterations:
    var weighted = 0.0
    for offset in 0 ..< int(order):
      let current = count - 1 - offset
      weighted += float64(coefficient(order, offset)) * (x[current] + y[current])
    y[count] = y[count - 1] + (0.25 / denominator) * weighted
    x[count] = x[count - 1] + 0.25
    inc count
  var encoded: array[256, uint8]
  var position = 0
  for i in 0 ..< count:
    if i > 0:
      encoded[position] = uint8(ord(','))
      inc position
    position = appendInteger(int64(y[i] * 1000000.0), encoded, position)
  if output.isNil or outputCapacity < csize_t(position): return -2
  for i in 0 ..< position: output[i] = encoded[i]
  int64(position)
