import std/math

const
  MaxIterations = 8
  InvalidResult = -1.0e300

proc gaussLegendrePi(iterations: int): float64 =
  var a = 1.0
  var b = sqrt(0.5)
  var t = 0.25
  var p = 1.0
  for _ in 0 ..< iterations:
    let nextA = (a + b) / 2.0
    let nextB = sqrt(a * b)
    let difference = a - nextA
    let nextT = t - p * difference * difference
    let nextP = 2.0 * p
    a = nextA
    b = nextB
    t = nextT
    p = nextP
  let sum = a + b
  sum * sum / (4.0 * t)

proc gauss_legendre*(iterationsValue: float64): float64 {.cdecl, exportc: "gauss_legendre".} =
  if not (iterationsValue >= 0.0 and iterationsValue <= float64(MaxIterations)):
    return InvalidResult
  if iterationsValue != floor(iterationsValue): return InvalidResult
  gaussLegendrePi(int(iterationsValue))
