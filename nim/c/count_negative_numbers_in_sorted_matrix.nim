proc count_negative_numbers_in_sorted_matrix*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "count_negative_numbers_in_sorted_matrix".} =
  if input.isNil or length < 3 or length > 514: return -1
  let rows_value = input[0]
  let columns_value = input[1]
  if rows_value < 1 or rows_value > 512 or columns_value < 1 or columns_value > 512: return -1
  let rows = int(rows_value)
  let columns = int(columns_value)
  if rows * columns > 512 or length != csize_t(2 + rows * columns): return -1

  var nonnegative = 0
  var bound = columns
  for row in 0 ..< rows:
    var left = 0
    var right = bound
    while left < right:
      let middle = left + (right - left) div 2
      let value = input[2 + row * columns + middle]
      if value >= 0: left = middle + 1
      else: right = middle
    bound = left
    nonnegative += bound
  return int64(rows * columns - nonnegative)
