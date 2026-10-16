proc nagel_schrekenberg*(values: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "nagel_schrekenberg".} =
  if values == nil or length < 5 or values[0] < 2 or values[0] > 32 or values[1] < 0 or values[1] > 16 or values[2] < 0 or values[2] > 5 or int(length) != int(values[0])+3: return -1
  let cells = int(values[0]); let steps = int(values[1]); let vmax = values[2]
  var row: array[32, int64]
  for i in 0 ..< cells:
    if values[i+3] < -1 or values[i+3] > 5: return -1
    row[i] = values[i+3]
  let need = cells*(steps+1)
  if need > int(capacity) or output == nil: return -2
  var pos = 0
  for j in 0 ..< cells: output[pos] = uint8(row[j]+1); inc pos
  for t in 0 ..< steps:
    var next: array[32, int64]
    for i in 0 ..< cells:
      next[i] = -1
      if row[i] != -1:
        var distance = 0
        var j = i+1
        while j < cells and row[j] == -1: inc distance; inc j
        if j == cells:
          j = 0
          while row[j] == -1: inc distance; inc j
        next[i] = min(min(row[i]+1, vmax), int64(distance-1))
    var moved: array[32, int64]
    for i in 0 ..< cells: moved[i] = -1
    for i in 0 ..< cells:
      if next[i] != -1: moved[(i+int(next[i])) mod cells] = next[i]
    row = moved
    for j in 0 ..< cells: output[pos] = uint8(row[j]+1); inc pos
  int64(pos)
