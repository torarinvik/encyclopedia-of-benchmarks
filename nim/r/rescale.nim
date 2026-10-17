proc rescale*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "rescale".} =
  if input == nil or length < 3 or length > 260: return -1
  let maxValue = input[0]
  let newMax = input[1]
  let drawCount = input[2]
  if maxValue < 2 or maxValue > 64 or newMax < 1 or newMax > 256: return -1
  if drawCount < 1 or drawCount > 256 or length != csize_t(3 + drawCount): return -1
  for i in 0 ..< int(drawCount):
    if input[3 + i] < 0 or input[3 + i] >= maxValue: return -1

  var cursor = 0
  if newMax == maxValue: return input[3]

  if newMax < maxValue:
    let threshold = maxValue - maxValue mod newMax
    while cursor < int(drawCount):
      let draw = input[3 + cursor]
      inc cursor
      if draw < threshold: return draw mod newMax
    return -1

  var resultValue = 0'i64
  var power = 1'i64
  while power < newMax:
    if cursor >= int(drawCount): return -1
    resultValue += power * input[3 + cursor]
    inc cursor
    power *= maxValue
  if power == newMax: return resultValue

  let threshold = power - power mod newMax
  while resultValue >= threshold:
    resultValue = 0
    power = 1
    while power < newMax:
      if cursor >= int(drawCount): return -1
      resultValue += power * input[3 + cursor]
      inc cursor
      power *= maxValue
  return resultValue mod newMax
