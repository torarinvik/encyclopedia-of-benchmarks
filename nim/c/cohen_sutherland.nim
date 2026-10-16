## Selected coordinate or acceptance flag from Cohen-Sutherland clipping.
proc cohen_sutherland*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "cohen_sutherland".} =
  const invalidResult = -1.0e300
  const scale = 1_000_000.0
  const maxCoordinateMicro = 1_000_000_000'i64
  const inside = 0
  const left = 1
  const right = 2
  const bottom = 4
  const top = 8
  if values == nil or length != 9: return invalidResult
  let selector = values[0]
  if selector < 0 or selector > 4: return invalidResult
  for i in 1 ..< 9:
    if values[i] < -maxCoordinateMicro or values[i] > maxCoordinateMicro: return invalidResult

  let xMin = float64(values[1]) / scale
  let yMin = float64(values[2]) / scale
  let xMax = float64(values[3]) / scale
  let yMax = float64(values[4]) / scale
  if xMin >= xMax or yMin >= yMax: return invalidResult
  var x1 = float64(values[5]) / scale
  var y1 = float64(values[6]) / scale
  var x2 = float64(values[7]) / scale
  var y2 = float64(values[8]) / scale

  template regionCode(x, y: float64): int =
    block:
      var code = inside
      if x < xMin: code = code or left
      elif x > xMax: code = code or right
      if y < yMin: code = code or bottom
      elif y > yMax: code = code or top
      code
  var code1 = regionCode(x1, y1)
  var code2 = regionCode(x2, y2)
  var accepted = false
  while true:
    if code1 == inside and code2 == inside:
      accepted = true
      break
    if (code1 and code2) != 0: break
    let codeOut = if code1 != inside: code1 else: code2
    var x, y: float64
    if (codeOut and top) != 0:
      x = x1 + (x2 - x1) * (yMax - y1) / (y2 - y1)
      y = yMax
    elif (codeOut and bottom) != 0:
      x = x1 + (x2 - x1) * (yMin - y1) / (y2 - y1)
      y = yMin
    elif (codeOut and right) != 0:
      y = y1 + (y2 - y1) * (xMax - x1) / (x2 - x1)
      x = xMax
    else:
      y = y1 + (y2 - y1) * (xMin - x1) / (x2 - x1)
      x = xMin
    if codeOut == code1:
      x1 = x
      y1 = y
      code1 = regionCode(x1, y1)
    else:
      x2 = x
      y2 = y
      code2 = regionCode(x2, y2)
  if selector == 4: return (if accepted: 1.0 else: 0.0)
  if not accepted: return invalidResult
  case selector
  of 0: x1
  of 1: y1
  of 2: x2
  else: y2
