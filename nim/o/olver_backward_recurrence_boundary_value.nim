import std/math

const MaxParseableInputLength = 53
const MaxNmax = 12

proc exactInteger(value: float64, low, high: int): bool =
  if classify(value) in {fcNan, fcInf, fcNegInf} or value < float64(low) or value > float64(high):
    return false
  float64(int(value)) == value

proc finite(value: float64): bool =
  classify(value) notin {fcNan, fcInf, fcNegInf}

proc olver_backward_recurrence_boundary_value*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "olver_backward_recurrence_boundary_value".} =
  if input == nil or inputLength < 8 or inputLength > MaxParseableInputLength.csize_t: return -1
  for i in 0 ..< inputLength.int:
    if not finite(input[i]): return -1
  if not exactInteger(input[0], 1, 8) or not exactInteger(input[1], 1, MaxNmax): return -1
  let m = int(input[0])
  let nmax = int(input[1])
  if m > nmax or inputLength != (4 + 4 * nmax).csize_t: return -1
  if input[2] < 9.094947017729282e-13 or input[2] > 0.5 or abs(input[3]) > 16.0: return -1
  for i in 0 ..< nmax:
    if abs(input[4 + i]) < 0.0625 or abs(input[4 + i]) > 16.0 or
        abs(input[4 + nmax + i]) > 16.0 or abs(input[4 + 2 * nmax + i]) > 16.0 or
        abs(input[4 + 3 * nmax + i]) > 16.0: return -1
  let required = m + 2
  if output == nil or outputCapacity < required.csize_t: return -2

  var p: array[14, float64]
  var e: array[13, float64]
  var w: array[13, float64]
  p[1] = 1.0
  e[0] = input[3]
  for n in 1 .. m:
    let a = input[4 + n - 1]
    let b = input[4 + nmax + n - 1]
    let c = input[4 + 2 * nmax + n - 1]
    let d = input[4 + 3 * nmax + n - 1]
    p[n + 1] = (b * p[n] - c * p[n - 1]) / a
    e[n] = (c * e[n - 1] - d * p[n]) / a
    if not finite(p[n + 1]) or not finite(e[n]): return -3
  for n in 1 .. m:
    let product = p[n] * p[n + 1]
    if product == 0.0 or not finite(product) or not finite(e[n] / product): return -3
  var minimum = abs(e[1] / (p[1] * p[2]))
  for n in 2 .. m:
    minimum = min(minimum, abs(e[n] / (p[n] * p[n + 1])))
  let threshold = input[2] * minimum
  var endpoint = 0
  for n in m .. nmax:
    if n > m:
      let a = input[4 + n - 1]
      let b = input[4 + nmax + n - 1]
      let c = input[4 + 2 * nmax + n - 1]
      let d = input[4 + 3 * nmax + n - 1]
      p[n + 1] = (b * p[n] - c * p[n - 1]) / a
      e[n] = (c * e[n - 1] - d * p[n]) / a
      if not finite(p[n + 1]) or not finite(e[n]): return -3
    let product = p[n] * p[n + 1]
    if product == 0.0 or not finite(product): return -3
    let ratio = abs(e[n] / product)
    if not finite(ratio): return -3
    if ratio <= threshold:
      endpoint = n
      break
  if endpoint == 0: return -3
  for n in countdown(endpoint - 1, 0):
    w[n] = (p[n] * w[n + 1] + e[n]) / p[n + 1]
    if not finite(w[n]): return -3
  output[0] = float64(endpoint)
  for i in 0 .. m: output[i + 1] = w[i]
  required.int64
