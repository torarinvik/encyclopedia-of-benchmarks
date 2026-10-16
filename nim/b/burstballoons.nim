const MaxBalloons = 128

## Maximum coins from bursting balloons by interval dynamic programming.
proc burstballoons*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "burstballoons".} =
  if length > MaxBalloons: return -1
  for index in 0 ..< int(length):
    if values[index] < 0 or values[index] > 1000: return -1
  if length == 0: return 0

  var padded: array[MaxBalloons + 2, int64]
  var dp: array[MaxBalloons + 2, array[MaxBalloons + 2, int64]]
  padded[0] = 1
  padded[int(length) + 1] = 1
  for index in 0 ..< int(length): padded[index + 1] = values[index]

  for span in 1 .. int(length):
    for left in 1 .. int(length) - span + 1:
      let right = left + span - 1
      var best = 0'i64
      for last in left .. right:
        let coins = dp[left][last - 1] + dp[last + 1][right]
          + padded[left - 1] * padded[last] * padded[right + 1]
        if coins > best: best = coins
      dp[left][right] = best
  dp[1][int(length)]
