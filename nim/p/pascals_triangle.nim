proc pascals_triangle*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "pascals_triangle".} =
  if v.isNil or n != 1 or v[0] < 1 or v[0] > 31: return -1
  let rows = int(v[0]); var values: array[31, int64]; values[0] = 1
  for row in 1..<rows:
    values[row] = 1
    var j = row
    while j > 1:
      dec j
      values[j] += values[j - 1]
  var hash = 0'i64
  for i in 0..<rows: hash = (hash * 31 + values[i]) mod 1_000_000_007
  hash
