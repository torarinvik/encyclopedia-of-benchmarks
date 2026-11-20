## Uncompiled multiword bit-parallel LCS length draft.
proc bit_parallel_lcs*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "bit_parallel_lcs".} =
  if input == nil or length < 2 or length > 515: return -1
  let nr = input[0]
  let mr = input[1]
  if nr < 0 or nr > 256 or mr < 0 or mr > 256 or length != csize_t(2+nr+mr): return -1
  let n = int(nr)
  let m = int(mr)
  for i in 2 ..< int(length):
    if input[i] < 0 or input[i] > 255: return -1
  var masks: array[256, array[4, uint64]]
  var row: array[4, uint64]
  let words = (n+63) div 64
  for i in 0 ..< n: masks[int(input[2+i])][i div 64] = masks[int(input[2+i])][i div 64] or (1'u64 shl (i mod 64))
  for i in 0 ..< m:
    let symbol = int(input[2+n+i])
    var carry = 1'u64
    var borrow = 0'u64
    for j in 0 ..< words:
      let old = row[j]
      let combined = old or masks[symbol][j]
      let shifted = (old shl 1) or carry
      carry = old shr 63
      let firstBorrow = combined < shifted
      let partial = if firstBorrow: (not (shifted - combined)) + 1'u64 else: combined - shifted
      let secondBorrow = partial < borrow
      let difference = if secondBorrow: not 0'u64 else: partial - borrow
      borrow = if firstBorrow or secondBorrow: 1'u64 else: 0'u64
      row[j] = combined and (combined xor difference)
  var resultCount = 0'i64
  for j in 0 ..< words:
    var word = row[j]
    while word != 0:
      word = word and (word-1)
      inc resultCount
  resultCount
