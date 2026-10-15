## Bracket-preserving false-position root solve for f(x) = x^2 - x.
proc functionValue(x: float64): float64 = x * x - x

proc falsePosition*(aInput, bInput: float64): float64 {.cdecl, exportc: "false_position".} =
  if aInput != aInput or bInput != bInput or aInput < 0.125 or aInput > 0.875 or
      not ((bInput >= -2.0 and bInput <= -0.125) or (bInput >= 1.125 and bInput <= 3.0)):
    return -1.0
  var a = aInput
  var b = bInput
  var fa = functionValue(a)
  var fb = functionValue(b)
  if not (fa < 0.0 and fb > 0.0):
    return -1.0
  var c = b
  for iteration in 0 ..< 256:
    c = b - fb * (b - a) / (fb - fa)
    let fc = functionValue(c)
    if abs(fc) <= 1e-12:
      return c
    if fc < 0.0:
      a = c
      fa = fc
    else:
      b = c
      fb = fc
  if abs(fa) <= abs(fb): a else: b
