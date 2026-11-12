const MaxRows = 16
const MaxColumns = 16

proc solve(input: ptr UncheckedArray[int64], length: int): int64 =
  if input.isNil or length < 2 or length > 259: return -1
  if input[0] < 1 or input[0] > int64(MaxRows) or
      input[1] < 1 or input[1] > int64(MaxColumns): return -1
  let rows = int(input[0])
  let columns = int(input[1])
  if length != 2 + rows * columns: return -1
  for index in 2 ..< length:
    if input[index] != 0 and input[index] != 1: return -1

  var lastOne: array[MaxColumns, int64]
  var left: array[MaxColumns, int]
  var right: array[MaxColumns, int]
  var stack: array[MaxColumns, int]
  for column in 0 ..< columns: lastOne[column] = -1
  var best = 0'i64
  for row in 0 ..< rows:
    for column in 0 ..< columns:
      if input[2 + row * columns + column] == 1: lastOne[column] = int64(row)
    var top = 0
    for column in 0 ..< columns:
      while top > 0 and lastOne[stack[top - 1]] <= lastOne[column]: dec top
      left[column] = if top == 0: -1 else: stack[top - 1]
      stack[top] = column
      inc top
    top = 0
    for cursor in countdown(columns - 1, 0):
      while top > 0 and lastOne[stack[top - 1]] <= lastOne[cursor]: dec top
      right[cursor] = if top == 0: columns else: stack[top - 1]
      stack[top] = cursor
      inc top
    for column in 0 ..< columns:
      let height = int64(row) - lastOne[column]
      let width = int64(right[column] - left[column] - 1)
      best = max(best, height * width)
  best

proc largest_zero_submatrix*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "largest_zero_submatrix".} =
  if input.isNil or length < csize_t(2) or length > csize_t(259): return -1
  solve(input, int(length))
