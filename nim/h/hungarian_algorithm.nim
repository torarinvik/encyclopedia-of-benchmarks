proc storeI32Le(output: ptr UncheckedArray[uint8], offset: int, value: int32) =
  let bits = cast[uint32](value)
  for b in 0 ..< 4: output[offset + b] = uint8((bits shr (8 * b)) and 0xFF'u32)

proc hungarian_algorithm*(input: ptr UncheckedArray[int32], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "hungarian_algorithm".} =
  if input == nil or length < 2 or length > 67: return -1
  let rows = input[0]; let cols = input[1]
  if rows < 1 or rows > 8 or cols < 1 or cols > 8 or int(length) != 2 + int(rows * cols): return -1
  for k in 0 ..< int(rows * cols):
    if input[2 + k] < 0 or input[2 + k] > 1000: return -1
  let n = int(max(rows, cols))
  var a: array[81, int32]
  var u, v, p, way: array[9, int32]
  for i in 0 ..< int(rows):
    for j in 0 ..< int(cols): a[i * 9 + j] = input[2 + i * int(cols) + j]
  for i in 1 .. n:
    p[0] = int32(i); var j0 = 0
    var minv: array[9, int32]
    var used: array[9, bool]
    for j in 0 .. n: minv[j] = high(int32)
    while true:
      used[j0] = true; let i0 = int(p[j0]); var delta = high(int32); var j1 = 0
      for j in 1 .. n:
        if not used[j]:
          let cur = a[(i0 - 1) * 9 + j - 1] - u[i0] - v[j]
          if cur < minv[j]: minv[j] = cur; way[j] = int32(j0)
          if minv[j] < delta: delta = minv[j]; j1 = j
      for j in 0 .. n:
        if used[j]: u[int(p[j])] += delta; v[j] -= delta
        else: minv[j] -= delta
      j0 = j1
      if p[j0] == 0: break
    while true:
      let j1 = int(way[j0]); p[j0] = p[j1]; j0 = j1
      if j0 == 0: break
  var matched: array[9, int32]
  for i in 0 .. 8: matched[i] = -1
  for j in 1 .. n:
    if p[j] != 0: matched[int(p[j] - 1)] = int32(j - 1)
  var assignments: array[8, int32]
  var total = 0'i32
  for i in 0 ..< int(rows):
    let j = matched[i]
    assignments[i] = if j >= 0 and j < cols: j else: -1
    if assignments[i] >= 0: total += input[2 + i * int(cols) + int(assignments[i])]
  let bytes = 4 * (int(rows) + 1)
  if output == nil or int(capacity) < bytes: return -2
  for i in 0 ..< int(rows): storeI32Le(output, 4 * i, assignments[i])
  storeI32Le(output, 4 * int(rows), total)
  int64(bytes)
