proc node_neighbors*(values: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "node_neighbors".} =
  if values == nil or length < 2 or values[0] < 0 or values[0] > 64 or values[1] < 0 or values[1] > 63 or int(length) != 2+2*int(values[0]): return -1
  var seen: array[64, bool]
  var result = ""
  for i in 0 ..< int(values[0]):
    let a = values[2+2*i]; let b = values[3+2*i]
    if a < 0 or a > 63 or b < 0 or b > 63: return -1
    let neighbor = if a == values[1]: b elif b == values[1]: a else: -1
    if neighbor >= 0 and not seen[int(neighbor)]:
      seen[int(neighbor)] = true
      if result.len > 0: result.add(',')
      result.add($neighbor)
  if result.len > int(capacity) or (result.len > 0 and output == nil): return -2
  for i in 0 ..< result.len: output[i] = uint8(ord(result[i]))
  int64(result.len)
