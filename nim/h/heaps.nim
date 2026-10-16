const MaxN = 7

proc emitRow(items: var array[MaxN, uint8], n: int,
             output: ptr UncheckedArray[uint8], rows: var int) =
  let offset = rows * n
  for index in 0 ..< n: output[offset + index] = items[index]
  inc rows

proc generate(items: var array[MaxN, uint8], n, size: int,
              output: ptr UncheckedArray[uint8], rows: var int) =
  if size == 1:
    emitRow(items, n, output, rows)
    return
  for index in 0 ..< size:
    generate(items, n, size - 1, output, rows)
    let swapIndex = if size mod 2 == 1: index else: 0
    swap(items[swapIndex], items[size - 1])

proc heaps*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "heaps".} =
  if values.isNil or length != 1 or values[0] < 0 or values[0] > int64(MaxN): return -1
  let n = int(values[0])
  if n == 0: return 0
  var rowCount = 1
  for factor in 2 .. n: rowCount *= factor
  let required = rowCount * n
  if output.isNil or capacity < csize_t(required): return -2
  var items: array[MaxN, uint8]
  for index in 0 ..< n: items[index] = uint8(ord('1') + index)
  var rows = 0
  generate(items, n, n, output, rows)
  int64(rows)
