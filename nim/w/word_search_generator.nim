const
  MaxDimension = 32
  MaxCells = MaxDimension * MaxDimension
  MaxWords = 96
  MaxWordLength = 32
  MaxInputValues = 4096
  RngModulus = 2_147_483_647'u64

proc nextRandom(state: var uint64): uint64 =
  state = (state * 48_271'u64) mod RngModulus
  state

proc shuffle(items: var array[MaxDimension, int], count: int, state: var uint64) =
  var remaining = count
  while remaining > 1:
    let other = int(nextRandom(state) mod uint64(remaining))
    swap(items[remaining - 1], items[other])
    dec remaining

proc isAsciiLetter(value: int64): bool =
  (value >= int64(ord('A')) and value <= int64(ord('Z'))) or
    (value >= int64(ord('a')) and value <= int64(ord('z')))

proc word_search_generator*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "word_search_generator".} =
  if values == nil or length < 4 or length > csize_t(MaxInputValues): return -1
  let widthValue = values[0]
  let heightValue = values[1]
  let seedValue = values[2]
  let wordCountValue = values[3]
  if widthValue < 1 or widthValue > int64(MaxDimension) or
      heightValue < 1 or heightValue > int64(MaxDimension) or
      seedValue < 1 or seedValue >= int64(RngModulus) or
      wordCountValue < 0 or wordCountValue > int64(MaxWords): return -1
  let width = int(widthValue)
  let height = int(heightValue)
  let wordCount = int(wordCountValue)

  var position = 4
  for _ in 0 ..< wordCount:
    if position >= int(length): return -1
    let wordLengthValue = values[position]
    inc position
    if wordLengthValue < 1 or wordLengthValue > int64(MaxWordLength) or
        wordLengthValue > int64(int(length) - position): return -1
    let wordLength = int(wordLengthValue)
    for offset in 0 ..< wordLength:
      if not isAsciiLetter(values[position + offset]): return -1
    position += wordLength
  if position != int(length): return -1

  let cells = width * height
  if output == nil or outputCapacity < csize_t(cells): return -2
  var board: array[MaxCells, uint8] = default(array[MaxCells, uint8])
  var rows, columns: array[MaxDimension, int]
  const RowDelta: array[8, int] = [-1, -1, 0, 1, 1, 1, 0, -1]
  const ColumnDelta: array[8, int] = [0, 1, 1, 1, 0, -1, -1, -1]
  var state = uint64(seedValue)
  position = 4

  for _ in 0 ..< wordCount:
    let wordLength = int(values[position])
    inc position
    let wordStart = position
    position += wordLength
    for row in 0 ..< height: rows[row] = row
    for column in 0 ..< width: columns[column] = column
    shuffle(rows, height, state)
    shuffle(columns, width, state)
    let direction = int(nextRandom(state) mod 8'u64)
    var placed = false

    for rowIndex in 0 ..< height:
      if placed: break
      for columnIndex in 0 ..< width:
        let row = rows[rowIndex]
        let column = columns[columnIndex]
        let lastRow = row + (wordLength - 1) * RowDelta[direction]
        let lastColumn = column + (wordLength - 1) * ColumnDelta[direction]
        if lastRow < 0 or lastRow >= height or lastColumn < 0 or lastColumn >= width: continue
        var available = true
        for offset in 0 ..< wordLength:
          let currentRow = row + offset * RowDelta[direction]
          let currentColumn = column + offset * ColumnDelta[direction]
          if board[currentRow * width + currentColumn] != 0:
            available = false
            break
        if not available: continue
        for offset in 0 ..< wordLength:
          let currentRow = row + offset * RowDelta[direction]
          let currentColumn = column + offset * ColumnDelta[direction]
          board[currentRow * width + currentColumn] = uint8(values[wordStart + offset])
        placed = true
        break

  for index in 0 ..< cells: output[index] = board[index]
  int64(cells)
