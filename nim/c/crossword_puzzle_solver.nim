type I64Input = ptr UncheckedArray[int64]
type U8Output = ptr UncheckedArray[uint8]

proc search(grid: var array[64, int64], rows, cols: int,
    words: array[8, array[8, int64]], lengths, order: array[8, int],
    depth, wordCount: int): bool =
  if depth == wordCount: return true
  let wordIndex = order[depth]
  let wordLength = lengths[wordIndex]
  for row in 0 ..< rows:
    for col in 0 ..< cols:
      for direction in 0 .. 1:
        let vertical = direction == 0
        if (vertical and row + wordLength > rows) or (not vertical and col + wordLength > cols): continue
        var cells: array[8, int]
        var added: array[8, bool]
        var valid = true
        for i in 0 ..< wordLength:
          cells[i] = if vertical: (row + i) * cols + col else: row * cols + col + i
          if grid[cells[i]] != 0 and grid[cells[i]] != words[wordIndex][i]: valid = false
        if not valid: continue
        for i in 0 ..< wordLength:
          added[i] = grid[cells[i]] == 0
          grid[cells[i]] = words[wordIndex][i]
        if search(grid, rows, cols, words, lengths, order, depth + 1, wordCount): return true
        for i in 0 ..< wordLength:
          if added[i]: grid[cells[i]] = 0
  false

proc crossword_puzzle_solver*(values: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "crossword_puzzle_solver".} =
  if values == nil or length < 3: return -1
  let rowsV = values[0]
  let colsV = values[1]
  let countV = values[2]
  if rowsV < 1 or rowsV > 8 or colsV < 1 or colsV > 8 or countV < 0 or countV > 8: return -1
  let rows = int(rowsV)
  let cols = int(colsV)
  let wordCount = int(countV)
  if length < csize_t(3 + rows * cols): return -1
  var grid: array[64, int64]
  for i in 0 ..< rows * cols:
    let cell = values[3 + i]
    if cell != 0 and cell != -1 and (cell < 65 or cell > 90): return -1
    grid[i] = cell
  var words: array[8, array[8, int64]]
  var lengths, order: array[8, int]
  var position = 3 + rows * cols
  for w in 0 ..< wordCount:
    if csize_t(position) >= length or values[position] < 1 or values[position] > 8: return -1
    lengths[w] = int(values[position])
    inc position
    if csize_t(lengths[w]) > length - csize_t(position): return -1
    for i in 0 ..< lengths[w]:
      let letter = values[position]
      if letter < 65 or letter > 90: return -1
      words[w][i] = letter
      inc position
  if csize_t(position) != length: return -1
  for i in 0 ..< wordCount: order[i] = i
  for i in 1 ..< wordCount:
    let value = order[i]
    var j = i
    while j > 0 and lengths[order[j - 1]] < lengths[value]:
      order[j] = order[j - 1]
      dec j
    order[j] = value
  let solved = search(grid, rows, cols, words, lengths, order, 0, wordCount)
  let required = (1 + rows * cols) * 8
  if output == nil or outputCapacity < csize_t(required): return -2
  for i in 0 .. rows * cols:
    let value = if i == 0: (if solved: 1'i64 else: 0'i64) else: grid[i - 1]
    let bits = cast[uint64](value)
    for byteIndex in 0 ..< 8:
      output[i * 8 + byteIndex] = uint8((bits shr (byteIndex * 8)) and 255)
  int64(required)
