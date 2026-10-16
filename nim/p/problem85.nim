## Search triangular-number products for the rectangle count nearest the target.
import std/math

const MaxTarget = 2_000_000_000'i64

proc triangle(side: int64): int64 =
  side * (side + 1) div 2

proc absoluteDifference(left, right: int64): int64 =
  let difference = left - right
  if difference < 0: -difference else: difference

proc problem85*(target: int64): int64 {.cdecl, exportc: "problem85".} =
  if target < 0 or target > MaxTarget: return -1
  let bound = int64(ceil(sqrt(float64(target * 2)) * 1.1))
  var bestProduct = 0'i64
  var area = 0'i64
  var triangleA = 0'i64
  for a in 1'i64 ..< bound:
    triangleA += a
    let estimate = (-1.0 + sqrt(1.0 + 8.0 * float64(target) / float64(triangleA))) / 2.0
    let bFloor = int64(floor(estimate))
    let bCeil = int64(ceil(estimate))
    let firstProduct = triangleA * triangle(bFloor)
    let secondProduct = triangleA * triangle(bCeil)
    if absoluteDifference(target, firstProduct) < absoluteDifference(target, bestProduct):
      bestProduct = firstProduct
      area = a * bFloor
    if absoluteDifference(target, secondProduct) < absoluteDifference(target, bestProduct):
      bestProduct = secondProduct
      area = a * bCeil
  area
