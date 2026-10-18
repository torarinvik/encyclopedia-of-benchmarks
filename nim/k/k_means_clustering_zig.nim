const MaxInputLength = 10
const MaxMoves = 64
const CenterBias = 4097'i64
const CenterBase = 8194'i64

proc k_means_clustering_zig*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "k_means_clustering_zig".} =
  if input == nil or length < 2 or length > MaxInputLength.csize_t: return -1
  if input[0] < 2 or input[0] > 8: return -1
  let pointCount = int(input[0])
  if length != csize_t(pointCount + 1): return -1

  var points: array[8, float32]
  for index in 0 ..< pointCount:
    let coordinate = input[index + 1]
    if coordinate < -16 or coordinate > 16 or (index > 0 and input[index] >= coordinate): return -1
    points[index] = float32(coordinate)

  var centers = [points[0], points[1]]
  var oldCounts: array[2, int]
  for move in 0 ..< MaxMoves:
    var sums: array[2, float32]
    var counts: array[2, int]
    for index in 0 ..< pointCount:
      let firstDelta = points[index] - centers[0]
      let secondDelta = centers[1] - points[index]
      let firstDistance = firstDelta * firstDelta
      let secondDistance = secondDelta * secondDelta
      let cluster = if secondDistance < firstDistance: 1 else: 0
      sums[cluster] = sums[cluster] + points[index]
      inc counts[cluster]
    if counts[0] == 0 or counts[1] == 0: return -1
    let moved = [sums[0] / float32(counts[0]), sums[1] / float32(counts[1])]
    if moved[0] == centers[0] and moved[1] == centers[1] and
        counts[0] == oldCounts[0] and counts[1] == oldCounts[1]:
      let code0 = int64(moved[0] * 256'f32) + CenterBias
      let code1 = int64(moved[1] * 256'f32) + CenterBias
      if code0 < 1 or code0 > 8193 or code1 < 1 or code1 > 8193: return -1
      return (code0 * CenterBase + code1) * 81 + int64(counts[0]) * 9 + int64(counts[1])
    centers = moved
    oldCounts = counts
  return -2
