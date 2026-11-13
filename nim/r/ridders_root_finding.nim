import std/math

const MaxInputLength = 6

proc exactInteger(value: float64, low, high: int64): bool =
  if classify(value) in {fcNan, fcInf, fcNegInf} or value < float64(low) or value > float64(high):
    return false
  float64(int64(value)) == value

proc polynomial(id: int, x: float64): float64 =
  case id
  of 0: x*x-2.0
  of 1: x*x*x-2.0
  of 2: x*x*x+x-1.0
  else: x

proc opposite(a, b: float64): bool = (a < 0.0) != (b < 0.0)

proc riddersRootFinding*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "ridders_root_finding".} =
  if input == nil or inputLength != 5 or inputLength > MaxInputLength.csize_t: return -1
  if not exactInteger(input[0], 0, 3) or not exactInteger(input[1], -3000, 3000) or
      not exactInteger(input[2], -3000, 3000) or not exactInteger(input[3], 1, 1000) or
      not exactInteger(input[4], 24, 32): return -1
  let id = int(input[0])
  let leftMilli = int64(input[1])
  let rightMilli = int64(input[2])
  let toleranceMicro = int64(input[3])
  let iterations = int(input[4])
  if leftMilli >= rightMilli: return -1
  var left = float64(leftMilli)/1000.0
  var right = float64(rightMilli)/1000.0
  var fLeft = polynomial(id, left)
  var fRight = polynomial(id, right)
  if fLeft != 0.0 and fRight != 0.0 and not opposite(fLeft, fRight): return -1
  if output == nil or outputCapacity < 1: return -2
  if fLeft == 0.0:
    output[0] = left
    return 1
  if fRight == 0.0:
    output[0] = right
    return 1
  let tolerance = float64(toleranceMicro)/1_000_000.0
  for _ in 0 ..< iterations:
    if right-left <= tolerance:
      output[0] = (left+right)*0.5
      return 1
    let middle = (left+right)*0.5
    let fMiddle = polynomial(id, middle)
    if fMiddle == 0.0:
      output[0] = middle
      return 1
    let radicand = fMiddle*fMiddle-fLeft*fRight
    if classify(radicand) in {fcNan, fcInf, fcNegInf} or radicand <= 0.0: return -3
    let denominator = sqrt(radicand)
    if classify(denominator) in {fcNan, fcInf, fcNegInf} or denominator == 0.0: return -3
    let direction = if fLeft < fRight: -1.0 else: 1.0
    let candidate = middle+(middle-left)*direction*fMiddle/denominator
    if classify(candidate) in {fcNan, fcInf, fcNegInf} or candidate <= left or candidate >= right: return -3
    let fCandidate = polynomial(id, candidate)
    if fCandidate == 0.0:
      output[0] = candidate
      return 1
    if opposite(fLeft, fCandidate):
      right = candidate
      fRight = fCandidate
    else:
      left = candidate
      fLeft = fCandidate
    if right-left <= tolerance:
      output[0] = (left+right)*0.5
      return 1
  -3
