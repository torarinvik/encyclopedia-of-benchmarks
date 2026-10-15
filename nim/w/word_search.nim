const MaxCells = 36
const MaxWordLength = 15

proc isLetter(value: int64): bool =
  (value >= ord('A').int64 and value <= ord('Z').int64) or
    (value >= ord('a').int64 and value <= ord('z').int64)

proc wordSearchVisit(input: ptr UncheckedArray[int64], columns, rows: int,
    wordStart, wordLength, position, wordIndex: int,
    visited: ptr UncheckedArray[bool]): bool =
  if visited[position] or input[2 + position] != input[wordStart + wordIndex]: return false
  visited[position] = true
  if wordIndex + 1 == wordLength:
    visited[position] = false
    return true
  let row = position div columns
  let column = position mod columns
  var found = false
  if row > 0:
    found = wordSearchVisit(input, columns, rows, wordStart, wordLength,
                            position - columns, wordIndex + 1, visited)
  if not found and row + 1 < rows:
    found = wordSearchVisit(input, columns, rows, wordStart, wordLength,
                            position + columns, wordIndex + 1, visited)
  if not found and column > 0:
    found = wordSearchVisit(input, columns, rows, wordStart, wordLength,
                            position - 1, wordIndex + 1, visited)
  if not found and column + 1 < columns:
    found = wordSearchVisit(input, columns, rows, wordStart, wordLength,
                            position + 1, wordIndex + 1, visited)
  visited[position] = false
  found

proc word_search*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "word_search".} =
  if input == nil or length < 5 or input[0] < 1 or input[0] > 6 or input[1] < 1 or input[1] > 6:
    return -1
  let rows = int(input[0])
  let columns = int(input[1])
  let cells = rows * columns
  let wordLengthIndex = 2 + cells
  if int(length) <= wordLengthIndex: return -1
  let wordLengthValue = input[wordLengthIndex]
  if wordLengthValue < 1 or wordLengthValue > MaxWordLength or
      int(length) != wordLengthIndex + 1 + int(wordLengthValue): return -1
  let wordLength = int(wordLengthValue)
  for index in 0 ..< cells:
    if not isLetter(input[2 + index]): return -1
  let wordStart = wordLengthIndex + 1
  for index in 0 ..< wordLength:
    if not isLetter(input[wordStart + index]): return -1
  if wordLength > cells: return 0
  var visited: array[MaxCells, bool]
  for position in 0 ..< cells:
    if wordSearchVisit(input, columns, rows, wordStart, wordLength, position, 0,
        cast[ptr UncheckedArray[bool]](addr visited[0])):
      return 1
  return 0
