import std/math

const Tolerance = 1.0e-8

proc functionValue(functionId: int, x: float64): float64 =
  case functionId
  of 0: x * x * x - x - 2.0
  of 1: x * x + 1.0
  else: x * x - 4.0 * x + 3.0

proc brent_method*(function_id, input_left, input_right: float64): float64
    {.cdecl, exportc: "brent_method".} =
  if function_id != 0.0 and function_id != 1.0 and function_id != 2.0 or
      classify(input_left) == fcNan or classify(input_right) == fcNan or
      input_left < -4.0 or input_left > 4.0 or input_right < -4.0 or input_right > 4.0 or input_left >= input_right:
    return -1.0e300
  let functionId = int(function_id)
  var left = input_left
  var right = input_right
  var fLeft = functionValue(functionId, left)
  var fRight = functionValue(functionId, right)
  if fLeft * fRight >= 0.0: return -1.0e300
  if abs(fLeft) < abs(fRight):
    swap(left, right)
    swap(fLeft, fRight)

  var c = left
  var fC = fLeft
  var d = right - left
  for iteration in 0 ..< 100:
    if fRight == 0.0: return right
    var candidate: float64
    if fC != fLeft and fC != fRight:
      candidate = left * fRight * fC / ((fLeft - fRight) * (fLeft - fC)) +
          right * fLeft * fC / ((fRight - fLeft) * (fRight - fC)) +
          c * fLeft * fRight / ((fC - fLeft) * (fC - fRight))
    else:
      candidate = right - fRight * (right - left) / (fRight - fLeft)

    let quarter = (3.0 * left + right) / 4.0
    let outside = if right > left: not (quarter < candidate and candidate < right)
                  else: not (right < candidate and candidate < quarter)
    let useBisection = outside or
        (iteration > 1 and abs(candidate - right) >= abs(right - c) / 2.0) or
        (iteration <= 1 and abs(candidate - right) >= abs(c - d) / 2.0) or
        (iteration > 1 and abs(right - c) < Tolerance) or
        (iteration <= 1 and abs(c - d) < Tolerance)
    if useBisection:
      candidate = (left + right) / 2.0
      d = right - left

    let fCandidate = functionValue(functionId, candidate)
    d = c
    c = right
    fC = fRight
    if fLeft * fCandidate < 0.0:
      right = candidate
      fRight = fCandidate
    else:
      left = candidate
      fLeft = fCandidate
    if abs(fLeft) < abs(fRight):
      swap(left, right)
      swap(fLeft, fRight)
    if abs(right - left) < Tolerance: return right
  right
