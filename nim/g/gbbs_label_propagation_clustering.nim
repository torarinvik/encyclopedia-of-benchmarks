# Clean-room bounded GBBS label-propagation profile; see package LICENSE.txt.
const MaxN = 16
const MaxM = 64
const MaxInput = 130

proc storeI64LE(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc gbbs_label_propagation_clustering*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "gbbs_label_propagation_clustering".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 1 or n64 > int64(MaxN) or m64 < 0 or m64 > int64(MaxM): return -1
  let n = int(n64)
  let m = int(m64)
  if int(length) != 2 + 2 * m: return -1
  var adjacent: array[MaxN, array[MaxN, bool]]
  for edge in 0..<m:
    let u64 = input[2 + 2 * edge]
    let v64 = input[3 + 2 * edge]
    if u64 < 0 or v64 <= u64 or v64 >= n64: return -1
    let u = int(u64)
    let v = int(v64)
    if adjacent[u][v]: return -1
    adjacent[u][v] = true
    adjacent[v][u] = true
  let outputBytes = 8 * n
  if output.isNil or capacity < csize_t(outputBytes): return -2

  var labels: array[MaxN, int64]
  for vertex in 0..<n: labels[vertex] = int64(vertex)
  for u in 0..<n:
    var frequency: array[MaxN, int]
    var degree = 0
    for v in 0..<n:
      if adjacent[u][v]:
        inc frequency[int(labels[v])]
        inc degree
    if degree == 0: continue
    var bestLabel = 0
    var bestFrequency = 0
    for label in 0..<n:
      if frequency[label] > bestFrequency or
          (frequency[label] == bestFrequency and frequency[label] > 0 and label > bestLabel):
        bestLabel = label
        bestFrequency = frequency[label]
    labels[u] = int64(bestLabel)
  for vertex in 0..<n: storeI64LE(output, 8 * vertex, labels[vertex])
  return int64(outputBytes)
