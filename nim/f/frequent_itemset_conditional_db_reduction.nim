proc putU64(output: ptr UncheckedArray[uint8], word: int, value: uint64) =
  for b in 0 ..< 8: output[word * 8 + b] = uint8((value shr (8 * b)) and 255)

proc frequent_itemset_conditional_db_reduction*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "frequent_itemset_conditional_db_reduction".} =
  if input.isNil or length < 6 or length > 69: return -1
  let n0 = input[0]; let rows0 = input[1]; let minimum = input[2]
  let tail = input[3]; let prefix0 = input[4]
  if n0 < 1 or n0 > 8 or rows0 < 1 or rows0 > 64 or minimum < 1 or minimum > rows0 or int(length) != 5 + int(rows0): return -1
  if tail < -1 or tail >= n0 or prefix0 < 0: return -1
  let n = int(n0); let rowCount = int(rows0)
  let limit = 1'u64 shl n; let prefix = uint64(prefix0)
  if prefix >= limit or (tail == -1 and prefix != 0'u64) or
     (tail >= 0 and (((prefix shr int(tail)) and 1'u64) == 0'u64 or (prefix shr (int(tail) + 1)) != 0'u64)): return -1
  var selected: array[64, uint64]
  var support: array[8, uint64]
  var selectedCount = 0
  for row in 0 ..< rowCount:
    let row0 = input[5 + row]
    if row0 < 0 or uint64(row0) >= limit: return -1
    let mask = uint64(row0)
    if (mask and prefix) != prefix: continue
    selected[selectedCount] = mask
    inc selectedCount
    for item in int(tail + 1) ..< n:
      if (mask and (1'u64 shl item)) != 0'u64: inc support[item]
  if selectedCount < int(minimum): return -1
  var keep = if tail >= 0: 1'u64 shl int(tail) else: 0'u64
  for item in int(tail + 1) ..< n:
    if support[item] >= uint64(minimum): keep = keep or (1'u64 shl item)
  let below = if tail > 0: (1'u64 shl int(tail)) - 1'u64 else: 0'u64
  var masks: array[64, uint64]
  var counts: array[64, uint64]
  var distinct = 0
  for row in 0 ..< selectedCount:
    let reduced = selected[row] and (not below) and keep
    var at = 0
    while at < distinct and masks[at] != reduced: inc at
    if at == distinct:
      masks[distinct] = reduced
      inc distinct
    inc counts[at]
  for i in 1 ..< distinct:
    let savedMask = masks[i]; let savedCount = counts[i]
    var j = i
    while j > 0 and masks[j - 1] > savedMask:
      masks[j] = masks[j - 1]; counts[j] = counts[j - 1]; dec j
    masks[j] = savedMask; counts[j] = savedCount
  let wordCount = 1 + 2 * distinct; let bytes = 8 * wordCount
  if bytes > 1032: return -1
  if output.isNil or int(capacity) < bytes: return -2
  putU64(output, 0, uint64(distinct))
  for i in 0 ..< distinct:
    putU64(output, 1 + 2 * i, masks[i]); putU64(output, 2 + 2 * i, counts[i])
  int64(bytes)
