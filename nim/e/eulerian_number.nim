## Return A(n,k), the number of permutations with exactly k descents.
const MaxN = 20

proc eulerian_number*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "eulerian_number".} =
  if values.isNil or length != 2: return -1
  let n = values[0]
  let target = values[1]
  if n < 0 or n > MaxN or target < 0 or
      (n == 0 and target != 0) or (n > 0 and target >= n): return -1

  var previous: array[21, int64]
  var current: array[21, int64]
  previous[0] = 1
  var row = 1'i64
  while row <= n:
    var k = 0'i64
    while k < row:
      let same = previous[int(k)]
      let fewer = if k == 0: 0'i64 else: previous[int(k - 1)]
      current[int(k)] = (k + 1) * same + (row - k) * fewer
      inc k
    for index in 0 ..< 21:
      previous[index] = current[index]
      current[index] = 0
    inc row
  previous[int(target)]
