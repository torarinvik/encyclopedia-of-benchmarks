const maxComponent = 1_000_000_000'i64
type I64Input = ptr UncheckedArray[int64]
type U8Output = ptr UncheckedArray[uint8]

proc gcdPositive(leftInput, rightInput: int64): int64 =
  var left = leftInput
  var right = rightInput
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  left

proc boundedNeighbors(limit, x, y: int64): tuple[lowerNum, lowerDen, upperNum, upperDen: int64] =
  let divisor = gcdPositive(x, y)
  let reducedX = x div divisor
  let reducedY = y div divisor
  if reducedX <= limit and reducedY <= limit:
    return (reducedX, reducedY, reducedX, reducedY)

  var a = 0'i64
  var b = 1'i64
  var c = 1'i64
  var d = 0'i64
  while true:
    let middleNum = a + c
    let middleDen = b + d
    if middleNum > limit or middleDen > limit: break
    let targetSide = middleNum * y
    let middleSide = middleDen * x
    if targetSide == middleSide:
      return (middleNum, middleDen, middleNum, middleDen)

    if targetSide < middleSide:
      let lowerGap = b * x - a * y
      let upperGap = c * y - d * x
      var step = lowerGap div upperGap
      step = min(step, (limit - a) div c)
      if d > 0: step = min(step, (limit - b) div d)
      a += step * c
      b += step * d
    else:
      let upperGap = c * y - d * x
      let lowerGap = b * x - a * y
      var step = upperGap div lowerGap
      if a > 0: step = min(step, (limit - c) div a)
      step = min(step, (limit - d) div b)
      c += step * a
      d += step * b
  (a, b, c, d)

proc storeI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc rational_approximation*(values: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "rational_approximation".} =
  if values == nil or length != 3: return -1
  let limit = values[0]
  let x = values[1]
  let y = values[2]
  if limit < 1 or limit > maxComponent or x < 1 or x > maxComponent or
      y < 1 or y > maxComponent: return -1
  if output == nil or outputCapacity < 32: return -2

  let bounds = boundedNeighbors(limit, x, y)
  storeI64Le(output, 0, bounds.lowerNum)
  storeI64Le(output, 8, bounds.lowerDen)
  storeI64Le(output, 16, bounds.upperNum)
  storeI64Le(output, 24, bounds.upperDen)
  32
