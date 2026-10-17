import math

const InvalidResult = -1.0e300
const MaxPhysical = 1_000_000_000_000_000'i64
const MaxFluxRate = 1_000_000_000_000_000_000'i64
const MinConstant = 1_000_000'i64
const MaxConstant = 1_000_000_000_000_000'i64
const EpsilonDefault = 8.8541878128e-12
const MuDefault = 4.0 * PI * 1e-7

proc inRange(value, limit: int64): bool = value >= -limit and value <= limit
proc decodeConstant(raw: int64, fallback: float64, value: var float64): bool =
  if raw == 0: value = fallback; return true
  if raw < MinConstant or raw > MaxConstant: return false
  value = float64(raw) / 1e18
  true
proc lawResult(actual, expected: float64): float64 =
  let tolerance = if expected != 0.0: 0.01 * abs(expected) else: 1e-10
  if abs(actual - expected) <= tolerance: 1.0 else: 0.0

proc maxwells_equations*(input: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "maxwells_equations".} =
  if input.isNil or length < 1 or length > 7: return InvalidResult
  let operation = input[0]
  case operation
  of 0:
    if length != 5: return InvalidResult
    let field, area, charge, epsilonRaw = input[1], input[2], input[3], input[4]
    if not inRange(field, MaxPhysical) or area < 0 or area > MaxPhysical or not inRange(charge, MaxPhysical): return InvalidResult
    var epsilon: float64
    if not decodeConstant(epsilonRaw, EpsilonDefault, epsilon): return InvalidResult
    let electricFlux = (float64(field) / 1e12) * (float64(area) / 1e12)
    let expectedFlux = (float64(charge) / 1e12) / epsilon
    lawResult(electricFlux, expectedFlux)
  of 1:
    if length != 3 or not inRange(input[1], MaxPhysical) or not inRange(input[2], MaxPhysical): return InvalidResult
    let circulation = float64(input[1]) / 1e12
    let expected = -(float64(input[2]) / 1e12)
    lawResult(circulation, expected)
  of 2:
    if length != 6 or not inRange(input[1], MaxPhysical) or not inRange(input[2], MaxPhysical) or not inRange(input[3], MaxFluxRate): return InvalidResult
    var mu, epsilon: float64
    if not decodeConstant(input[4], MuDefault, mu) or not decodeConstant(input[5], EpsilonDefault, epsilon): return InvalidResult
    let displacement = epsilon * (float64(input[3]) / 1e6)
    let totalCurrent = (float64(input[2]) / 1e12) + displacement
    let expected = mu * totalCurrent
    lawResult(float64(input[1]) / 1e12, expected)
  of 3, 4:
    if length != 3: return InvalidResult
    var mu, epsilon: float64
    if not decodeConstant(input[1], MuDefault, mu) or not decodeConstant(input[2], EpsilonDefault, epsilon): return InvalidResult
    if operation == 3: 1.0 / sqrt(mu * epsilon) else: sqrt(mu / epsilon)
  of 5:
    if length != 4 or not inRange(input[1], MaxPhysical) or not inRange(input[2], MaxPhysical): return InvalidResult
    var mu: float64
    if not decodeConstant(input[3], MuDefault, mu): return InvalidResult
    ((float64(input[1]) / 1e12) * (float64(input[2]) / 1e12)) / mu
  of 6:
    if length != 5 or not inRange(input[1], MaxPhysical) or not inRange(input[2], MaxPhysical): return InvalidResult
    var epsilon, mu: float64
    if not decodeConstant(input[3], EpsilonDefault, epsilon) or not decodeConstant(input[4], MuDefault, mu): return InvalidResult
    let electric = 0.5 * epsilon * pow(float64(input[1]) / 1e12, 2.0)
    let magnetic = 0.5 * pow(float64(input[2]) / 1e12, 2.0) / mu
    electric + magnetic
  else: InvalidResult
