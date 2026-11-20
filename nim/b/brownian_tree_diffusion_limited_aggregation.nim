const
  Side = 33
  MaxAttempts = 16
  MaxSteps = 512
  MaxPoints = 17
  Golden = 0x9e3779b97f4a7c15'u64
  Multiplier = 0x2545f4914f6cdd1d'u64

proc nextWord(state: var uint64): uint64 =
  state = state xor (state shr 12)
  state = state xor (state shl 25)
  state = state xor (state shr 27)
  state * Multiplier

proc touches(occupied: openArray[uint8], x, y: int): bool =
  occupied[y * Side + x - 1] != 0 or occupied[(y - 1) * Side + x] != 0 or
    occupied[y * Side + x + 1] != 0 or occupied[(y + 1) * Side + x] != 0

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc brownian_tree_diffusion_limited_aggregation*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "brownian_tree_diffusion_limited_aggregation".} =
  if input.isNil or length != 3: return -1
  let attemptsValue = input[0]
  let seedValue = input[1]
  let stepsValue = input[2]
  if attemptsValue < 0 or attemptsValue > MaxAttempts or seedValue < 1 or
      stepsValue < 1 or stepsValue > MaxSteps: return -1

  var occupied: array[Side * Side, uint8]
  var pointX: array[MaxPoints, int32]
  var pointY: array[MaxPoints, int32]
  pointX[0] = 16
  pointY[0] = 16
  var pointCount = 1
  occupied[16 * Side + 16] = 1

  for attempt in 0 ..< int(attemptsValue):
    var state = uint64(seedValue) xor (Golden * uint64(attempt + 1))
    if state == 0: state = Multiplier
    let sideDraw = nextWord(state)
    let positionDraw = nextWord(state)
    let launchSide = int(sideDraw mod 4'u64)
    let position = 1 + int(positionDraw mod 31'u64)
    var x, y: int
    if launchSide == 0: x = position; y = 1
    elif launchSide == 1: x = 31; y = position
    elif launchSide == 2: x = position; y = 31
    else: x = 1; y = position

    var at = y * Side + x
    if occupied[at] != 0: continue
    if touches(occupied, x, y):
      occupied[at] = 1
      pointX[pointCount] = int32(x)
      pointY[pointCount] = int32(y)
      inc pointCount
      continue
    for _ in 0 ..< int(stepsValue):
      let direction = int(nextWord(state) mod 4'u64)
      if direction == 0: dec x
      elif direction == 1: dec y
      elif direction == 2: inc x
      else: inc y
      if x == 0 or x == 32 or y == 0 or y == 32: break
      at = y * Side + x
      if touches(occupied, x, y):
        occupied[at] = 1
        pointX[pointCount] = int32(x)
        pointY[pointCount] = int32(y)
        inc pointCount
        break

  let required = (1 + 2 * pointCount) * 8
  if output.isNil or capacity < csize_t(required): return -2
  storeI64Le(output, 0, int64(pointCount))
  for point in 0 ..< pointCount:
    storeI64Le(output, (1 + 2 * point) * 8, int64(pointX[point]))
    storeI64Le(output, (2 + 2 * point) * 8, int64(pointY[point]))
  int64(required)
