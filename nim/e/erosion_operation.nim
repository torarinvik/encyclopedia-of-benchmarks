proc erosion_operation*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "erosion_operation".} =
  if input == nil or length < 2 or length > 38: return -1
  let height = input[0]
  let width = input[1]
  if height < 1 or height > 6 or width < 1 or width > 6 or length != csize_t(2 + height * width): return -1
  for i in 2..<int(length):
    if input[i] != 0 and input[i] != 1: return -1
  var result = 0'i64
  for row in 0..<int(height):
    for col in 0..<int(width):
      if row == 0 or row + 1 == int(height) or col == 0 or col + 1 == int(width): continue
      let at = 2 + row * int(width) + col
      if input[at] == 1 and input[at - int(width)] == 1 and input[at + int(width)] == 1 and input[at - 1] == 1 and input[at + 1] == 1:
        result = result or (1'i64 shl (row * int(width) + col))
  result
