proc nearest_neighbour_algorithm*(values: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "nearest_neighbour_algorithm".} =
  if values == nil or length < 2 or length > 257 or values[0] < 1 or values[0] > 16: return -1
  let n = int(values[0])
  if int(length) != 1 + n*n: return -1
  for i in 1 ..< int(length):
    if values[i] < 0 or values[i] > 1000000: return -1
  var seen: array[16, bool]
  var path: array[16, int]
  var current = 0
  for step in 0 ..< n:
    path[step] = current
    seen[current] = true
    if step + 1 < n:
      var best = n
      var distance = 0'i64
      for j in 0 ..< n:
        if not seen[j]:
          let d = values[1 + current*n + j]
          if best == n or d < distance: best = j; distance = d
      current = best
  var result = ""
  for i in 0 ..< n:
    if i > 0: result.add(',')
    result.add($path[i])
  if result.len > int(capacity) or (result.len > 0 and output == nil): return -2
  for i in 0 ..< result.len: output[i] = uint8(ord(result[i]))
  int64(result.len)
