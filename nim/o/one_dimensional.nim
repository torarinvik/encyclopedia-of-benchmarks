proc one_dimensional*(values: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "one_dimensional".} =
  if values == nil or length != 1: return -1
  let code = values[0]
  if code < 0 or code > 11111111: return -1
  var digits: array[8, uint8]
  var rules: array[8, uint8]
  var x = code
  var count = 0
  while true:
    let d = x mod 10
    if d > 1: return -1
    digits[count] = uint8(d)
    inc count
    x = x div 10
    if x == 0: break
    if count == 8: return -1
  for i in 0 ..< count: rules[8-count+i] = digits[count-1-i]
  var cells: array[17, array[31, uint8]]
  cells[0][15] = 1
  for r in 0 ..< 16:
    for c in 0 ..< 31:
      let left = if c > 0: int(cells[r][c-1]) else: 0
      let center = int(cells[r][c])
      let right = if c < 30: int(cells[r][c+1]) else: 0
      cells[r+1][c] = rules[7-((left shl 2) or (center shl 1) or right)]
  if capacity < 1581 or output == nil: return -2
  var pos = 0
  for row in cells:
    for cell in row:
      let color = if cell == 1: 0'u8 else: 255'u8
      output[pos] = color; output[pos+1] = color; output[pos+2] = color
      pos += 3
  int64(pos)
