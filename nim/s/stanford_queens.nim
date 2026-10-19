const MinRuns = 1'i64
const MaxRuns = 100'i64
const SolveRepetitions = 50
const MaxOutputBytes = 292

proc tryQueens(row: int, columns: var array[9, bool], diagonalSum: var array[17, bool], diagonalDiff: var array[15, bool], positions: var array[9, int]): bool =
  var j = 0
  var found = false
  while not found and j != 8:
    inc j
    found = false
    if columns[j] and diagonalSum[row + j] and diagonalDiff[row - j + 7]:
      positions[row] = j
      columns[j] = false
      diagonalSum[row + j] = false
      diagonalDiff[row - j + 7] = false
      if row < 8:
        found = tryQueens(row + 1, columns, diagonalSum, diagonalDiff, positions)
        if not found:
          columns[j] = true
          diagonalSum[row + j] = true
          diagonalDiff[row - j + 7] = true
      else:
        found = true
  found

proc doit(): bool =
  var a: array[9, bool]
  var b: array[17, bool]
  var c: array[15, bool]
  var x: array[9, int]
  for i in -7 .. 16:
    if i >= 1 and i <= 8: a[i] = true
    if i >= 2: b[i] = true
    if i <= 7: c[i + 7] = true
  tryQueens(1, a, b, c, x)

proc appendText(buffer: var array[MaxOutputBytes, uint8], used: var int, text: string) =
  for ch in text:
    buffer[used] = uint8(ord(ch))
    inc used

proc appendInteger(buffer: var array[MaxOutputBytes, uint8], used: var int, value: int32) =
  var remaining = value
  var reverse: array[12, uint8]
  var count = 0
  while true:
    reverse[count] = uint8(48 + remaining mod 10)
    inc count
    remaining = remaining div 10
    if remaining == 0: break
  while count > 0:
    dec count
    buffer[used] = reverse[count]
    inc used

proc stanford_queens*(runs: int64, output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64 {.cdecl, exportc: "stanford_queens".} =
  if runs < MinRuns or runs > MaxRuns: return -1
  if output.isNil: return -2
  var staged: array[MaxOutputBytes, uint8]
  var used = 0
  for run in 0 ..< int(runs):
    for repetition in 0 ..< SolveRepetitions:
      discard repetition
      if not doit(): appendText(staged, used, " Error in Queens.\n")
    appendInteger(staged, used, int32(run + 1))
    appendText(staged, used, "\n")
  if outputCapacity < csize_t(used): return -2
  for index in 0 ..< used: output[index] = staged[index]
  int64(used)
