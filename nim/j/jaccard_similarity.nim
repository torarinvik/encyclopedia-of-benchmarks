## Return intersection-over-union similarity for two unique ASCII sets.

proc jaccard_similarity*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "jaccard_similarity".} =
  if values == nil or length < 2: return -1.0e300
  let leftValue = values[0]
  let rightValue = values[1]
  if leftValue < 0 or leftValue > 64 or rightValue < 0 or rightValue > 64 or
      (leftValue == 0 and rightValue == 0): return -1.0e300
  let leftLength = int(leftValue)
  let rightLength = int(rightValue)
  if int(length) != 2 + leftLength + rightLength: return -1.0e300

  for i in 0 ..< leftLength:
    let value = values[2 + i]
    if value < 32 or value > 126: return -1.0e300
    for before in 0 ..< i:
      if values[2 + before] == value: return -1.0e300
  for i in 0 ..< rightLength:
    let value = values[2 + leftLength + i]
    if value < 32 or value > 126: return -1.0e300
    for before in 0 ..< i:
      if values[2 + leftLength + before] == value: return -1.0e300

  var intersection = 0
  for i in 0 ..< leftLength:
    for j in 0 ..< rightLength:
      if values[2 + i] == values[2 + leftLength + j]:
        inc intersection
        break
  let unionLength = leftLength + rightLength - intersection
  float64(intersection) / float64(unionLength)
