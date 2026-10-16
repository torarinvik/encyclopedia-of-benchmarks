type I64Input = ptr UncheckedArray[int64]
type U8Output = ptr UncheckedArray[uint8]

proc search(grid: var array[64, int64], rows, cols: int,
    words: array[8, array[8, int64]], lengths: array[8, int],
    remaining: var array[8, int], remainingCount: int): bool =
  var start = 0
  while start < rows * cols and grid[start] != 0: inc start
  if start == rows * cols: return true
  let row = start div cols
  let col = start mod cols
  var current = remaining
  var currentCount = remainingCount
  for choice in 0 ..< remainingCount:
    let wordIndex = remaining[choice]
    let wordLength = lengths[wordIndex]
    for direction in 0 .. 1:
      let vertical = direction == 0
      if (vertical and row + wordLength > rows) or (not vertical and col + wordLength > cols): continue
      var valid = true
      for i in 0 ..< wordLength:
        let cell = if vertical: (row + i) * cols + col else: row * cols + col + i
        if grid[cell] != 0: valid = false
      if not valid: continue
      for i in 0 ..< wordLength:
        let cell = if vertical: (row + i) * cols + col else: row * cols + col + i
        grid[cell] = words[wordIndex][i]
      var next: array[8, int]
      var nextCount = 0
      var removeAt = 0
      for i in 0 ..< currentCount:
        if current[i] == wordIndex: removeAt = i
        else:
          next[nextCount] = current[i]
          inc nextCount
      for i in removeAt + 1 ..< currentCount: current[i - 1] = current[i]
      dec currentCount
      if search(grid, rows, cols, words, lengths, next, nextCount): return true
      current[currentCount] = wordIndex
      inc currentCount
      for i in 0 ..< wordLength:
        let cell = if vertical: (row + i) * cols + col else: row * cols + col + i
        grid[cell] = 0
  return false

proc crossword_solver*(values: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "crossword_solver".} =
  if values == nil or length < 3: return -1
  let rowsV = values[0]
  let colsV = values[1]
  let countV = values[2]
  if rowsV < 1 or rowsV > 8 or colsV < 1 or colsV > 8 or countV < 0 or countV > 8: return -1
  let rows = int(rowsV)
  let cols = int(colsV)
  let count = int(countV)
  if length < csize_t(3 + rows * cols): return -1
  var grid: array[64, int64]
  for i in 0 ..< rows * cols:
    let v = values[3 + i]
    if v != 0 and v != -1 and (v < 65 or v > 90): return -1
    grid[i] = v
  var words: array[8, array[8, int64]]
  var lengths: array[8, int]
  var pos = 3 + rows * cols
  for w in 0 ..< count:
    if csize_t(pos) >= length or values[pos] < 1 or values[pos] > 8: return -1
    lengths[w] = int(values[pos])
    inc pos
    if csize_t(lengths[w]) > length - csize_t(pos): return -1
    for i in 0 ..< lengths[w]:
      let v = values[pos]
      if v < 65 or v > 90: return -1
      words[w][i] = v
      inc pos
    for prior in 0 ..< w:
      if lengths[prior] == lengths[w]:
        var same = true
        for i in 0 ..< lengths[w]:
          if words[prior][i] != words[w][i]: same = false
        if same: return -1
  if csize_t(pos) != length: return -1
  var remaining: array[8, int]
  for i in 0 ..< count: remaining[i] = i
  let solved = search(grid, rows, cols, words, lengths, remaining, count)
  let required = (1 + rows * cols) * 8
  if output == nil or outputCapacity < csize_t(required): return -2
  for i in 0 .. rows * cols:
    let value = if i == 0: (if solved: 1'i64 else: 0'i64) else: grid[i - 1]
    let bits = cast[uint64](value)
    for byteIndex in 0 ..< 8:
      output[i * 8 + byteIndex] = uint8((bits shr (byteIndex * 8)) and 255)
  int64(required)
