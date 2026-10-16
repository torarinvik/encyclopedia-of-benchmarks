const MaxTotal = 200
const MaxParts = 200
const MemoSize = (MaxTotal + 1) * MaxParts

proc problem76*(total: int64): int64 {.cdecl, exportc: "problem76".} =
  if total < 1 or total > MaxTotal: return -1
  let bound = int(total)
  var memo: array[MemoSize, int64]
  for n in 0 .. bound: memo[n * MaxParts] = 1
  for n in 0 .. bound:
    for k in 1 ..< bound:
      let index = n * MaxParts + k
      memo[index] += memo[index - 1]
      if n > k: memo[index] += memo[(n - k - 1) * MaxParts + k]
  memo[bound * MaxParts + bound - 1] - 1
