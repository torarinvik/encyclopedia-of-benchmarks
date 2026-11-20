const MaxN = 30
const MaxK = 30
const MaxInputLength = 33
const DpCells = MaxN * MaxN * (MaxK + 1)
const Infinity = 1'i64 shl 60

proc mcsIndex(left, right, piles: int): int {.inline.} =
  (left * MaxN + right) * (MaxK + 1) + piles

proc minimumCostToMergeStones*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "minimum_cost_to_merge_stones".} =
  if input.isNil or length < 3 or length > MaxInputLength: return -1
  if input[0] < 1 or input[0] > MaxN or input[1] < 2 or input[1] > MaxK: return -1
  let n = int(input[0])
  let mergeCount = int(input[1])
  if int(length) != n + 2: return -1

  var prefix: array[MaxN + 1, int64]
  for i in 0..<n:
    let stone = input[i + 2]
    if stone < 1 or stone > 100: return -1
    prefix[i + 1] = prefix[i] + stone
  if (n - 1) mod (mergeCount - 1) != 0: return -1

  var dp: array[DpCells, int64]
  for i in 0..<DpCells: dp[i] = Infinity
  for i in 0..<n: dp[mcsIndex(i, i, 1)] = 0
  for intervalLength in 2..n:
    for left in 0..<(n - intervalLength + 1):
      let right = left + intervalLength - 1
      let maximumPiles = min(mergeCount, intervalLength)
      for piles in 2..maximumPiles:
        var best = Infinity
        for cut in left..<right:
          let first = dp[mcsIndex(left, cut, 1)]
          let rest = dp[mcsIndex(cut + 1, right, piles - 1)]
          if first < Infinity and rest < Infinity and first + rest < best:
            best = first + rest
        dp[mcsIndex(left, right, piles)] = best
      if intervalLength >= mergeCount:
        let toK = dp[mcsIndex(left, right, mergeCount)]
        if toK < Infinity:
          dp[mcsIndex(left, right, 1)] = toK + prefix[right + 1] - prefix[left]
  let answer = dp[mcsIndex(0, n - 1, 1)]
  if answer >= Infinity: -1 else: answer
