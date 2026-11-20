type
  I64Input = ptr UncheckedArray[int64]

proc berry_ravindran_search*(values: I64Input, length: csize_t): int64
    {.cdecl, exportc: "berry_ravindran_search".} =
  if values.isNil or length < 2 or length > 274: return -2
  if values[0] < 0 or values[0] > 256 or values[1] < 1 or values[1] > 16: return -2
  let n = int(values[0])
  let m = int(values[1])
  if length != csize_t(2 + n + m): return -2
  for i in 0 ..< n + m:
    if values[2 + i] < 0 or values[2 + i] > 15: return -2
  if m > n: return -1
  let p = 2 + n
  var shift: array[289, int]
  for i in 0 ..< 289: shift[i] = m + 2
  for first in 0 ..< 17: shift[first * 17 + int(values[p])] = m + 1
  for i in 0 ..< (m - 1): shift[int(values[p + i]) * 17 + int(values[p + i + 1])] = m - i
  for second in 0 ..< 17: shift[int(values[p + m - 1]) * 17 + second] = 1
  var start = 0
  while start <= n - m:
    var i = 0
    while i < m and values[2 + start + i] == values[p + i]: inc i
    if i == m: return int64(start)
    let k = start + m
    if k >= n: break
    let first = int(values[2 + k])
    let second = if k + 1 < n: int(values[2 + k + 1]) else: 16
    start += shift[first * 17 + second]
  -1
