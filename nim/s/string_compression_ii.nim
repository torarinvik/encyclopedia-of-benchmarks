const MaxN = 12
const MaxInput = 15
const Width = MaxN + 1
const Cells = Width * Width
const Infinity = 1000'i64

proc runCost(kept: int): int64 =
  if kept == 1: return 1
  var value = kept
  var digits = 0
  while value > 0:
    inc digits
    value = value div 10
  int64(1 + digits)

proc string_compression_ii*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "string_compression_ii".} =
  if input == nil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let rawN = input[0]
  let rawK = input[1]
  if rawN < 0 or rawN > MaxN or rawK < 0 or rawK > rawN: return -1
  let n = int(rawN)
  let budget = int(rawK)
  if int(length) != n + 2: return -1
  for i in 0..<n:
    if input[i + 2] < 0 or input[i + 2] > 25: return -1

  var dp: array[Cells, int64]
  for i in 0..<Cells: dp[i] = Infinity
  dp[0] = 0
  for start in 0..<n:
    for used in 0..budget:
      let prefixCost = dp[start * Width + used]
      if prefixCost == Infinity: continue
      if used < budget:
        let index = (start + 1) * Width + used + 1
        if prefixCost < dp[index]: dp[index] = prefixCost
      var same = 0
      for ending in start..<n:
        if input[ending + 2] == input[start + 2]: inc same
        let span = ending - start + 1
        for kept in 1..same:
          let deleted = used + span - kept
          if deleted > budget: continue
          let candidate = prefixCost + runCost(kept)
          let index = (ending + 1) * Width + deleted
          if candidate < dp[index]: dp[index] = candidate
  var answer = Infinity
  for deleted in 0..budget:
    answer = min(answer, dp[n * Width + deleted])
  answer
