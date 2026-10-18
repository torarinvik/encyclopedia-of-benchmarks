const U53Max = 9_007_199_254_740_991'i64
const U53Denominator = 9_007_199_254_740_992.0

proc k_means_rust*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "k_means_rust".} =
  if input == nil or length != 10 or input[0] != 4: return -1
  let maxIter = input[1]
  if maxIter < 1 or maxIter > 16: return -1
  let draw0 = input[2]
  let draw1 = input[4]
  if input[3] != 0 or input[5] != 0 or draw0 < 0 or draw0 > U53Max or
      draw1 < 0 or draw1 > U53Max or draw0 == draw1: return -1

  var points: array[4, float64]
  for index in 0 ..< 4:
    let coordinate = input[index + 6]
    if coordinate < -16 or coordinate > 16 or
        (index > 0 and input[index + 5] >= coordinate): return -1
    points[index] = float64(coordinate)
  if input[7] >= 0 or input[8] <= 1: return -1

  var centers = [[float64(draw0) / U53Denominator, 0.0],
                 [float64(draw1) / U53Denominator, 0.0]]
  var labels: array[4, int64]
  for pass in 0 ..< int(maxIter):
    var sums: array[2, array[2, float64]]
    var counts: array[2, int]
    for index in 0 ..< 4:
      let dx0 = points[index] - centers[0][0]
      let dy0 = -centers[0][1]
      let dx1 = points[index] - centers[1][0]
      let dy1 = -centers[1][1]
      let distance0 = dx0 * dx0 + dy0 * dy0
      let distance1 = dx1 * dx1 + dy1 * dy1
      let cluster = if distance1 < distance0: 1 else: 0
      labels[index] = int64(cluster)
      sums[cluster][0] = sums[cluster][0] + points[index]
      sums[cluster][1] = sums[cluster][1] + 0.0
      inc counts[cluster]
    if counts[0] == 0 or counts[1] == 0: return -1
    for cluster in 0 ..< 2:
      centers[cluster][0] = sums[cluster][0] / float64(counts[cluster])
      centers[cluster][1] = sums[cluster][1] / float64(counts[cluster])

  var packed = 0'i64
  for index in 0 ..< 4: packed += labels[index] * (1'i64 shl index)
  packed
