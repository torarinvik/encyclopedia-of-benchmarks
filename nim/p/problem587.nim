import std/math

const InvalidResult = -1.0e300
const MinFraction = 0.001
const MaxFraction = 0.1
const MaxN = 100_000
const PiValue = 3.141592653589793238462643383279502884

proc circleBottomArcIntegral(point: float64): float64 =
  ((1.0 - 2.0 * point) * sqrt(point - point * point) +
    2.0 * point + arcsin(sqrt(1.0 - point))) / 4.0

proc concaveTriangleArea(n: int): float64 =
  let circles = float64(n)
  let intersectionY = (circles + 1.0 - sqrt(2.0 * circles)) / (2.0 * (circles * circles + 1.0))
  let intersectionX = circles * intersectionY
  let triangleArea = intersectionX * intersectionY / 2.0
  let concaveRegionArea = circleBottomArcIntegral(0.5) - circleBottomArcIntegral(intersectionX)
  triangleArea + concaveRegionArea

proc problem587*(fraction: float64): float64 {.cdecl, exportc: "problem587".} =
  if fraction != fraction or fraction < MinFraction or fraction > MaxFraction: return InvalidResult
  let lSectionArea = (1.0 - PiValue / 4.0) / 4.0
  for n in 1 .. MaxN:
    if concaveTriangleArea(n) / lSectionArea < fraction: return float64(n)
  InvalidResult
