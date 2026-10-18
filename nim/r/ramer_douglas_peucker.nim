import math

const MaxPoints = 12
const MaxOutput = 25

proc ramer_douglas_peucker*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64 {.cdecl, exportc: "ramer_douglas_peucker".} =
  if input == nil or inputLength < 2 or inputLength > 26: return -1
  if input[0] != input[0] or input[0] < 0 or input[0] > 12 or input[0] != floor(input[0]): return -1
  let n = int(input[0])
  let epsilon = input[1]
  if inputLength != csize_t(2 + 2 * n) or epsilon != epsilon or epsilon < 0 or epsilon > 100: return -1
  var xs, ys: array[MaxPoints, float64]
  for i in 0 ..< n:
    xs[i] = input[2 + 2 * i]
    ys[i] = input[3 + 2 * i]
    if xs[i] != xs[i] or ys[i] != ys[i] or abs(xs[i]) > 100 or abs(ys[i]) > 100: return -1
  if n >= 3:
    for i in 0 ..< n:
      for j in i + 1 ..< n:
        if xs[i] == xs[j] and ys[i] == ys[j]: return -1
        let dx = xs[j] - xs[i]
        let dy = ys[j] - ys[i]
        let lengthSquared = dx * dx + dy * dy
        let lineLength = sqrt(lengthSquared)
        if lengthSquared != lengthSquared or lengthSquared <= 0 or lineLength != lineLength or lineLength <= 0: return -1
        var maxClamped = 0.0
        var maxLine = 0.0
        var indexClamped = i
        var indexLine = i
        for k in i + 1 ..< j:
          let px = xs[k]
          let py = ys[k]
          let t = ((px - xs[i]) * dx + (py - ys[i]) * dy) / lengthSquared
          if t < 0 or t > 1: return -1
          let nearestX = xs[i] + t * dx
          let nearestY = ys[i] + t * dy
          let clampedDistance = hypot(px - nearestX, py - nearestY)
          let numerator = dy * px - dx * py + xs[j] * ys[i] - ys[j] * xs[i]
          let lineDistance = abs(numerator) / lineLength
          if clampedDistance != clampedDistance or lineDistance != lineDistance: return -1
          if clampedDistance > maxClamped:
            maxClamped = clampedDistance
            indexClamped = k
          if lineDistance > maxLine:
            maxLine = lineDistance
            indexLine = k
        if indexClamped != indexLine or ((maxClamped > epsilon) != (maxLine > epsilon)): return -1
  var keep: array[MaxPoints, bool]
  if n > 0: keep[0] = true
  if n > 1: keep[n - 1] = true
  if n >= 3:
    var starts, finishes: array[24, int]
    var top = 1
    starts[0] = 0
    finishes[0] = n - 1
    while top > 0:
      dec top
      let start = starts[top]
      let finish = finishes[top]
      let dx = xs[finish] - xs[start]
      let dy = ys[finish] - ys[start]
      let lengthSquared = dx * dx + dy * dy
      var maxDistance = 0.0
      var maxIndex = start
      for k in start + 1 ..< finish:
        let t = ((xs[k] - xs[start]) * dx + (ys[k] - ys[start]) * dy) / lengthSquared
        let nearestX = xs[start] + t * dx
        let nearestY = ys[start] + t * dy
        let distance = hypot(xs[k] - nearestX, ys[k] - nearestY)
        if distance > maxDistance:
          maxDistance = distance
          maxIndex = k
      if maxDistance > epsilon:
        keep[maxIndex] = true
        starts[top] = start
        finishes[top] = maxIndex
        inc top
        starts[top] = maxIndex
        finishes[top] = finish
        inc top
  var staged: array[MaxOutput, float64]
  var resultCount = 0
  for i in 0 ..< n:
    if keep[i]:
      staged[1 + 2 * resultCount] = xs[i]
      staged[2 + 2 * resultCount] = ys[i]
      inc resultCount
  staged[0] = float64(resultCount)
  let outputSize = 1 + 2 * resultCount
  if output == nil or capacity < csize_t(outputSize): return -2
  for i in 0 ..< outputSize: output[i] = staged[i]
  int64(outputSize)
