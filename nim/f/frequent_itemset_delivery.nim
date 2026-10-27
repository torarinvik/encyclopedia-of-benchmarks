proc putU64(output: ptr UncheckedArray[uint8], word: int, value: uint64) =
  for b in 0 ..< 8: output[word * 8 + b] = uint8((value shr (8 * b)) and 255)

proc frequent_itemset_delivery*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "frequent_itemset_delivery".} =
  if input.isNil or length < 6 or length > 69: return -1
  let n0 = input[0]; let rows0 = input[1]; let minimum = input[2]
  let tail = input[3]; let prefix0 = input[4]
  if n0 < 1 or n0 > 8 or rows0 < 1 or rows0 > 64 or minimum < 1 or minimum > rows0 or int(length) != 5 + int(rows0): return -1
  if tail < -1 or tail >= n0 or prefix0 < 0: return -1
  let n = int(n0); let rowCount = int(rows0)
  let limit = 1'u64 shl n; let prefix = uint64(prefix0)
  if prefix >= limit or (tail == -1 and prefix != 0'u64) or
     (tail >= 0 and (((prefix shr int(tail)) and 1'u64) == 0'u64 or (prefix shr (int(tail) + 1)) != 0'u64)): return -1
  var occurrences: array[8, uint64]
  var supports: array[8, uint64]
  for row in 0 ..< rowCount:
    let row0 = input[5 + row]
    if row0 < 0 or uint64(row0) >= limit: return -1
    let mask = uint64(row0)
    if (mask and prefix) != prefix: continue
    for item in int(tail + 1) ..< n:
      let bit = 1'u64 shl item
      if (mask and bit) != 0'u64:
        occurrences[item] = occurrences[item] or (1'u64 shl row)
        inc supports[item]
  var words: array[25, uint64]
  var records = 0
  for item in int(tail + 1) ..< n:
    if supports[item] < uint64(minimum): continue
    let at = 1 + 3 * records
    words[at] = uint64(item); words[at + 1] = occurrences[item]; words[at + 2] = supports[item]
    inc records
  words[0] = uint64(records)
  let wordCount = 1 + 3 * records; let bytes = 8 * wordCount
  if bytes > 200: return -1
  if output.isNil or int(capacity) < bytes: return -2
  for word in 0 ..< wordCount: putU64(output, word, words[word])
  int64(bytes)
