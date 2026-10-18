const MaxInputLength = 10
const MaxMoves = 256

proc kmeans_rust*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "kmeans_rust".} =
  if input == nil or length < 2 or length > MaxInputLength.csize_t: return -1
  if input[0] < 2 or input[0] > 8: return -1
  let n = int(input[0])
  if length != csize_t(n + 1): return -1

  var points: array[8, float64]
  for index in 0 ..< n:
    let coordinate = input[index + 1]
    if coordinate < -16 or coordinate > 16 or (index > 0 and input[index] >= coordinate): return -1
    points[index] = float64(coordinate)

  var centers = [points[0], points[n div 2]]
  var labels: array[8, int64]
  for index in 0 ..< n:
    let d0 = points[index] - centers[0]
    let d1 = points[index] - centers[1]
    if d1 * d1 < d0 * d0: labels[index] = 1

  for move in 0 ..< MaxMoves:
    var sums: array[2, float64]
    var counts: array[2, int]
    for index in 0 ..< n:
      let cluster = int(labels[index])
      sums[cluster] = sums[cluster] + points[index]
      inc counts[cluster]
    if counts[0] == 0 or counts[1] == 0: return -1
    centers[0] = sums[0] / float64(counts[0])
    centers[1] = sums[1] / float64(counts[1])

    var nextLabels: array[8, int64]
    var unchanged = true
    for index in 0 ..< n:
      let d0 = points[index] - centers[0]
      let d1 = points[index] - centers[1]
      if d1 * d1 < d0 * d0: nextLabels[index] = 1
      if nextLabels[index] != labels[index]: unchanged = false
    if unchanged:
      var packed = 0'i64
      for index in 0 ..< n: packed = packed or (nextLabels[index] shl index)
      return packed
    labels = nextLabels
  return -2
