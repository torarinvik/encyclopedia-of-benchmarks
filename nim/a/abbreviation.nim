## Check whether lowercase source letters can be capitalized or deleted.
proc abbreviation*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "abbreviation".} =
  if length < 2 or length > 258:
    return -1
  let sourceLength = values[0]
  let targetLength = values[1]
  if sourceLength < 0 or sourceLength > 128 or targetLength < 0 or targetLength > 128:
    return -1
  if length != csize_t(2 + sourceLength + targetLength):
    return -1
  for index in 0 ..< csize_t(sourceLength):
    let value = values[2 + index]
    if not ((value >= 65 and value <= 90) or (value >= 97 and value <= 122)):
      return -1
  for index in 0 ..< csize_t(targetLength):
    let value = values[2 + csize_t(sourceLength) + index]
    if value < 65 or value > 90:
      return -1

  var current: array[129, bool]
  var next: array[129, bool]
  current[0] = true
  for sourceIndex in 0 ..< csize_t(sourceLength):
    for targetIndex in 0 .. csize_t(targetLength):
      next[targetIndex] = false
    let source = values[2 + sourceIndex]
    let uppercase = if source >= 97 and source <= 122: source - 32 else: source
    for targetIndex in 0 .. csize_t(targetLength):
      if not current[targetIndex]:
        continue
      if source >= 97 and source <= 122:
        next[targetIndex] = true
      if targetIndex < csize_t(targetLength) and
          uppercase == values[2 + csize_t(sourceLength) + targetIndex]:
        next[targetIndex + 1] = true
    for targetIndex in 0 .. csize_t(targetLength):
      current[targetIndex] = next[targetIndex]
  if current[csize_t(targetLength)]: 1'i64 else: 0'i64
