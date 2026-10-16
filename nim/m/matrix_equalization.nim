## Minimum updates needed to equalize a vector with a fixed step size.
proc matrix_equalization*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "matrix_equalization".} =
  const maxVectorLength = 64
  const maxInputLength = 66
  if input == nil or length < 2 or length > csize_t(maxInputLength):
    return -1
  let vectorLength = int(length) - 1
  if vectorLength > maxVectorLength or input[0] < 1 or input[0] > int64(vectorLength):
    return -1
  let stepSize = int(input[0])
  var minimumUpdates = vectorLength

  for targetIndex in 0 ..< vectorLength:
    var seen = false
    for previous in 0 ..< targetIndex:
      if input[previous + 1] == input[targetIndex + 1]:
        seen = true
        break
    if seen:
      continue

    var updates = 0
    var index = 0
    while index < vectorLength:
      if input[index + 1] == input[targetIndex + 1]:
        inc index
      else:
        inc updates
        index += stepSize
    if updates < minimumUpdates:
      minimumUpdates = updates
  return int64(minimumUpdates)
