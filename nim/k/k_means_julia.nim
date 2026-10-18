const MaxInputLength = 10
const MaxMoves = 64
const CenterScale = 256.0
const CenterBias = 4097'i64
const CenterBase = 8194'i64

proc k_means_julia*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "k_means_julia".} =
  if input == nil or length < 2 or length > MaxInputLength.csize_t: return -1
  if input[0] < 3 or input[0] > 8: return -1
  let n = int(input[0])
  if length != csize_t(n + 1): return -1

  var points: array[8, float64]
  for index in 0 ..< n:
    let coordinate = input[index + 1]
    if coordinate < -16 or coordinate > 16 or (index > 0 and input[index] >= coordinate): return -1
    points[index] = float64(coordinate)

  var centers = [points[0], points[n div 2]]
  for move in 0 ..< MaxMoves:
    var sums: array[2, float64]
    var counts: array[2, int]
    for index in 0 ..< n:
      let d0 = points[index] - centers[0]
      let d1 = points[index] - centers[1]
      let cluster = if d1 * d1 < d0 * d0: 1 else: 0
      sums[cluster] = sums[cluster] + points[index]
      inc counts[cluster]
    if counts[0] == 0 or counts[1] == 0: return -1
    let moved = [sums[0] / float64(counts[0]), sums[1] / float64(counts[1])]
    if moved[0] == centers[0] and moved[1] == centers[1]:
      let code0 = int64(moved[0] * CenterScale) + CenterBias
      let code1 = int64(moved[1] * CenterScale) + CenterBias
      if code0 < 1 or code0 > 8193 or code1 < 1 or code1 > 8193: return -1
      return code0 * CenterBase + code1
    centers = moved
  return -2
