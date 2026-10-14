## Unit-cost Levenshtein distance over two ASCII byte sequences.
proc levenshtein_distance*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "levenshtein_distance".} =
  if length < 2:
    return -1
  let leftLengthValue = values[0]
  let rightLengthValue = values[1]
  if leftLengthValue < 0 or leftLengthValue > 255 or rightLengthValue < 0 or rightLengthValue > 255:
    return -1
  let leftLength = csize_t(leftLengthValue)
  let rightLength = csize_t(rightLengthValue)
  if length != 2 + leftLength + rightLength:
    return -1
  let leftStart = csize_t(2)
  let rightStart = leftStart + leftLength
  for index in 0 ..< leftLength:
    if values[leftStart + index] < 0 or values[leftStart + index] > 127:
      return -1
  for index in 0 ..< rightLength:
    if values[rightStart + index] < 0 or values[rightStart + index] > 127:
      return -1

  var row: array[256, int64]
  for column in 0 .. rightLength:
    row[column] = int64(column)
  for rowIndex in 1 .. leftLength:
    var diagonal = row[0]
    row[0] = int64(rowIndex)
    for column in 1 .. rightLength:
      let above = row[column]
      let deletion = above + 1
      let insertion = row[column - 1] + 1
      let substitution = diagonal + (if values[leftStart + rowIndex - 1] == values[rightStart + column - 1]: 0 else: 1)
      row[column] = min(deletion, min(insertion, substitution))
      diagonal = above
  row[rightLength]
