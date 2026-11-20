proc entringer_number*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "entringer_number".} =
  if values == nil or length != 2: return -1
  let n = values[0]
  let target = values[1]
  if n < 0 or n > 12 or target < 0 or target > n: return -1
  var previous: array[13, int64]
  var current: array[13, int64]
  previous[0] = 1
  var row = 1'i64
  while row <= n:
    current[0] = 0
    var col = 1'i64
    while col <= row:
      current[int(col)] = current[int(col - 1)] + previous[int(row - col)]
      inc col
    for i in 0 ..< 13:
      previous[i] = current[i]
      current[i] = 0
    inc row
  previous[int(target)]
