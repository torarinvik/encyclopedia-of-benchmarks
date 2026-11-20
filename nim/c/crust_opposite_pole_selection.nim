const MaxSamples = 8
const MaxCellVertices = 8

proc putI64(output: ptr UncheckedArray[uint8], word: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0..<8: output[word * 8 + b] = uint8((bits shr (b * 8)) and 255'u64)

proc samePoint(a, b: array[3, int64]): bool = a[0] == b[0] and a[1] == b[1] and a[2] == b[2]

proc crust_opposite_pole_selection*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "crust_opposite_pole_selection".} =
  if input == nil or length < 1 or length > 226: return -1
  let n0 = input[0]
  if n0 < 1 or n0 > 8: return -1
  let n = int(n0)
  var samples: array[MaxSamples, array[3, int64]]
  var answer: array[MaxSamples, array[2, int64]]
  var offset = 1
  for row in 0..<n:
    if offset + 4 > int(length): return -1
    let sample = [input[offset], input[offset + 1], input[offset + 2]]
    let count0 = input[offset + 3]
    offset += 4
    if count0 < 1 or count0 > 8: return -1
    for axis in 0..<3:
      if sample[axis] < -16 or sample[axis] > 16: return -1
    for previous in 0..<row:
      if samePoint(sample, samples[previous]): return -1
    samples[row] = sample
    let count = int(count0)
    if offset + 3 * count > int(length): return -1
    var cell: array[MaxCellVertices, array[3, int64]]
    for vertex in 0..<count:
      for axis in 0..<3:
        cell[vertex][axis] = input[offset]
        inc offset
        if cell[vertex][axis] < -16 or cell[vertex][axis] > 16: return -1
      if samePoint(cell[vertex], sample): return -1
      for previous in 0..<vertex:
        if samePoint(cell[vertex], cell[previous]): return -1

    var positive = 0
    var positiveDistance = -1'i64
    for vertex in 0..<count:
      var distance = 0'i64
      for axis in 0..<3:
        let delta = cell[vertex][axis] - sample[axis]
        distance += delta * delta
      if distance > positiveDistance:
        positiveDistance = distance
        positive = vertex
    var forward: array[3, int64]
    for axis in 0..<3: forward[axis] = cell[positive][axis] - sample[axis]
    var negative = -1'i64
    var negativeDistance = -1'i64
    for vertex in 0..<count:
      var distance = 0'i64
      var projection = 0'i64
      for axis in 0..<3:
        let delta = cell[vertex][axis] - sample[axis]
        distance += delta * delta
        projection += delta * forward[axis]
      if projection < 0 and distance > negativeDistance:
        negativeDistance = distance
        negative = int64(vertex)
    answer[row] = [int64(positive), negative]
  if offset != int(length): return -1
  let bytes = 8 * (1 + 2 * n)
  if output == nil or capacity < csize_t(bytes): return -2
  putI64(output, 0, n0)
  var word = 1
  for row in 0..<n:
    putI64(output, word, answer[row][0]); inc word
    putI64(output, word, answer[row][1]); inc word
  int64(bytes)
