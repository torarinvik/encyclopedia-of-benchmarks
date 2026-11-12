import std/math

const MaxPairs = 64
const DrawScale = 4_294_967_296.0
const Tau = 6.283185307179586476925286766559

proc isBoundedInteger(value, minimum, maximum: float64): bool =
  value.isFinite and floor(value) == value and value >= minimum and value <= maximum

proc box_muller_cartesian_normal*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "box_muller_cartesian_normal".} =
  if input.isNil or length < csize_t(2) or length > csize_t(1 + 2 * MaxPairs): return -1
  if not isBoundedInteger(input[0], 1.0, float64(MaxPairs)): return -1
  let pairCount = int(input[0])
  if length != csize_t(1 + 2 * pairCount): return -1
  for index in 0 ..< 2 * pairCount:
    if not isBoundedInteger(input[1 + index], 0.0, 4_294_967_295.0): return -1

  let resultCount = 2 * pairCount
  if output.isNil or capacity < csize_t(resultCount): return -2
  for pair in 0 ..< pairCount:
    let radial = (input[1 + 2 * pair] + 1.0) / DrawScale
    let angular = input[2 + 2 * pair] / DrawScale
    let radius = sqrt(-2.0 * ln(radial))
    let angle = Tau * angular
    output[2 * pair] = radius * cos(angle)
    output[2 * pair + 1] = radius * sin(angle)
  int64(resultCount)
