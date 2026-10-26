const MaxRows = 8
const MaxCols = 8
const MaxInput = 66
const OutputBytes = 24

proc intervalCost(table: ptr UncheckedArray[int64], rows, cols, beginCol, endCol: int): int64 =
  var runs = 0'i64
  var havePrevious = false
  var previous = 0'i64
  for row in 0..<rows:
    for col in beginCol..<endCol:
      let value = table[2 + row * cols + col]
      if not havePrevious or value != previous: inc runs
      previous = value
      havePrevious = true
  2 * runs

proc put(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc table_compression_optimal_contiguous_partition*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "table_compression_optimal_contiguous_partition".} =
  if input.isNil or length < 3 or length > csize_t(MaxInput): return -1
  let rows64 = input[0]
  let cols64 = input[1]
  if rows64 < 1 or rows64 > MaxRows or cols64 < 1 or cols64 > MaxCols: return -1
  let rows = int(rows64)
  let cols = int(cols64)
  if int(length) != 2 + rows * cols: return -1
  for i in 0..<rows * cols:
    if input[2 + i] < 0 or input[2 + i] > 15: return -1

  var cost: array[MaxCols + 1, int64]
  var previous: array[MaxCols + 1, int]
  for finish in 1..cols:
    cost[finish] = int64.high
    for start in 0..<finish:
      let candidate = cost[start] + intervalCost(input, rows, cols, start, finish)
      if candidate < cost[finish]:
        cost[finish] = candidate
        previous[finish] = start

  var groups = 0'i64
  var cuts = 0'u64
  var finish = cols
  while finish > 0:
    let start = previous[finish]
    if start > 0: cuts = cuts or (1'u64 shl (start - 1))
    inc groups
    finish = start
  if output.isNil or capacity < csize_t(OutputBytes): return -2
  var staged: array[OutputBytes, uint8]
  put(staged[0].addr, 0, cost[cols])
  put(staged[0].addr, 8, groups)
  put(staged[0].addr, 16, int64(cuts))
  for byte in 0..<OutputBytes: output[byte] = staged[byte]
  OutputBytes.int64
