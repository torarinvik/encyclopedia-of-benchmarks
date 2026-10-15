## Count unordered partitions of a positive integer using the pinned 2D DP.
proc integer_partition*(m: int64): int64 {.cdecl, exportc: "integer_partition".} =
  if m < 1 or m > 300: return low(int64)
  var memo: array[90300, int64]
  var i = 0'i64
  while i <= m:
    memo[int(i * 300)] = 1
    inc i
  var n = 0'i64
  while n <= m:
    var k = 1'i64
    while k < m:
      let index = int(n * 300 + k)
      memo[index] += memo[index - 1]
      if n - k > 0:
        memo[index] += memo[int((n - k - 1) * 300 + k)]
      inc k
    inc n
  memo[int(m * 300 + m - 1)]
