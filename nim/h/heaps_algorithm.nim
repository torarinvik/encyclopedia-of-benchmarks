const MaxValues = 6
const BytesPerValue = 8

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< BytesPerValue:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc emitRow(values: var array[MaxValues, int64], n: int,
             output: ptr UncheckedArray[uint8], rows: var int) =
  let rowOffset = rows * n * BytesPerValue
  for index in 0 ..< n:
    storeI64Le(output, rowOffset + index * BytesPerValue, values[index])
  inc rows

proc generate(values: var array[MaxValues, int64], n, k: int,
              output: ptr UncheckedArray[uint8], rows: var int) =
  if k == 1:
    emitRow(values, n, output, rows)
    return
  generate(values, n, k - 1, output, rows)
  for index in 0 ..< k - 1:
    let swapIndex = if k mod 2 == 0: index else: 0
    swap(values[swapIndex], values[k - 1])
    generate(values, n, k - 1, output, rows)

proc heaps_algorithm*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "heaps_algorithm".} =
  if values.isNil or length < 1 or length > csize_t(MaxValues): return -1
  let n = int(length)
  var rowCount = 1
  for factor in 2 .. n: rowCount *= factor
  let required = rowCount * n * BytesPerValue
  if output.isNil or capacity < csize_t(required): return -2
  var items: array[MaxValues, int64]
  for index in 0 ..< n: items[index] = values[index]
  var rows = 0
  generate(items, n, n, output, rows)
  int64(rows)
