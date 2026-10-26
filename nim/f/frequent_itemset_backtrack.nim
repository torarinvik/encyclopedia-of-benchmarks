type BacktrackContext = object
  minimumSupport: int64
  words: array[511, int64]
  records: int

proc enumerate(ctx: var BacktrackContext, rows: array[16, int64], rowCount, itemCount, startItem: int, prefix: int64) =
  for item in startItem ..< itemCount:
    let bit = 1'i64 shl item
    var projected: array[16, int64]
    var projectedCount = 0
    for row in 0 ..< rowCount:
      if (rows[row] and bit) != 0:
        projected[projectedCount] = rows[row]
        inc projectedCount
    if int64(projectedCount) < ctx.minimumSupport: continue
    let mask = prefix or bit
    let at = 1 + 2 * ctx.records
    ctx.words[at] = mask
    ctx.words[at + 1] = int64(projectedCount)
    inc ctx.records
    enumerate(ctx, projected, projectedCount, itemCount, item + 1, mask)

proc putI64(output: ptr UncheckedArray[uint8], word: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[word * 8 + b] = uint8((bits shr (8 * b)) and 255)

proc frequent_itemset_backtrack*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "frequent_itemset_backtrack".} =
  if input.isNil or length < 4 or length > 19: return -1
  let itemCount0 = input[0]; let rowCount0 = input[1]; let minimum = input[2]
  if itemCount0 < 1 or itemCount0 > 8 or rowCount0 < 1 or rowCount0 > 16 or
     minimum < 1 or minimum > rowCount0 or int(length) != 3 + int(rowCount0): return -1
  let itemCount = int(itemCount0); let rowCount = int(rowCount0)
  let limit = 1'i64 shl itemCount
  var rows: array[16, int64]
  for i in 0 ..< rowCount:
    let mask = input[3 + i]
    if mask < 0 or mask >= limit: return -1
    rows[i] = mask
  var ctx = BacktrackContext(minimumSupport: minimum, records: 0)
  enumerate(ctx, rows, rowCount, itemCount, 0, 0)
  ctx.words[0] = int64(ctx.records)
  let wordCount = 1 + 2 * ctx.records
  let bytes = 8 * wordCount
  if output.isNil or int(capacity) < bytes: return -2
  for i in 0 ..< wordCount: putI64(output, i, ctx.words[i])
  int64(bytes)
