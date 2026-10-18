const MaxInputLength = 18
const MaxMoves = 64
const CenterScale = 256.0
const CenterBias = 4097'i64
const CenterBase = 8194'i64

proc k_means_clustering_c*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "k_means_clustering_c".} =
  if input == nil or length < 1 or length > MaxInputLength.csize_t: return -1
  if input[0] < 3 or input[0] > 8: return -1
  let n = int(input[0])
  if length != csize_t(1 + 2 * n): return -1

  var labels: array[8, int64]
  var hasZero = false
  var hasOne = false
  for index in 0 ..< n:
    let label = input[index + 1]
    let coordinate = input[1 + n + index]
    if label != 0 and label != 1: return -1
    labels[index] = label
    if label == 0: hasZero = true
    if label == 1: hasOne = true
    if coordinate < -16 or coordinate > 16 or
        (index > 0 and input[n + index] >= coordinate): return -1
  if not hasZero or not hasOne: return -1

  for move in 0 ..< MaxMoves:
    var sums: array[2, float64]
    var counts: array[2, int]
    for index in 0 ..< n:
      let cluster = int(labels[index])
      sums[cluster] = sums[cluster] + float64(input[1 + n + index])
      inc counts[cluster]
    if counts[0] == 0 or counts[1] == 0: return -1
    let centers = [sums[0] / float64(counts[0]), sums[1] / float64(counts[1])]

    var nextLabels: array[8, int64]
    var changed = 0
    for index in 0 ..< n:
      let point = float64(input[1 + n + index])
      let d0 = point - centers[0]
      let d1 = point - centers[1]
      if d1 * d1 < d0 * d0: nextLabels[index] = 1
      if nextLabels[index] != labels[index]: inc changed
    labels = nextLabels
    if changed == 0:
      let code0 = int64(centers[0] * CenterScale) + CenterBias
      let code1 = int64(centers[1] * CenterScale) + CenterBias
      if code0 < 1 or code0 > 8193 or code1 < 1 or code1 > 8193: return -1
      return code0 * CenterBase + code1
  return -2
