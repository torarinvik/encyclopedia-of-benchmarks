const maxDimension = 64
const invalidResult = -1e300
type Vector = array[maxDimension, float64]

proc gesummv*(values: ptr int64, length: uint64): float64 {.cdecl, exportc: "gesummv".} =
  if values == nil or length != 1 or values[0] < 1 or values[0] > maxDimension: return invalidResult
  let n = int(values[0])
  var x: Vector
  for i in 0 ..< n: x[i] = float64(i mod n) / float64(n)
  var result = 0.0
  for i in 0 ..< n:
    var temporary = 0.0
    var y = 0.0
    for j in 0 ..< n:
      let a = float64((i * j + 1) mod n) / float64(n)
      let b = float64((i * j + 2) mod n) / float64(n)
      temporary = a * x[j] + temporary
      y = b * x[j] + y
    y = 1.5 * temporary + 1.2 * y
    result += y
  result
