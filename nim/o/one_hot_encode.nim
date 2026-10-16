proc one_hot_encode*(values: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "one_hot_encode".} =
  if values == nil or length < 2 or length > 33 or values[0] < 1 or values[0] > 32: return -1
  let rows = int(values[0])
  if int(length) != rows + 1: return -1
  var present: array[26,bool]
  for i in 0 ..< rows:
    if values[i+1] < 0 or values[i+1] > 25: return -1
    present[int(values[i+1])] = true
  var map: array[26,int]
  var cols = 0
  for i in 0 ..< 26:
    if present[i]: map[i] = cols; inc cols
  let needed = rows * cols
  if needed > int(capacity) or (needed > 0 and output == nil): return -2
  for r in 0 ..< rows:
    for c in 0 ..< cols:
      output[r*cols+c] = uint8(ord(map[int(values[r+1])] == c))
  int64(needed)
