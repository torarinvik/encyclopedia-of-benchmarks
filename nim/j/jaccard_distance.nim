## Return one minus character-set Jaccard similarity for two ASCII strings.

proc jaccard_distance*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "jaccard_distance".} =
  if values == nil or length < 2: return -1.0e300
  let leftValue = values[0]
  let rightValue = values[1]
  if leftValue < 0 or leftValue > 64 or rightValue < 0 or rightValue > 64: return -1.0e300
  let leftLength = int(leftValue)
  let rightLength = int(rightValue)
  if int(length) != 2 + leftLength + rightLength: return -1.0e300
  for i in 0 ..< leftLength:
    if values[2 + i] < 32 or values[2 + i] > 126: return -1.0e300
  for j in 0 ..< rightLength:
    if values[2 + leftLength + j] < 32 or values[2 + leftLength + j] > 126: return -1.0e300

  var intersection = 0
  var unionLength = 0
  for i in 0 ..< leftLength:
    var seenBefore = false
    for k in 0 ..< i:
      if values[2 + k] == values[2 + i]:
        seenBefore = true
        break
    if not seenBefore:
      inc unionLength
      for j in 0 ..< rightLength:
        if values[2 + i] == values[2 + leftLength + j]:
          inc intersection
          break
  for j in 0 ..< rightLength:
    var seenBefore = false
    for k in 0 ..< j:
      if values[2 + leftLength + k] == values[2 + leftLength + j]:
        seenBefore = true
        break
    if not seenBefore:
      var inLeft = false
      for i in 0 ..< leftLength:
        if values[2 + i] == values[2 + leftLength + j]:
          inLeft = true
          break
      if not inLeft: inc unionLength
  if unionLength == 0: return 0.0
  1.0 - float64(intersection) / float64(unionLength)
