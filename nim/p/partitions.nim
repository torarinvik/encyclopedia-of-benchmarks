const MaxN = 100
const Stride = 101
proc countParts(n, k: int, memo: var array[Stride * Stride, int64]): int64 =
  if (n == 0 and k == 0) or (n > 0 and k == 1) or n == k: return 1
  if k == 0 or k > n: return 0
  let index = n * Stride + k
  if memo[index] >= 0: return memo[index]
  memo[index] = countParts(n - 1, k - 1, memo) + countParts(n - k, k, memo)
  memo[index]
proc partitions*(n: int64): int64 {.cdecl, exportc: "partitions".} =
  if n < 0 or n > MaxN: return low(int64)
  var memo: array[Stride * Stride, int64]
  for cell in memo.mitems: cell = -1
  var total = 0'i64
  for k in 1..int(n): total += countParts(int(n), k, memo)
  if n == 0: return 1
  total
