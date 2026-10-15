import std/math

const
  Epsilon = 1.4901161193847656e-8
  Pi64 = 3.141592653589793238462643383279502884
  TwoPi = 2.0 * Pi64
  ThreePi = 3.0 * Pi64

proc objectiveValue(x, objectiveId: float64): float64 =
  if objectiveId == 0.0:
    let offset = x - 2.0
    return offset * offset
  if objectiveId == 0.5: return cos(x)
  -cos(x)

proc hasValidBracket(low, high, objectiveId: float64): bool =
  if objectiveId == 0.0: return low < 2.0 and 2.0 < high
  if objectiveId == 0.5: return low >= 0.0 and high <= TwoPi and low < Pi64 and Pi64 < high
  objectiveId == 1.0 and low >= Pi64 and high <= ThreePi and low < TwoPi and TwoPi < high

proc brent_method_extrema*(start, ending, objectiveId: float64): float64
    {.cdecl, exportc: "brent_method_extrema".} =
  if start != start or ending != ending or objectiveId != objectiveId or
      start < -10.0 or start > 10.0 or ending < -10.0 or ending > 10.0:
    return -1.0
  var a = start
  var b = ending
  if a > b: swap(a, b)
  if b - a <= Epsilon or
      (objectiveId != 0.0 and objectiveId != 0.5 and objectiveId != 1.0) or
      not hasValidBracket(a, b, objectiveId):
    return -1.0

  let goldenRatio = (3.0 - sqrt(5.0)) / 2.0
  var v = a + goldenRatio * (b - a)
  var w = v
  var x = v
  var fv = objectiveValue(v, objectiveId)
  var fw = fv
  var fx = fv
  var p = 0.0
  var q = 0.0
  var r = 0.0
  var d = 0.0
  var e = 0.0

  for iteration in 0 ..< 256:
    let midpoint = (a + b) / 2.0
    let tolerance = Epsilon * abs(x)
    let tolerance2 = 2.0 * tolerance
    if abs(e) > tolerance2:
      r = (x - w) * (fx - fv)
      q = (x - v) * (fx - fw)
      p = (x - v) * q - (x - w) * r
      q = 2.0 * (q - r)
      if q > 0.0: p = -p
      else: q = -q
      r = e
      e = d
    if abs(p) < abs(0.5 * q * r) and p < q * (b - x):
      d = p / q
      let u = x + d
      if u - a < tolerance2 or b - u < tolerance2:
        if x < midpoint: d = tolerance
        else: d = -tolerance
    else:
      if x < midpoint: e = b - x
      else: e = a - x
      d = goldenRatio * e
    var u = d
    if abs(d) < tolerance:
      if d > 0.0: u = tolerance
      else: u = -tolerance
    u += x
    let fu = objectiveValue(u, objectiveId)
    if fu <= fx:
      if u < x: b = x
      else: a = x
      v = w; fv = fw
      w = x; fw = fx
      x = u; fx = fu
    else:
      if u < x: a = u
      else: b = u
      if fu <= fw or x == w:
        v = w; fv = fw
        w = u; fw = fu
      elif fu <= fv or v == x or v == w:
        v = u; fv = fu
    if not (abs(x - midpoint) > tolerance - (b - a) / 2.0): return x
  x
