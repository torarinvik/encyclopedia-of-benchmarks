const MaxDimension = 63
const MaxInputValues = 3971
const Int32Minimum = -2_147_483_648'i64
const Int32Maximum = 2_147_483_647'i64

proc writeI32Le(output: var array[8, uint8], offset: int, value: int64) =
  let bits = cast[uint32](int32(value))
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u32)

proc search_in_arow_and_col_wise_sorted_matrix*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "search_in_arow_and_col_wise_sorted_matrix".} =
  if input == nil or length < 2 or length > csize_t(MaxInputValues): return -1
  let nValue = input[0]
  let target = input[1]
  if nValue < 1 or nValue > MaxDimension.int64 or target < Int32Minimum or target > Int32Maximum: return -1
  let n = int(nValue)
  if length != csize_t(2 + n * n): return -1

  var targetCount = 0
  for row in 0 ..< n:
    for column in 0 ..< n:
      let index = row * n + column
      let value = input[2 + index]
      if value < Int32Minimum or value > Int32Maximum: return -1
      if column > 0 and value < input[2 + index - 1]: return -1
      if row > 0 and value < input[2 + index - n]: return -1
      if value == target:
        inc targetCount
        if targetCount > 1: return -1

  var row = 0
  var column = n - 1
  var resultRow = -1'i64
  var resultColumn = -1'i64
  var found = 0'i64
  while row < n and column >= 0:
    let value = input[2 + row * n + column]
    if value == target:
      resultRow = int64(row)
      resultColumn = int64(column)
      found = 1
      break
    if target > value: inc row
    else: dec column

  if output == nil or capacity < 8: return -2
  var buffer: array[8, uint8]
  writeI32Le(buffer, 0, resultRow)
  writeI32Le(buffer, 4, resultColumn)
  for index in 0 ..< 8: output[index] = buffer[index]
  found
