type I64Input = ptr UncheckedArray[int64]

const Training: array[11, array[4, int64]] = [
  [2'i64, 99, 255, 1], [37, 44, 58, 0], [139, 169, 229, 1],
  [14, 255, 10, 1], [2, 28, 1, 0], [20, 33, 20, 0],
  [252, 227, 65, 1], [71, 65, 24, 0], [168, 80, 80, 1],
  [119, 35, 90, 0], [186, 13, 126, 1]
]

proc brightness*(input: I64Input, length: csize_t): int64 {.cdecl, exportc: "brightness".} =
  if input == nil or length != 3: return -1
  for channel in 0 ..< 3:
    if input[channel] < 0 or input[channel] > 255: return -1

  var bestDistance = 195076'i64
  var bestLabel = -1'i64
  for sample in 0 ..< Training.len:
    let redDelta = input[0] - Training[sample][0]
    let greenDelta = input[1] - Training[sample][1]
    let blueDelta = input[2] - Training[sample][2]
    let distance = redDelta * redDelta + greenDelta * greenDelta + blueDelta * blueDelta
    if distance < bestDistance:
      bestDistance = distance
      bestLabel = Training[sample][3]
  bestLabel
