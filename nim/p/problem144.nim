import std/math

const InvalidResult = -1.0e300
const MaxReflections = 10_000

proc isClose(left, right: float64): bool =
  abs(left - right) <= 1.0e-9 * max(abs(left), abs(right))

proc nextPoint(pointX, pointY, incomingGradient: float64): tuple[x, y, gradient: float64] =
  let normalGradient = pointY / 4.0 / pointX
  let s2 = 2.0 * normalGradient / (1.0 + normalGradient * normalGradient)
  let c2 = (1.0 - normalGradient * normalGradient) / (1.0 + normalGradient * normalGradient)
  let outgoingGradient = (s2 - c2 * incomingGradient) / (c2 + s2 * incomingGradient)
  let quadraticTerm = outgoingGradient * outgoingGradient + 4.0
  let lineOffset = pointY - outgoingGradient * pointX
  let linearTerm = 2.0 * outgoingGradient * lineOffset
  let constantTerm = lineOffset * lineOffset - 100.0
  let root = sqrt(linearTerm * linearTerm - 4.0 * quadraticTerm * constantTerm)
  let xMinus = (-linearTerm - root) / (2.0 * quadraticTerm)
  let xPlus = (-linearTerm + root) / (2.0 * quadraticTerm)
  let nextX = if isClose(xPlus, pointX): xMinus else: xPlus
  (nextX, pointY + outgoingGradient * (nextX - pointX), outgoingGradient)

proc problem144*(firstXCoord, firstYCoord: float64): float64 {.cdecl, exportc: "problem144".} =
  if firstXCoord != firstXCoord or firstYCoord != firstYCoord or
      firstXCoord < 1.0e-5 or firstXCoord > 5.0 or firstYCoord < -10.0 or firstYCoord > 0.0:
    return InvalidResult
  let ellipseResidual = 4.0 * firstXCoord * firstXCoord + firstYCoord * firstYCoord - 100.0
  if abs(ellipseResidual) > 1.0e-6: return InvalidResult

  var pointX = firstXCoord
  var pointY = firstYCoord
  var gradient = (10.1 - pointY) / (0.0 - pointX)
  var reflections = 0
  while not (pointX >= -0.01 and pointX <= 0.01 and pointY > 0.0):
    if reflections >= MaxReflections: return InvalidResult
    let next = nextPoint(pointX, pointY, gradient)
    if next.x != next.x or next.y != next.y: return InvalidResult
    pointX = next.x
    pointY = next.y
    gradient = next.gradient
    inc reflections
  float64(reflections)
