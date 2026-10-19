import std/math

const InputCount = 4
const MaxRoots = 3

proc solveCubic(input: ptr UncheckedArray[float64],
    roots: var array[MaxRoots, float64]): int =
  let a = input[0]
  let b = input[1]
  let c = input[2]
  let d = input[3]
  let a1 = b / a
  let a2 = c / a
  let a3 = d / a
  let q = (a1 * a1 - 3.0 * a2) / 9.0
  let r = (2.0 * a1 * a1 * a1 - 9.0 * a1 * a2 + 27.0 * a3) / 54.0
  let discriminant = r * r - q * q * q
  if discriminant == 0.0: return -1
  if discriminant <= 0.0:
    let pi = arccos(-1.0)
    let theta = arccos(r / sqrt(q * q * q))
    roots[0] = -2.0 * sqrt(q) * cos(theta / 3.0) - a1 / 3.0
    roots[1] = -2.0 * sqrt(q) * cos((theta + 2.0 * pi) / 3.0) - a1 / 3.0
    roots[2] = -2.0 * sqrt(q) * cos((theta + 4.0 * pi) / 3.0) - a1 / 3.0
    return 3
  var root = pow(sqrt(discriminant) + abs(r), 1.0 / 3.0)
  root += q / root
  root *= (if r < 0.0: 1.0 else: -1.0)
  roots[0] = root - a1 / 3.0
  1

proc mibench_automotive_basicmath_cubic*(input: ptr UncheckedArray[float64],
    inputLength: csize_t, output: ptr UncheckedArray[float64],
    outputCapacity: csize_t): int64
    {.cdecl, exportc: "mibench_automotive_basicmath_cubic".} =
  if input.isNil or inputLength != InputCount.csize_t: return -1
  for index in 0 ..< InputCount:
    if not input[index].isFinite or input[index] < -100.0 or input[index] > 100.0: return -1
  if input[0] > -1.0 and input[0] < 1.0: return -1
  var roots: array[MaxRoots, float64]
  let count = solveCubic(input, roots)
  if count < 0: return -1
  if output.isNil or outputCapacity < count.csize_t: return -2
  for index in 0 ..< count: output[index] = roots[index]
  count.int64
