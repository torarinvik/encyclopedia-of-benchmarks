const MaxPackedLength = 366
const MaxDraws = 176'i64
const MaxIterations = 22
const InvalidResult = -1'i64

type I64Input = ptr UncheckedArray[int64]

proc scoreI64(x, y: int64): int64 = x * x + y * y

proc simulated_annealing*(packed: I64Input, length: csize_t): int64 {.cdecl, exportc: "simulated_annealing".} =
  if packed == nil or length < 13 or length > csize_t(MaxPackedLength): return InvalidResult
  let x0 = packed[0]
  let y0 = packed[1]
  let step = packed[2]
  let minX = packed[3]
  let maxX = packed[4]
  let minY = packed[5]
  let maxY = packed[6]
  let findMax = packed[7]
  let startRaw = packed[8]
  let rateRaw = packed[9]
  let thresholdRaw = packed[10]
  let selectionCount = packed[11]
  if x0 < -16 or x0 > 16 or y0 < -16 or y0 > 16 or step < 1 or step > 4 or
      minX < -16 or maxX > 16 or minX > maxX or minY < -16 or maxY > 16 or minY > maxY or
      x0 < minX or x0 > maxX or y0 < minY or y0 > maxY or (findMax != 0 and findMax != 1) or
      startRaw < 1000000 or startRaw > 10000000 or rateRaw < 100000 or rateRaw > 500000 or
      thresholdRaw < 1000000 or thresholdRaw > 9999999 or thresholdRaw >= startRaw or
      selectionCount < 0 or selectionCount > MaxDraws or csize_t(selectionCount) > length - 13:
    return InvalidResult

  let selectionN = int(selectionCount)
  let acceptanceCountIndex = 12 + selectionN
  let acceptanceCount = packed[acceptanceCountIndex]
  if acceptanceCount < 0 or acceptanceCount > MaxDraws or length != csize_t(13 + selectionCount + acceptanceCount):
    return InvalidResult
  for i in 0 ..< selectionN:
    if packed[12 + i] < 0 or packed[12 + i] > 7: return InvalidResult
  let acceptanceStart = acceptanceCountIndex + 1
  for i in 0 ..< int(acceptanceCount):
    let draw = packed[acceptanceStart + i]
    if draw != 0 and draw != 999999: return InvalidResult

  var currentTemp = float64(startRaw) / 1_000_000.0
  let rate = float64(rateRaw) / 1_000_000.0
  let threshold = float64(thresholdRaw) / 1_000_000.0
  var currentX = x0
  var currentY = y0
  var bestX = x0
  var bestY = y0
  var bestScore = scoreI64(x0, y0)
  var selectionCursor = 0
  var acceptanceCursor = 0
  var stopped = false

  for _ in 0 ..< MaxIterations:
    let currentScore = scoreI64(currentX, currentY)
    if currentScore > bestScore:
      bestScore = currentScore
      bestX = currentX
      bestY = currentY
    var neighborX = [currentX-step,currentX-step,currentX-step,currentX,currentX,currentX+step,currentX+step,currentX+step]
    var neighborY = [currentY-step,currentY,currentY+step,currentY-step,currentY+step,currentY-step,currentY,currentY+step]
    var remaining = 8
    var found = false
    var nextX, nextY: int64
    while not found and remaining > 0:
      if selectionCursor >= selectionN: return InvalidResult
      let rank = int(packed[12 + selectionCursor])
      inc selectionCursor
      if rank >= remaining: return InvalidResult
      let candidateX = neighborX[rank]
      let candidateY = neighborY[rank]
      let rawChange = scoreI64(candidateX, candidateY) - currentScore
      for i in rank + 1 ..< remaining:
        neighborX[i - 1] = neighborX[i]
        neighborY[i - 1] = neighborY[i]
      dec remaining
      if candidateX < minX or candidateX > maxX or candidateY < minY or candidateY > maxY: continue
      let change = if findMax == 1: rawChange else: -rawChange
      if change > 0:
        found = true
      else:
        if acceptanceCursor >= int(acceptanceCount): return InvalidResult
        let draw = packed[acceptanceStart + acceptanceCursor]
        inc acceptanceCursor
        if change == 0 or draw == 0: found = true
      if found:
        nextX = candidateX
        nextY = candidateY

    currentTemp = currentTemp - currentTemp * rate
    if currentTemp < threshold or not found:
      stopped = true
      break
    currentX = nextX
    currentY = nextY
  if not stopped: return InvalidResult
  (bestX + 16) * 33 + (bestY + 16)
