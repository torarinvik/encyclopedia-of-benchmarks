import std/math

const MaxN = 8'i64
const MaxP = 6'i64
const InvalidResult = -1.0e300

type I64Input = ptr UncheckedArray[int64]

proc minkowski_distance*(packed: I64Input, length: csize_t): float64 {.cdecl, exportc: "minkowski_distance".} =
  if packed == nil or length < 2 or length > 18: return InvalidResult
  let n = packed[0]
  let p = packed[1]
  if n < 0 or n > MaxN or p < 3 or p > MaxP or length != csize_t(2 + 2 * n): return InvalidResult
  for index in 0 ..< int(n):
    if packed[2 + index] < -100 or packed[2 + index] > 100 or packed[2 + int(n) + index] < -100 or packed[2 + int(n) + index] > 100: return InvalidResult
  var total = 0'i64
  for index in 0 ..< int(n):
    var difference = packed[2 + index] - packed[2 + int(n) + index]
    if difference < 0: difference = -difference
    var term = 1'i64
    for _ in 0 ..< int(p): term *= difference
    total += term
  pow(float64(total), 1.0 / float64(p))
