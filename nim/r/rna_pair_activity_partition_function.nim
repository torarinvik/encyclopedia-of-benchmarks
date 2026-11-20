const
  MaxSequenceLength = 16
  MaxParseableLength = 122

proc pairInputIndex(n, left, right: int): int =
  let preceding = left * (2 * n - left - 1) div 2
  1 + preceding + (right - left - 1)

proc rna_pair_activity_partition_function*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "rna_pair_activity_partition_function".} =
  if input.isNil or length < 1 or length > csize_t(MaxParseableLength): return -1
  let nValue = input[0]
  if nValue < 0 or nValue > int64(MaxSequenceLength): return -1
  let n = int(nValue)
  let expectedLength = if n == 0: 1 else: 1 + n * (n - 1) div 2
  if int(length) != expectedLength: return -1
  for index in 1 ..< int(length):
    if input[index] < 0 or input[index] > 3: return -1
  if n == 0: return 1

  var table: array[MaxSequenceLength, array[MaxSequenceLength, int64]]
  for span in 1 .. n:
    for left in 0 .. n - span:
      let right = left + span - 1
      var total = 1'i64
      if left < right: total = table[left][right - 1]
      for partner in left ..< right:
        let activity = input[pairInputIndex(n, partner, right)]
        let before = if partner == left: 1'i64 else: table[left][partner - 1]
        let inside = if partner + 1 >= right: 1'i64 else: table[partner + 1][right - 1]
        total += before * inside * activity
      table[left][right] = total
  table[0][n - 1]
